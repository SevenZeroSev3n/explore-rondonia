class_name Hud
extends CanvasLayer
## Layer-1 HUD (ADR 0002, 0006, 0008): passport and secrets counters, toasts,
## PT/EN toggle, the passport panel (stamps, teleport, secrets), the photo-mode
## viewfinder and the place sheet. Built in code so the layout lives in one
## reviewable file. Every string comes from tr() or the place catalog.

signal teleport_requested(city: String)
signal shutter_pressed(frame_screen: Rect2)

## Text uses the project theme (assets/ui_theme.tres): Pixelify Sans at 18 px at 640x360
## (ADR 0005), where its strokes are even and every Portuguese accent reads.
const HEADING_COLOR := Color("f2d04a")
const VIEWFINDER := Vector2(320, 200)   ## screen px, centred

var stamp_cities: PackedStringArray = []
var secret_ids: PackedStringArray = []
var landmark_ids: PackedStringArray = []          ## Madeira-Mamoré photos
var map_attribution: PackedStringArray = []
var catalog: PlaceCatalog
var photo_mode := false
## Key-hint string shown when not in photo mode; dioramas swap it.
var keys_hint := "HUD_KEYS"

var _root: Control
var _counter: Label
var _secrets_counter: Label
var _landmarks_counter: Label
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
var _landmarks_title: Label
var _landmark_rows: VBoxContainer
var _help: Button
var _credits_button: Button
var _secret_rows: VBoxContainer
var _hint: Label
var _close: Button

var _sheet: PanelContainer
var _sheet_title: Label
var _sheet_text: Label
var _sheet_photo: Label                ## "[ real photo coming soon ]" when a place has none
var _sheet_photo_rect: TextureRect     ## the photo frame (in-game texture; the web overlays it)
var _sheet_photo_credit: Label
var _sheet_photo_file := ""
var _photo_rect_shown := Rect2()
var _sheet_sources: Label
var _sheet_close: Button
var _sheet_id := ""

## One-screen panels: tutorial, passport complete, credits. Each is
## {panel, title, body, extra, button, button2} built by _build_info().
var _tutorial := {}
var _complete := {}
var _credits := {}
var _complete_pending := false   ## the last photo's sheet shows first, then "complete"

