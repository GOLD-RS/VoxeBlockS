extends CanvasLayer
class_name VoxeHUD

signal move_changed(value: Vector2)
signal look_changed(value: Vector2)
signal break_pressed
signal place_pressed
signal jump_pressed
signal perspective_pressed
signal mode_pressed

var move_buttons := {"forward": false, "back": false, "left": false, "right": false}
var status_label: Label
var hint_label: Label
var active_look_touch := -1

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	var look_area := Control.new()
	look_area.name = "TouchLookArea"
	look_area.anchor_left = 0.5
	look_area.anchor_right = 1.0
	look_area.anchor_bottom = 1.0
	look_area.mouse_filter = Control.MOUSE_FILTER_STOP if OS.has_feature("mobile") else Control.MOUSE_FILTER_IGNORE
	root.add_child(look_area)
	look_area.gui_input.connect(_on_look_input)

	var header := VBoxContainer.new()
	header.anchor_right = 1.0
	header.offset_left = 24
	header.offset_top = 18
	header.offset_right = -24
	header.offset_bottom = 82
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)
	var title := Label.new()
	title.text = "VOXEBLOCKS  //  PROTÓTIPO 0.2"
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	status_label = Label.new()
	status_label.text = "Inicializando..."
	status_label.add_theme_color_override("font_color", Color("#e8f5e9"))
	header.add_child(status_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -8
	crosshair.offset_top = -16
	crosshair.offset_right = 8
	crosshair.offset_bottom = 16
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)

	var pad := GridContainer.new()
	pad.name = "MovementPad"
	pad.columns = 3
	pad.anchor_top = 1.0
	pad.anchor_bottom = 1.0
	pad.offset_left = 24
	pad.offset_top = -224
	pad.offset_right = 228
	pad.offset_bottom = -24
	pad.add_theme_constant_override("h_separation", 6)
	pad.add_theme_constant_override("v_separation", 6)
	root.add_child(pad)
	_add_spacer(pad)
	_make_move_button(pad, "↑", "forward")
	_add_spacer(pad)
	_make_move_button(pad, "←", "left")
	_make_move_button(pad, "↓", "back")
	_make_move_button(pad, "→", "right")
	_add_spacer(pad)
	_add_spacer(pad)
	_make_action_button(root, "PULAR", Vector2(0.0, 1.0), Vector2(-224, -224), Vector2(-124, -160), jump_pressed)

	var actions := VBoxContainer.new()
	actions.name = "ActionButtons"
	actions.anchor_left = 1.0
	actions.anchor_right = 1.0
	actions.anchor_top = 1.0
	actions.anchor_bottom = 1.0
	actions.offset_left = -224
	actions.offset_top = -224
	actions.offset_right = -24
	actions.offset_bottom = -24
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	_make_container_button(actions, "QUEBRAR", break_pressed)
	_make_container_button(actions, "COLOCAR", place_pressed)
	_make_container_button(actions, "CÂMERA", perspective_pressed)
	_make_container_button(actions, "MODO", mode_pressed)

	hint_label = Label.new()
	hint_label.text = "WASD / setas • Espaço: pular • V: câmera • M: modo • F/G: blocos"
	hint_label.anchor_left = 0.5
	hint_label.anchor_right = 0.5
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = -300
	hint_label.offset_top = -34
	hint_label.offset_right = 300
	hint_label.offset_bottom = -10
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color("#e8f5e9"))
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint_label)

func _add_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(64, 64)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)

func _make_move_button(parent: GridContainer, text: String, action: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(64, 64)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	button.button_down.connect(_set_move.bind(action, true))
	button.button_up.connect(_set_move.bind(action, false))

func _make_action_button(parent: Control, text: String, anchor: Vector2, top_left: Vector2, bottom_right: Vector2, signal_to_emit: Signal) -> void:
	var button := Button.new()
	button.text = text
	button.anchor_left = anchor.x
	button.anchor_right = anchor.x
	button.anchor_top = anchor.y
	button.anchor_bottom = anchor.y
	button.offset_left = top_left.x
	button.offset_top = top_left.y
	button.offset_right = bottom_right.x
	button.offset_bottom = bottom_right.y
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	button.pressed.connect(func() -> void: signal_to_emit.emit())

func _make_container_button(parent: Container, text: String, signal_to_emit: Signal) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 46)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	button.pressed.connect(func() -> void: signal_to_emit.emit())

func _set_move(action: String, pressed: bool) -> void:
	move_buttons[action] = pressed
	_emit_move()

func _emit_move() -> void:
	var value := Vector2(float(move_buttons["right"]) - float(move_buttons["left"]), float(move_buttons["back"]) - float(move_buttons["forward"]))
	move_changed.emit(value)

func _on_look_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_look_touch == -1:
			active_look_touch = event.index
		elif not event.pressed and event.index == active_look_touch:
			active_look_touch = -1
	elif event is InputEventScreenDrag and event.index == active_look_touch:
		look_changed.emit(event.relative)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_controls()

func release_controls() -> void:
	for action in move_buttons:
		move_buttons[action] = false
	active_look_touch = -1
	_emit_move()

func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func show_message(text: String) -> void:
	if hint_label != null:
		hint_label.text = text
