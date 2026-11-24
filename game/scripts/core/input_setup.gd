extends Node
## Registers the game's input actions (keyboard + gamepad) at startup, so the
## mapping lives in code review instead of serialized blobs in project.godot.
## Touch is out of the MVP (ADR 0001); it plugs in here later.

const DEADZONE := 0.2


func _enter_tree() -> void:
	_action("accelerate", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0), _button(JOY_BUTTON_A)])
	_action("brake", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0), _button(JOY_BUTTON_B)])
	_action("steer_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("steer_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("passport", [_key(KEY_P), _key(KEY_TAB), _button(JOY_BUTTON_Y)])
	_action("photo", [_key(KEY_F), _button(JOY_BUTTON_X)])
	_action("shoot", [_key(KEY_SPACE), _button(JOY_BUTTON_RIGHT_SHOULDER)])
	_action("interact", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_action("rotate_view_left", [_key(KEY_Q), _axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("rotate_view_right", [_key(KEY_E), _axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("map", [_key(KEY_M), _button(JOY_BUTTON_BACK)])


func _action(action_name: StringName, events: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name, DEADZONE)
	for event in events:
		InputMap.action_add_event(action_name, event)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


func _button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e