## Road trip (ADR 0009): minimap, distances, speedometer, fuel gauge and the full map (M).
var _trip: Control
var _minimap: MapView
var _trip_next: Label
var _trip_end: Label
var _speed: Label
var _fuel_label: Label
var _fuel_back: ColorRect
var _fuel_fill: ColorRect
var _map_panel: PanelContainer
var _map_title: Label
var _map_view: MapView
var _map_info: Label
var _map_legend: Label
var _trip_data := {}
var _trip_on := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_counter = _label(_root, Vector2(8, 3))
	_landmarks_counter = _label(_root, Vector2(8, 23))
	_secrets_counter = _label(_root, Vector2(8, 43))
	# Key hints sit on the bottom line; standing prompts ("Enter: ...") just above them.
	_key_hint = _label(_root, Vector2.ZERO)
	_key_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_key_hint.offset_top = -23
	_key_hint.offset_bottom = -3
	_key_hint.offset_left = 8
	_key_hint.modulate = Color(1, 1, 1, 0.7)

	_lang = Button.new()
	_lang.focus_mode = Control.FOCUS_NONE   # never steal the driving keys
	_lang.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lang.position = Vector2(-35, 4)
	_lang.custom_minimum_size = Vector2(29, 16)
	_lang.pressed.connect(I18n.toggle)
	_root.add_child(_lang)

	_build_viewfinder()

	_toast = _label(_root, Vector2.ZERO)
	# Full width under the counters, text centred: anchors + offsets, not a raw position.
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 67
	_toast.offset_bottom = 88
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.offset_left = 150          # clear of the counters and the minimap
	_toast.offset_right = -150
	_toast.offset_bottom = 110
	_toast.modulate.a = 0.0

	_prompt = _label(_root, Vector2.ZERO)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -48
	_prompt.offset_bottom = -27
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_build_panel()
	_build_sheet()
	_tutorial = _build_info(608)
	_tutorial.button.pressed.connect(close_tutorial)
	_complete = _build_info(507)
	_complete.button.pressed.connect(func() -> void: _hide_info(_complete))
	_complete.button2.pressed.connect(func() -> void:
		_hide_info(_complete)
		show_credits())
	_credits = _build_info(560)
	_credits.button.pressed.connect(func() -> void: _hide_info(_credits))
	I18n.locale_changed.connect(func(_l: String) -> void: refresh())
	SaveStore.passport.stamped.connect(func(_c: String) -> void: refresh())
	SaveStore.passport.photographed.connect(func(_id: String) -> void: refresh())
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _map_panel and _map_panel.visible:
		if event.is_action_pressed("map") or event.is_action_pressed("ui_cancel"):
			toggle_map()
			get_viewport().set_input_as_handled()
		return
	for info in [_tutorial, _complete, _credits]:
		if info.panel.visible:
			if event.is_action_pressed("ui_cancel"):
				info.button.pressed.emit()
				get_viewport().set_input_as_handled()
			return
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
	elif event.is_action_pressed("map") and _map_panel and _trip_on and not photo_mode:
		toggle_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("photo") or (photo_mode and event.is_action_pressed("ui_cancel")):
		set_photo_mode(not photo_mode if event.is_action_pressed("photo") else false)
		get_viewport().set_input_as_handled()
	elif photo_mode and event.is_action_pressed("shoot"):
		_shoot()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not WebPhoto.available():
		return
	if not _sheet.visible or _sheet_photo_file.is_empty():
		if _photo_rect_shown != Rect2():   # the sheet was hidden some other way
			_photo_rect_shown = Rect2()
			WebPhoto.hide()
		return
	var r := WebPhoto.window_rect(_sheet_photo_rect)
	if r != _photo_rect_shown:   # first frame after layout, and on window resize
		_photo_rect_shown = r
		WebPhoto.show(_sheet_photo_file, r)


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
	_landmarks_counter.text = tr("HUD_LANDMARKS") % [p.photo_count(landmark_ids), landmark_ids.size()]
	_landmarks_title.text = tr("PASSPORT_LANDMARKS")
	_help.text = tr("PASSPORT_HELP")
	_credits_button.text = tr("PASSPORT_CREDITS")
	_fill_infos()
	_key_hint.text = tr("PHOTO_MODE_KEYS") if photo_mode else tr(keys_hint)
	_lang.text = tr("LANG_TOGGLE")
	if _trip:
		_fuel_label.text = tr("FUEL_LABEL")
		_map_title.text = tr("MAP_TITLE")
		_map_legend.text = tr("MAP_LEGEND")
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

	_clear(_landmark_rows)
	for id in landmark_ids:
		var name_text := catalog.name_of(id, locale) if catalog else id
		var row := _row(("[x] " if p.has_photo(id) else "[ ] ") + name_text)
		if p.has_photo(id):
			row.add_child(_button(tr("PASSPORT_VIEW"), func() -> void: open_sheet(id)))
		else:
			row.add_child(_dim(tr("PASSPORT_NOT_TAKEN")))
		_landmark_rows.add_child(row)

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
	_sheet_photo_file = ""
	_photo_rect_shown = Rect2()
	WebPhoto.hide()
	_update_pause()
	if _complete_pending:
		_complete_pending = false
		show_complete()


