extends CharacterBody3D
class_name VoxePlayer

signal perspective_changed(is_third_person: bool)

const WALK_SPEED := 5.5
const JUMP_SPEED := 7.0
const GRAVITY := 18.0
var touch_move := Vector2.ZERO
var yaw := 0.0
var pitch := -0.25
var is_third_person := false
var camera_pivot: Node3D
var camera: Camera3D
var visual: MeshInstance3D

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    _build_body()
    _apply_camera()
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    visual = MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.38
    capsule_mesh.height = 1.8
    visual.mesh = capsule_mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#f3b45b")
    material.roughness = 0.85
    visual.material_override = material
    visual.position.y = 0.9
    add_child(visual)

    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.1, 0)
    add_child(camera_pivot)

    camera = Camera3D.new()
    camera.current = true
    camera.fov = 72.0
    camera.near = 0.05
    camera.far = 120.0
    camera_pivot.add_child(camera)

func _physics_process(delta: float) -> void:
    var keyboard := Vector2(
        float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
        float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    )
    var move_input := keyboard
    if touch_move.length() > 0.05:
        move_input = touch_move
    if move_input.length() > 1.0:
        move_input = move_input.normalized()

    var direction := Vector3(move_input.x, 0, move_input.y).rotated(Vector3.UP, yaw)
    velocity.x = move_toward(velocity.x, direction.x * WALK_SPEED, 24.0 * delta)
    velocity.z = move_toward(velocity.z, direction.z * WALK_SPEED, 24.0 * delta)
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif Input.is_key_pressed(KEY_SPACE):
        velocity.y = JUMP_SPEED
    else:
        velocity.y = -0.5
    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_V:
        toggle_perspective()
    elif event is InputEventMouseMotion and not OS.has_feature("mobile"):
        yaw -= event.relative.x * 0.003
        pitch = clamp(pitch - event.relative.y * 0.003, -1.2, 0.85)
        _apply_camera_rotation()

func set_touch_move(value: Vector2) -> void:
    touch_move = value

func toggle_perspective() -> void:
    is_third_person = not is_third_person
    _apply_camera()
    perspective_changed.emit(is_third_person)

func _apply_camera() -> void:
    if camera == null:
        return
    visual.visible = is_third_person
    if is_third_person:
        camera.position = Vector3(0, 2.4, 6.5)
    else:
        camera.position = Vector3(0, 0.55, 0.0)
    _apply_camera_rotation()

func _apply_camera_rotation() -> void:
    if camera_pivot != null:
        camera_pivot.rotation = Vector3(pitch, yaw, 0)

func get_view_origin() -> Vector3:
    return camera.global_position

func get_view_direction() -> Vector3:
    return -camera.global_transform.basis.z.normalized()
