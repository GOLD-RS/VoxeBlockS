extends Node3D

const WorldScript = preload("res://scripts/world.gd")
const PlayerScript = preload("res://scripts/player.gd")
const HUDScript = preload("res://scripts/hud.gd")

var world: VoxeWorld
var player: VoxePlayer
var hud: VoxeHUD
var creative_mode := false
var last_f_pressed := false
var last_g_pressed := false

func _ready() -> void:
    _setup_environment()

    world = WorldScript.new()
    world.name = "ProceduralWorld"
    add_child(world)

    player = PlayerScript.new()
    player.name = "Player"
    player.position = Vector3(0, 7, 0)
    add_child(player)

    hud = HUDScript.new()
    add_child(hud)
    hud.move_changed.connect(player.set_touch_move)
    hud.break_pressed.connect(_break_target)
    hud.place_pressed.connect(_place_target)
    hud.perspective_pressed.connect(player.toggle_perspective)
    hud.set_status("Sobrevivência  •  %d blocos  •  mundo procedural" % world.blocks.size())

func _process(_delta: float) -> void:
    if player == null or hud == null:
        return
    var f_pressed := Input.is_key_pressed(KEY_F)
    var g_pressed := Input.is_key_pressed(KEY_G)
    if f_pressed and not last_f_pressed:
        _break_target()
    if g_pressed and not last_g_pressed:
        _place_target()
    last_f_pressed = f_pressed
    last_g_pressed = g_pressed
    var mode := "Criativo" if creative_mode else "Sobrevivência"
    hud.set_status("%s  •  %d blocos  •  seed local" % [mode, world.blocks.size()])

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

func _raycast_block() -> Dictionary:
    var origin := player.get_view_origin()
    var target := origin + player.get_view_direction() * 7.0
    var query := PhysicsRayQueryParameters3D.create(origin, target)
    query.collision_mask = 1
    query.exclude = [player.get_rid()]
    return get_world_3d().direct_space_state.intersect_ray(query)

func _break_target() -> void:
    var hit := _raycast_block()
    if hit.is_empty():
        return
    var collider = hit.get("collider")
    if collider == null or not collider.has_meta("block_coord"):
        return
    var coord: Vector3i = collider.get_meta("block_coord")
    if world.remove_block(coord):
        hud.show_message("Bloco removido  •  G coloca um bloco")

func _place_target() -> void:
    var hit := _raycast_block()
    if hit.is_empty():
        return
    var collider = hit.get("collider")
    if collider == null or not collider.has_meta("block_coord"):
        return
    var base: Vector3i = collider.get_meta("block_coord")
    var normal: Vector3 = hit.get("normal", Vector3.UP)
    var offset := Vector3i(roundi(normal.x), roundi(normal.y), roundi(normal.z))
    var target := base + offset
    if world.add_block(target, "grass"):
        hud.show_message("Bloco colocado  •  F quebra um bloco")
