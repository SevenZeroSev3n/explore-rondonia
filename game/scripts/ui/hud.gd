class_name Hud
extends CanvasLayer
## Layer-1 HUD (ADR 0002, 0006, 0008): passport and secrets counters, toasts,
## PT/EN toggle, the passport panel (stamps, teleport, secrets), the photo-mode
## viewfinder and the place sheet. Built in code so the layout lives in one
## reviewable file. Every string comes from tr() or the place catalog.

signal teleport_requested(city: String)
signal shutter_pressed(frame_screen: Rect2)

const FONT_SIZE := 8
const VIEWFINDER := Vector2(240, 150)   ## screen px, centred

var stamp_cities: PackedStringArray = []
var secret_ids: PackedStringArray = []
var catalog: PlaceCatalog
var photo_mode := false
## Key-hint string shown when not in photo mode; dioramas swap it.
var keys_hint := "HUD_KEYS"

var _root: Control
var _counter: Label
var _secrets_counter: Label
var _key_hint: Label
var _toast: Label
var _prompt: Label
var _toast_tween: Tween
var _lang: Button
var _viewfinder: Control
var _flash: ColorRect

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _rows: VBoxContainer
var _secrets_title: Label
var _secret_rows: VBoxContainer
var _hint: Label
var _close: Button

var _sheet: PanelContainer
var _sheet_title: Label
var _sheet_text: Label
var _sheet_photo: Label
var _sheet_sources: Label
var _sheet_close: Button
var _sheet_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Theme.new()
	_root.theme.default_font_size = FONT_SIZE
	add_child(_root)

	_counter = _label(_root, Vector2(6, 4))
	_secrets_counter = _label(_root, Vector2(6, 14))
	_key_hint = _label(_root, Vector2(6, 24))
	_key_hint.modulate = Color(1, 1, 1, 0.7)

	_lang = Button.new()
	_lang.focus_mode = Control.FOCUS_NONE   # never steal the driving keys
	_lang.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lang.position = Vector2(-26, 3)
	_lang.custom_minimum_size = Vector2(22, 12)
	_lang.pressed.connect(I18n.toggle)
	_root.add_child(_lang)

	_build_viewfinder()

	_toast = _label(_root, Vector2.ZERO)
	# Full width under the counters, text centred: anchors + offsets, not a raw position.
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 36
	_toast.offset_bottom = 50
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 10)
	_toast.modulate.a = 0.0

	_prompt = _label(_root, Vector2.ZERO)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -22
	_prompt.offset_bottom = -8
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_build_panel()
	_build_sheet()
	I18n.locale_changed.connect(func(_l: String) -> void: refresh())
	SaveStore.passport.stamped.connect(func(_c: String) -> void: refresh())
	SaveStore.passport.photographed.connect(func(_id: String) -> void: refresh())
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _sheet.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("passport"):
			close_sheet()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("passport"):
		toggle_panel()
		get_viewport().set_input_as_handled()
	elif _panel.visible:
		return
	elif event.is_action_pressed("photo") or (photo_mode and event.is_action_pressed("ui_cancel")):
		set_photo_mode(not photo_mode if event.is_action_pressed("photo") else false)
		get_viewport().set_input_as_handled()
	elif photo_mode and event.is_action_pressed("shoot"):
		_shoot()
		get_viewport().set_input_as_handled()


# --- passport panel -------------------------------------------------------

func toggle_panel() -> void:
	_panel.visible = not _panel.visible
	_update_pause()
	if _panel.visible:
		set_photo_mode(false)
		refresh()
		_close.grab_focus()


func refresh() -> void:
	var p := SaveStore.passport
	var locale := I18n.current()
	_counter.text = tr("HUD_PASSPORT") % [p.stamp_count(stamp_cities), stamp_cities.size()]
	_secrets_counter.text = tr("HUD_SECRETS") % [p.photo_count(secret_ids), secret_ids.size()]
	_key_hint.text = tr("PHOTO_MODE_KEYS") if photo_mode else tr(keys_hint)
	_lang.text = tr("LANG_TOGGLE")
	_title.text = tr("PASSPORT_TITLE")
	_subtitle.text = tr("PASSPORT_STAMPS")
	_secrets_title.text = tr("PASSPORT_SECRETS")
	_hint.text = tr("PASSPORT_HINT")
	_close.text = tr("PASSPORT_CLOSE")
	_sheet_close.text = tr("SHEET_CLOSE")
	if not _sheet_id.is_empty():
		_fill_sheet(_sheet_id)

	_clear(_rows)
	for city in stamp_cities:
		var row := _row(("[x] " if p.has_stamp(city) else "[ ] ") + city)
		if p.has_stamp(city):
			row.add_child(_button(tr("PASSPORT_GO"), func() -> void:
				toggle_panel()
				teleport_requested.emit(city)))
		else:
			row.add_child(_dim(tr("PASSPORT_NOT_YET")))
		_rows.add_child(row)

	_clear(_secret_rows)
	for id in secret_ids:
		if p.has_photo(id) and catalog:
			var row := _row("[x] " + catalog.name_of(id, locale))
			row.add_child(_button(tr("PASSPORT_VIEW"), func() -> void: open_sheet(id)))
			_secret_rows.add_child(row)
		else:
			var row := _row("[ ] ???")
			row.add_child(_dim(tr("PASSPORT_SECRET_UNKNOWN")))
			_secret_rows.add_child(row)


