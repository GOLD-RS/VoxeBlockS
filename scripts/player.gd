extends CharacterBody3D
class_name VoxePlayer

signal perspective_changed(is_third_person: bool)

const WALK_SPEED := 5.5
const JUMP_SPEED := 7.0
const GRAVITY := 18.0
const LOOK_SENSITIVITY := 0.003

var touch_move := Vector2.ZERO
var yaw := 0.0
var pitch := -0.25
var is_third_person := false
var visual: MeshInstance3D
var camera_pivot: Node3D
var first_person_camera: Camera3D
var third_person_camera: Camera3D
var spring_arm: SpringArm3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.2
	floor_stop_on_slope = true
	_build_body()
	_apply_camera()

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

	first_person_camera = Camera3D.new()
	first_person_camera.name = "FirstPersonCamera"
	first_person_camera.fov = 72.0
	first_person_camera.near = 0.05
	first_person_camera.far = 160.0
	first_person_camera.position = Vector3(0, 0.55, 0)
	camera_pivot.add_child(first_person_camera)

	spring_arm = SpringArm3D.new()
	spring_arm.name = "ThirdPersonSpringArm"
	spring_arm.spring_length = 6.5
	spring_arm.margin = 0.25
	spring_arm.collision_mask = 1
	spring_arm.position = Vector3(0, 0.25, 0)
	camera_pivot.add_child(spring_arm)
	third_person_camera = Camera3D.new()
	third_person_camera.name = "ThirdPersonCamera"
	third_person_camera.fov = 72.0
	third_person_camera.near = 0.05
	third_person_camera.far = 160.0
	spring_arm.add_child(third_person_camera)

func _physics_process(delta: float) -> void:
	var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_input := keyboard if keyboard.length() > 0.05 else touch_move
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	var direction := Vector3(move_input.x, 0, move_input.y).rotated(Vector3.UP, yaw)
	velocity.x = move_toward(velocity.x, direction.x * WALK_SPEED, 24.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * WALK_SPEED, 24.0 * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_SPEED
	else:
		velocity.y = -0.5
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look(event.relative)
	if Input.is_action_just_pressed("toggle_camera"):
		toggle_perspective()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_touch_move(value: Vector2) -> void:
	touch_move = value

func apply_look(delta: Vector2) -> void:
	yaw -= delta.x * LOOK_SENSITIVITY
	pitch = clamp(pitch - delta.y * LOOK_SENSITIVITY, -1.2, 0.85)
	_apply_camera_rotation()

func toggle_perspective() -> void:
	is_third_person = not is_third_person
	_apply_camera()
	perspective_changed.emit(is_third_person)

func _apply_camera() -> void:
	if first_person_camera == null:
		return
	first_person_camera.current = not is_third_person
	third_person_camera.current = is_third_person
	visual.visible = is_third_person
	_apply_camera_rotation()

func _apply_camera_rotation() -> void:
	if camera_pivot != null:
		camera_pivot.rotation = Vector3(pitch, yaw, 0)

func get_view_origin() -> Vector3:
	return third_person_camera.global_position if is_third_person else first_person_camera.global_position

func get_view_direction() -> Vector3:
	var active_camera := third_person_camera if is_third_person else first_person_camera
	return -active_camera.global_transform.basis.z.normalized()