func _fill_sheet(id: String) -> void:
	var locale := I18n.current()
	_sheet_title.text = catalog.name_of(id, locale)
	_sheet_text.text = catalog.text_of(id, locale)
	var photos := catalog.photos_of(id)
	if photos.is_empty():
		_sheet_photo_file = ""
		_sheet_photo_rect.texture = null
		_sheet_photo.text = tr("SHEET_PHOTO_SOON")
		_sheet_photo_credit.text = ""
	else:
		var photo: Dictionary = photos[0]
		_sheet_photo_file = photo.file
		_sheet_photo_rect.texture = load(photo.file)
		_sheet_photo.text = ""
		_sheet_photo_credit.text = catalog.caption_of(photo, locale) + "\n" \
			+ tr("SHEET_PHOTO_CREDIT") % [photo.get("author", "?"), photo.get("license", "?")]
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
	var info_open := false
	for info in [_tutorial, _complete, _credits]:
		if not info.is_empty() and info.panel.visible:
			info_open = true
	var map_open := _map_panel != null and _map_panel.visible
	get_tree().paused = _panel.visible or _sheet.visible or info_open or map_open
	# The HUD behind a panel would show through it and compete with its text.
	for l in [_counter, _landmarks_counter, _secrets_counter, _key_hint, _prompt]:
		l.visible = not get_tree().paused
	if _trip:
		_trip.visible = _trip_on and not get_tree().paused
	if get_tree().paused:
		if _toast_tween:
			_toast_tween.kill()
		_toast.modulate.a = 0.0   # never show a toast through a panel


# --- road trip: minimap, speedometer, fuel, full map (ADR 0009) -----------

## Builds the trip HUD for this map. Called once by the state map.
func setup_trip(map: StateMapData, stations: Array[Dictionary]) -> void:
	_trip = Control.new()
	_trip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_trip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_trip)
	_root.move_child(_trip, 0)   # under every panel

	var mini_frame := PanelContainer.new()
	mini_frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mini_frame.position = Vector2(-132, 24)
	mini_frame.custom_minimum_size = Vector2(124, 92)
	mini_frame.modulate = Color(1, 1, 1, 0.92)
	_trip.add_child(mini_frame)
	_minimap = MapView.new()
	_minimap.map = map
	_minimap.stations = stations
	_minimap.custom_minimum_size = Vector2(122, 90)
	mini_frame.add_child(_minimap)
	_trip_next = _right_label(_trip, 118)
	_trip_end = _right_label(_trip, 138)

	_fuel_label = _label(_trip, Vector2.ZERO)
	_fuel_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_fuel_label.offset_left = -200
	_fuel_label.offset_right = -96
	_fuel_label.offset_top = -50
	_fuel_label.offset_bottom = -30
	_fuel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fuel_back = ColorRect.new()
	_fuel_back.color = Color(0, 0, 0, 0.75)
	_fuel_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_fuel_back.offset_left = -90
	_fuel_back.offset_right = -8
	_fuel_back.offset_top = -43
	_fuel_back.offset_bottom = -34
	_trip.add_child(_fuel_back)
	_fuel_fill = ColorRect.new()
	_fuel_fill.position = Vector2(1, 1)
	_fuel_fill.size = Vector2(80, 7)
	_fuel_back.add_child(_fuel_fill)
	_speed = _label(_trip, Vector2.ZERO)
	_speed.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_speed.offset_left = -160
	_speed.offset_right = -8
	_speed.offset_top = -25
	_speed.offset_bottom = -3
	_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Full map: the state on the left as big as the screen allows, the text on the right.
	_map_panel = _centred_panel(Vector2(608, 0))
	var outer := _map_panel.get_child(0).get_child(0) as VBoxContainer
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	outer.add_child(row)
	_map_view = MapView.new()
	_map_view.map = map
	_map_view.stations = stations
	_map_view.detailed = true
	_map_view.custom_minimum_size = Vector2(330, 316)
	row.add_child(_map_view)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 11)
	row.add_child(side)
	_map_title = _heading(side)
	_map_info = Label.new()
	_map_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_info.custom_minimum_size = Vector2(245, 0)
	side.add_child(_map_info)
	_map_legend = _dim("")
	_map_legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_legend.custom_minimum_size = Vector2(245, 0)
	side.add_child(_map_legend)
	refresh()


