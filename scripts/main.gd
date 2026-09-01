extends Node3D

const InputActionsScript = preload("res://scripts/input_actions.gd")
const GameModeScript = preload("res://scripts/game_mode.gd")
const WorldScript = preload("res://scripts/world_manager.gd")
const PlayerScript = preload("res://scripts/player.gd")
const HUDScript = preload("res://scripts/hud.gd")
const InteractionScript = preload("res://scripts/world_interaction.gd")

var world
var player
var hud
var interaction
var game_mode
var status_timer := 0.0

func _ready() -> void:
	InputActionsScript.ensure()
	_setup_environment()

	world = WorldScript.new()
	world.name = "WorldManager"
	world.render_distance = int(ProjectSettings.get_setting("voxel/render_distance", 2))
	world.load_distance = int(ProjectSettings.get_setting("voxel/load_distance", 2))
	world.unload_distance = int(ProjectSettings.get_setting("voxel/unload_distance", 3))
	add_child(world)

	player = PlayerScript.new()
	player.name = "Player"
	add_child(player)
	world.initialize(player, int(ProjectSettings.get_setting("voxel/world_seed", 20260831)))
	player.global_position = world.get_spawn_position()

	game_mode = GameModeScript.new()

	interaction = InteractionScript.new()
	interaction.name = "WorldInteraction"
	interaction.configure(world, player)
	add_child(interaction)

	hud = HUDScript.new()
	hud.name = "HUD"
	add_child(hud)
	hud.move_changed.connect(player.set_touch_move)
	hud.look_changed.connect(player.apply_look)
	hud.break_pressed.connect(_break_block)
	hud.place_pressed.connect(_place_block)
	hud.jump_pressed.connect(_jump)
	hud.perspective_pressed.connect(player.toggle_perspective)
	hud.mode_pressed.connect(_toggle_mode)
	player.perspective_changed.connect(_on_perspective_changed)
	_update_status()

func _process(delta: float) -> void:
	status_timer -= delta
	if status_timer <= 0.0:
		status_timer = 0.25
		_update_status()
	if Input.is_action_just_pressed("break_block"):
		_break_block()
	if Input.is_action_just_pressed("place_block"):
		_place_block()
	if Input.is_action_just_pressed("toggle_mode"):
		_toggle_mode()

func _break_block() -> void:
	if interaction.try_break():
		hud.show_message("Bloco removido")

func _place_block() -> void:
	if interaction.try_place():
		hud.show_message("Bloco colocado")
	else:
		hud.show_message("Não é possível colocar aqui")

func _jump() -> void:
	if player.is_on_floor():
		player.velocity.y = player.JUMP_SPEED

func _toggle_mode() -> void:
	game_mode.toggle()
	hud.show_message("Modo: " + game_mode.display_name())

func _on_perspective_changed(is_third_person: bool) -> void:
	hud.show_message("Câmera: " + ("terceira pessoa" if is_third_person else "primeira pessoa"))

func _update_status() -> void:
	if world == null or hud == null or game_mode == null:
		return
	var stats: Dictionary = world.get_stats()
	hud.set_status("%s  •  %d chunks  •  %d faces  •  seed %d" % [game_mode.display_name(), stats["chunks"], stats["faces"], stats["seed"]])

func _setup_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#77bce8")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d7efff")
	environment.ambient_light_energy = 0.75
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("#fff1c1")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
