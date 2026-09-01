extends RefCounted
class_name VoxeInputActions

static func ensure() -> void:
	_ensure_action("move_forward", [KEY_W, KEY_UP])
	_ensure_action("move_backward", [KEY_S, KEY_DOWN])
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("jump", [KEY_SPACE])
	_ensure_action("break_block", [KEY_F])
	_ensure_action("place_block", [KEY_G])
	_ensure_action("toggle_camera", [KEY_V])
	_ensure_action("toggle_mode", [KEY_M])

static func _ensure_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var existing := InputMap.action_get_events(action_name)
	for key in keys:
		var already_present := false
		for event in existing:
			if event is InputEventKey and event.physical_keycode == key:
				already_present = true
				break
		if not already_present:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = key
			InputMap.action_add_event(action_name, key_event)
