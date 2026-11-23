class_name Hud
extends CanvasLayer
## Layer-1 HUD: passport counter, stamp toast, PT/EN toggle and the passport
## panel with teleport to visited cities (ADR 0002, 0006, 0008). Built in code
## so the layout lives in one reviewable file. All text comes from tr().

signal teleport_requested(city: String)

const FONT_SIZE := 8

var stamp_cities: PackedStringArray = []

var _counter: Label
var _key_hint: Label
var _toast: Label
var _toast_tween: Tween
var _lang: Button
var _panel: PanelContainer
var _rows: VBoxContainer
var _title: Label
var _subtitle: Label
var _hint: Label
var _close: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Theme.new()
	root.theme.default_font_size = FONT_SIZE
	add_child(root)

	_counter = _label(root, Vector2(6, 4))
	_key_hint = _label(root, Vector2(6, 14))
	_key_hint.modulate = Color(1, 1, 1, 0.7)

	_lang = Button.new()
	_lang.focus_mode = Control.FOCUS_NONE   # never steal the driving keys
	_lang.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lang.position = Vector2(-26, 3)
	_lang.custom_minimum_size = Vector2(22, 12)
	_lang.pressed.connect(I18n.toggle)
	root.add_child(_lang)

	_toast = _label(root, Vector2.ZERO)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(-120, 30)
	_toast.size = Vector2(240, 12)
	_toast.add_theme_font_size_override("font_size", 10)
	_toast.modulate.a = 0.0

	_build_panel(root)
	I18n.locale_changed.connect(func(_l: String) -> void: refresh())
	SaveStore.passport.stamped.connect(func(_c: String) -> void: refresh())
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("passport"):
		toggle_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	_panel.visible = not _panel.visible
	get_tree().paused = _panel.visible
	if _panel.visible:
		refresh()
		_close.grab_focus()


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func refresh() -> void:
	var p := SaveStore.passport
	_counter.text = tr("HUD_PASSPORT") % [p.stamp_count(stamp_cities), stamp_cities.size()]
	_key_hint.text = tr("HUD_PASSPORT_KEY")
	_lang.text = tr("LANG_TOGGLE")
	_title.text = tr("PASSPORT_TITLE")
	_subtitle.text = tr("PASSPORT_STAMPS")
	_hint.text = tr("PASSPORT_HINT")
	_close.text = tr("PASSPORT_CLOSE")
	for child in _rows.get_children():
		child.queue_free()
	for city in stamp_cities:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = ("[x] " if p.has_stamp(city) else "[ ] ") + city
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		if p.has_stamp(city):
			var go := Button.new()
			go.text = tr("PASSPORT_GO")
			go.pressed.connect(func() -> void:
				toggle_panel()
				teleport_requested.emit(city))
			row.add_child(go)
		else:
			var missing := Label.new()
			missing.text = tr("PASSPORT_NOT_YET")
			missing.modulate = Color(1, 1, 1, 0.6)
			row.add_child(missing)
		_rows.add_child(row)


func _build_panel(root: Control) -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(220, 0)
	_panel.position = Vector2(-110, -70)
	root.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 12)
	box.add_child(_title)
	_subtitle = Label.new()
	box.add_child(_subtitle)
	_rows = VBoxContainer.new()
	box.add_child(_rows)
	_hint = Label.new()
	_hint.modulate = Color(1, 1, 1, 0.7)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_hint)
	_close = Button.new()
	_close.pressed.connect(toggle_panel)
	box.add_child(_close)


func _label(parent: Control, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	return l
