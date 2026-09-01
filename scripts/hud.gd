extends CanvasLayer
class_name VoxeHUD

signal move_changed(value: Vector2)
signal break_pressed
signal place_pressed
signal perspective_pressed

var move_buttons := {"forward": false, "back": false, "left": false, "right": false}
var status_label: Label
var hint_label: Label

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var title := Label.new()
    title.text = "VOXEBLOCKS  //  PROTÓTIPO 0.1"
    title.position = Vector2(28, 20)
    title.add_theme_font_size_override("font_size", 22)
    root.add_child(title)

    status_label = Label.new()
    status_label.text = "Carregando mundo..."
    status_label.position = Vector2(30, 52)
    status_label.add_theme_color_override("font_color", Color("#e8f5e9"))
    root.add_child(status_label)

    hint_label = Label.new()
    hint_label.text = "WASD / setas: mover   •   Espaço: pular   •   V: câmera   •   F: quebrar   •   G: colocar"
    hint_label.position = Vector2(28, 675)
    hint_label.add_theme_color_override("font_color", Color("#e8f5e9"))
    root.add_child(hint_label)

    _make_button(root, "↑", Vector2(90, 485), "forward")
    _make_button(root, "←", Vector2(20, 555), "left")
    _make_button(root, "↓", Vector2(90, 625), "back")
    _make_button(root, "→", Vector2(160, 555), "right")

    var break_button := _make_action_button(root, "QUEBRAR", Vector2(1060, 530))
    break_button.pressed.connect(func() -> void: break_pressed.emit())
    var place_button := _make_action_button(root, "COLOCAR", Vector2(1160, 530))
    place_button.pressed.connect(func() -> void: place_pressed.emit())
    var camera_button := _make_action_button(root, "CÂMERA", Vector2(1080, 620))
    camera_button.pressed.connect(func() -> void: perspective_pressed.emit())

func _make_button(parent: Control, text: String, position: Vector2, action: String) -> Button:
    var button := Button.new()
    button.text = text
    button.position = position
    button.size = Vector2(64, 64)
    button.focus_mode = Control.FOCUS_NONE
    parent.add_child(button)
    button.button_down.connect(_set_move.bind(action, true))
    button.button_up.connect(_set_move.bind(action, false))
    return button

func _make_action_button(parent: Control, text: String, position: Vector2) -> Button:
    var button := Button.new()
    button.text = text
    button.position = position
    button.size = Vector2(90, 64)
    button.focus_mode = Control.FOCUS_NONE
    parent.add_child(button)
    return button

func _set_move(action: String, pressed: bool) -> void:
    move_buttons[action] = pressed
    var value := Vector2(
        float(move_buttons["right"]) - float(move_buttons["left"]),
        float(move_buttons["back"]) - float(move_buttons["forward"])
    )
    move_changed.emit(value)

func set_status(text: String) -> void:
    if status_label != null:
        status_label.text = text

func show_message(text: String) -> void:
    if hint_label != null:
        hint_label.text = text