# --- photo mode -----------------------------------------------------------

func set_photo_mode(on: bool) -> void:
	photo_mode = on
	_viewfinder.visible = on
	refresh()


## The viewfinder rectangle in viewport (screen) coordinates.
func viewfinder_rect() -> Rect2:
	var size := get_viewport().get_visible_rect().size
	return Rect2((size - VIEWFINDER) / 2.0, VIEWFINDER)


func _shoot() -> void:
	_flash.modulate.a = 0.8
	create_tween().tween_property(_flash, "modulate:a", 0.0, 0.35)
	shutter_pressed.emit(viewfinder_rect())


# --- place sheet ----------------------------------------------------------

func open_sheet(id: String) -> void:
	if catalog == null or not catalog.has(id):
		return
	_sheet_id = id
	_fill_sheet(id)
	_panel.visible = false
	_sheet.visible = true
	set_photo_mode(false)
	_update_pause()
	_sheet_close.grab_focus()


func close_sheet() -> void:
	_sheet.visible = false
	_sheet_id = ""
	_update_pause()


func _fill_sheet(id: String) -> void:
	var locale := I18n.current()
	_sheet_title.text = catalog.name_of(id, locale)
	_sheet_text.text = catalog.text_of(id, locale)
	_sheet_photo.text = tr("SHEET_PHOTO_SOON")
	var hosts: PackedStringArray = []
	for url in catalog.sources_of(id):
		var host := url.trim_prefix("https://").trim_prefix("http://").get_slice("/", 0)
		if not hosts.has(host):
			hosts.append(host)
	_sheet_sources.text = tr("SHEET_SOURCES") % ", ".join(hosts)


# --- toasts and prompts ---------------------------------------------------

## A standing hint at the bottom of the screen ("Enter: ..."); empty hides it.
func set_prompt(text: String) -> void:
	if _prompt.text != text:
		_prompt.text = text



func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


# --- building blocks ------------------------------------------------------

func _update_pause() -> void:
	get_tree().paused = _panel.visible or _sheet.visible


func _build_viewfinder() -> void:
	_viewfinder = Control.new()
	_viewfinder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewfinder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewfinder.visible = false
	_viewfinder.draw.connect(func() -> void:
		var r := viewfinder_rect()
		var c := Color(1, 1, 1, 0.9)
		var l := 14.0
		for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			var sx := 1.0 if corner.x == r.position.x else -1.0
			var sy := 1.0 if corner.y == r.position.y else -1.0
			_viewfinder.draw_line(corner, corner + Vector2(l * sx, 0), c, 1.0)
			_viewfinder.draw_line(corner, corner + Vector2(0, l * sy), c, 1.0)
		var mid := r.get_center()
		_viewfinder.draw_line(mid - Vector2(4, 0), mid + Vector2(4, 0), Color(1, 1, 1, 0.5), 1.0)
		_viewfinder.draw_line(mid - Vector2(0, 4), mid + Vector2(0, 4), Color(1, 1, 1, 0.5), 1.0))
	_root.add_child(_viewfinder)

	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.modulate.a = 0.0
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)


func _build_panel() -> void:
	_panel = _centred_panel(Vector2(240, 0), Vector2(-120, -110))
	var box := _panel.get_child(0).get_child(0) as VBoxContainer
	_title = _heading(box)
	_subtitle = Label.new()
	box.add_child(_subtitle)
	_rows = VBoxContainer.new()
	box.add_child(_rows)
	_secrets_title = Label.new()
	box.add_child(_secrets_title)
	_secret_rows = VBoxContainer.new()
	box.add_child(_secret_rows)
	_hint = _dim("")
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_hint)
	_close = Button.new()
	_close.pressed.connect(toggle_panel)
	box.add_child(_close)


func _build_sheet() -> void:
	_sheet = _centred_panel(Vector2(300, 0), Vector2(-150, -115))
	var box := _sheet.get_child(0).get_child(0) as VBoxContainer
	_sheet_title = _heading(box)
	_sheet_photo = _dim("")
	_sheet_photo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sheet_photo.custom_minimum_size = Vector2(0, 40)
	_sheet_photo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_sheet_photo)
	_sheet_text = Label.new()
	_sheet_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_sheet_text.custom_minimum_size = Vector2(284, 0)
	box.add_child(_sheet_text)
	_sheet_sources = _dim("")
	_sheet_sources.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_sheet_sources)
	_sheet_close = Button.new()
	_sheet_close.pressed.connect(close_sheet)
	box.add_child(_sheet_close)


func _centred_panel(min_size: Vector2, offset: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = min_size
	panel.position = offset
	_root.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	return panel


func _heading(box: VBoxContainer) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 12)
	box.add_child(l)
	return l


func _row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	return row


func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_pressed)
	return b


func _dim(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.modulate = Color(1, 1, 1, 0.65)
	return l


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _label(parent: Control, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	return l