## Fed every frame by the state map: {kmh, fuel, pos, heading, km, next_town, next_km,
## end_town, end_km}.
func update_trip(d: Dictionary) -> void:
	if _trip == null:
		return
	_trip_data = d
	_speed.text = tr("SPEED_KMH") % roundi(d.kmh)
	var f: float = d.fuel
	_fuel_fill.size.x = maxf(0.0, 80.0 * f)
	var low := f < 0.2
	_fuel_fill.color = Color("d8503c") if low else (Color("e8c64a") if f < 0.5 else Color("6cc04a"))
	_fuel_fill.visible = not low or fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.4
	_minimap.set_player(d.pos, d.heading)
	_trip_next.text = tr("TRIP_DISTANCE") % [d.next_town, roundi(d.next_km)] if d.next_town != "" else ""
	_trip_end.text = tr("TRIP_DISTANCE") % [d.end_town, roundi(d.end_km)] if d.end_km > 0.5 else ""


func set_trip_visible(on: bool) -> void:
	_trip_on = on
	if _trip:
		_trip.visible = on and not get_tree().paused


func toggle_map() -> void:
	_map_panel.visible = not _map_panel.visible
	if _map_panel.visible:
		set_photo_mode(false)
		_fill_map()
	_update_pause()


func _fill_map() -> void:
	if _trip_data.is_empty():
		return
	var d := _trip_data
	_map_view.set_player(d.pos, d.heading)
	var info := tr("MAP_INFO_KM") % roundi(d.km)
	if d.next_town != "":
		info += "\n\n" + tr("MAP_INFO_NEXT") % [d.next_town, roundi(d.next_km)]
	if d.end_km > 0.5:
		info += "\n" + tr("TRIP_DISTANCE") % [d.end_town, roundi(d.end_km)]
	_map_info.text = info


func _right_label(parent: Control, top: float) -> Label:
	var l := _label(parent, Vector2.ZERO)
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	l.offset_left = -240
	l.offset_right = -8
	l.offset_top = top
	l.offset_bottom = top + 20
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return l


# --- tutorial, passport complete, credits ---------------------------------

func show_tutorial() -> void:
	_show_info(_tutorial)


func close_tutorial() -> void:
	_hide_info(_tutorial)
	SaveStore.set_flag("tutorial_seen")


func show_complete() -> void:
	if _sheet.visible:
		_complete_pending = true
		return
	_show_info(_complete)


func show_credits() -> void:
	_show_info(_credits)


func is_showing(which: String) -> bool:
	var info: Dictionary = {"tutorial": _tutorial, "complete": _complete, "credits": _credits}[which]
	return info.panel.visible


func _show_info(info: Dictionary) -> void:
	_panel.visible = false
	_sheet.visible = false
	for other in [_tutorial, _complete, _credits]:
		other.panel.visible = false
	set_photo_mode(false)
	_fill_infos()
	info.panel.visible = true
	_update_pause()
	info.button.grab_focus()


func _hide_info(info: Dictionary) -> void:
	info.panel.visible = false
	_update_pause()


func _fill_infos() -> void:
	if _tutorial.is_empty():
		return
	_tutorial.title.text = tr("TUTORIAL_TITLE")
	_tutorial.body.text = tr("TUTORIAL_BODY") + "\n\n" + tr("TUTORIAL_GOAL")
	_tutorial.extra.text = tr("TUTORIAL_KEYS")
	_tutorial.button.text = tr("TUTORIAL_START")
	_tutorial.button2.visible = false
	_complete.title.text = tr("COMPLETE_TITLE")
	_complete.body.text = tr("COMPLETE_BODY")
	_complete.extra.text = ""
	_complete.button.text = tr("COMPLETE_CONTINUE")
	_complete.button2.text = tr("PASSPORT_CREDITS")
	_credits.title.text = tr("CREDITS_TITLE")
	var hosts := Credits.source_hosts(catalog) if catalog else PackedStringArray()
	var photo_lines := Credits.photo_lines(tr, catalog, I18n.current()) if catalog else PackedStringArray()
	_credits.body.text = "\n".join(Credits.lines(tr, map_attribution, hosts, photo_lines))
	_credits.extra.text = ""
	_credits.button.text = tr("SHEET_CLOSE")
	_credits.button2.visible = false


func _build_info(width: float) -> Dictionary:
	var panel := _centred_panel(Vector2(width, 0))
	var box := panel.get_child(0).get_child(0) as VBoxContainer
	var title := _heading(box)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size = Vector2(width - 22, 0)
	box.add_child(body)
	var extra := _dim("")
	extra.autowrap_mode = TextServer.AUTOWRAP_WORD
	extra.custom_minimum_size = Vector2(width - 22, 0)
	box.add_child(extra)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	var button := Button.new()
	buttons.add_child(button)
	var button2 := Button.new()
	buttons.add_child(button2)
	return {"panel": panel, "title": title, "body": body, "extra": extra, "button": button, "button2": button2}


func _build_viewfinder() -> void:
	_viewfinder = Control.new()
	_viewfinder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewfinder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewfinder.visible = false
	_viewfinder.draw.connect(func() -> void:
		var r := viewfinder_rect()
		var c := Color(1, 1, 1, 0.9)
		var l := 19.0
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
	_panel = _centred_panel(Vector2(480, 0))
	var box := _panel.get_child(0).get_child(0) as VBoxContainer
	_title = _heading(box)
	# The lists scroll; title and buttons stay put, so the panel fits 360 px with any content.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 181)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var lists := VBoxContainer.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_theme_constant_override("separation", 3)
	scroll.add_child(lists)
	_subtitle = Label.new()
	lists.add_child(_subtitle)
	_rows = VBoxContainer.new()
	lists.add_child(_rows)
	_landmarks_title = Label.new()
	lists.add_child(_landmarks_title)
	_landmark_rows = VBoxContainer.new()
	lists.add_child(_landmark_rows)
	_secrets_title = Label.new()
	lists.add_child(_secrets_title)
	_secret_rows = VBoxContainer.new()
	lists.add_child(_secret_rows)
	_hint = _dim("")
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_hint)
	var extras := HBoxContainer.new()
	box.add_child(extras)
	_help = _button("", func() -> void: show_tutorial())
	extras.add_child(_help)
	_credits_button = _button("", func() -> void: show_credits())
	extras.add_child(_credits_button)
	_close = Button.new()
	_close.pressed.connect(toggle_panel)
	box.add_child(_close)


func _build_sheet() -> void:
	_sheet = _centred_panel(Vector2(619, 0))
	var box := _sheet.get_child(0).get_child(0) as VBoxContainer
	_sheet_title = _heading(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	box.add_child(row)
	# Photo frame (3:2-ish like most photos); the placeholder label sits inside it.
	_sheet_photo_rect = TextureRect.new()
	_sheet_photo_rect.custom_minimum_size = Vector2(224, 152)
	_sheet_photo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sheet_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sheet_photo_rect.clip_contents = true
	_sheet_photo_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	row.add_child(_sheet_photo_rect)
	_sheet_photo = _dim("")
	_sheet_photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet_photo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sheet_photo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sheet_photo.autowrap_mode = TextServer.AUTOWRAP_WORD
	_sheet_photo_rect.add_child(_sheet_photo)
	_sheet_text = Label.new()
	_sheet_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_sheet_text.custom_minimum_size = Vector2(363, 0)
	_sheet_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_sheet_text)
	_sheet_photo_credit = _dim("")
	_sheet_photo_credit.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_sheet_photo_credit)
	_sheet_sources = _dim("")
	_sheet_sources.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_sheet_sources)
	_sheet_close = Button.new()
	_sheet_close.pressed.connect(close_sheet)
	box.add_child(_sheet_close)


func _centred_panel(min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.custom_minimum_size = min_size
	_root.add_child(panel)
	# Centred and growing both ways, so it stays centred whatever its content's height.
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 11)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	return panel


func _heading(box: VBoxContainer) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", HEADING_COLOR)
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
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	return l
