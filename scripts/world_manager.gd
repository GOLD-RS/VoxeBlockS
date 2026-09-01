extends Node3D
class_name VoxeWorldManager

const BlockTypesScript = preload("res://scripts/block_types.gd")
const WorldCoordsScript = preload("res://scripts/world_coords.gd")
const ChunkDataScript = preload("res://scripts/chunk_data.gd")
const TerrainGeneratorScript = preload("res://scripts/terrain_generator.gd")
const ChunkScript = preload("res://scripts/chunk.gd")

@export var render_distance := 2
@export var load_distance := 2
@export var unload_distance := 3
@export var max_chunk_loads_per_frame := 1
@export var max_chunk_rebuilds_per_frame := 2

var world_seed := 20260831
var generator
var player
var chunks: Dictionary = {}
var dirty_chunks: Dictionary = {}
var load_queue: Array[Vector2i] = []
var queued_chunks: Dictionary = {}
var modified_blocks: Dictionary = {}
var shared_materials: Dictionary = {}
var stream_timer := 0.0
var initialized := false

func _ready() -> void:
	_create_materials()

func initialize(player_ref, seed_value: int) -> void:
	player = player_ref
	world_seed = seed_value
	generator = TerrainGeneratorScript.new(world_seed)
	initialized = true
	var center := chunk_from_position(player.global_position)
	# Apenas o anel inicial é síncrono; o restante entra na fila para não travar o frame.
	for x in range(center.x - 1, center.x + 2):
		for z in range(center.y - 1, center.y + 2):
			_load_chunk(Vector2i(x, z), false)
	for key in chunks:
		chunks[key].rebuild()
	dirty_chunks.clear()
	_refresh_streaming(center)

func _process(delta: float) -> void:
	if not initialized or player == null:
		return
	stream_timer -= delta
	if stream_timer <= 0.0:
		stream_timer = 0.25
		_refresh_streaming(chunk_from_position(player.global_position))
	for _i in range(max_chunk_loads_per_frame):
		_load_next_chunk()
	for _i in range(max_chunk_rebuilds_per_frame):
		_rebuild_next_dirty()

func chunk_from_position(position_3d: Vector3) -> Vector2i:
	return WorldCoordsScript.world_to_chunk(Vector3i(floori(position_3d.x), 0, floori(position_3d.z)))

func get_spawn_position() -> Vector3:
	var surface: int = generator.height_at(0, 0)
	return Vector3(0.5, surface + 2.0, 0.5)

func get_block(world_coord: Vector3i) -> int:
	if not WorldCoordsScript.is_valid_world(world_coord):
		return BlockTypesScript.AIR
	if modified_blocks.has(world_coord):
		return modified_blocks[world_coord]
	var key := WorldCoordsScript.world_to_chunk(world_coord)
	if chunks.has(key):
		return chunks[key].data.get_block(WorldCoordsScript.world_to_local(world_coord))
	return generator.get_block_type(world_coord)

func get_block_for_mesh(world_coord: Vector3i) -> int:
	if not WorldCoordsScript.is_valid_world(world_coord):
		return BlockTypesScript.AIR
	var key := WorldCoordsScript.world_to_chunk(world_coord)
	if not chunks.has(key):
		# Chunk não carregado é vazio para que a fronteira visível seja fechada.
		return BlockTypesScript.AIR
	return chunks[key].data.get_block(WorldCoordsScript.world_to_local(world_coord))

func remove_block(world_coord: Vector3i) -> bool:
	return set_block(world_coord, BlockTypesScript.AIR)

func place_block(world_coord: Vector3i, block_id: int) -> bool:
	return set_block(world_coord, block_id)

func set_block(world_coord: Vector3i, block_id: int) -> bool:
	if not WorldCoordsScript.is_valid_world(world_coord):
		return false
	var key := WorldCoordsScript.world_to_chunk(world_coord)
	if not chunks.has(key):
		return false
	var local := WorldCoordsScript.world_to_local(world_coord)
	if block_id == BlockTypesScript.AIR and local.y == WorldCoordsScript.MIN_Y:
		return false
	var chunk_data = chunks[key].data
	if chunk_data.get_block(local) == block_id:
		return false
	chunk_data.set_block(local, block_id)
	var generated_id: int = generator.get_block_type(world_coord)
	if block_id == generated_id:
		modified_blocks.erase(world_coord)
	else:
		modified_blocks[world_coord] = block_id
	mark_dirty(key)
	_mark_boundary_neighbors(key, local)
	return true

func can_place_block(world_coord: Vector3i, actor_position: Vector3, actor_radius := 0.38, actor_height := 1.8) -> bool:
	if not WorldCoordsScript.is_valid_world(world_coord) or get_block(world_coord) != BlockTypesScript.AIR:
		return false
	var block_min := Vector3(world_coord.x, world_coord.y, world_coord.z)
	var block_max := block_min + Vector3.ONE
	var actor_min := actor_position + Vector3(-actor_radius, 0, -actor_radius)
	var actor_max := actor_position + Vector3(actor_radius, actor_height, actor_radius)
	return not (block_max.x <= actor_min.x or block_min.x >= actor_max.x or block_max.y <= actor_min.y or block_min.y >= actor_max.y or block_max.z <= actor_min.z or block_min.z >= actor_max.z)

func mark_dirty(key: Vector2i) -> void:
	if chunks.has(key):
		dirty_chunks[key] = true

func _mark_boundary_neighbors(key: Vector2i, local: Vector3i) -> void:
	if local.x == 0:
		mark_dirty(Vector2i(key.x - 1, key.y))
	if local.x == WorldCoordsScript.CHUNK_SIZE - 1:
		mark_dirty(Vector2i(key.x + 1, key.y))
	if local.z == 0:
		mark_dirty(Vector2i(key.x, key.y - 1))
	if local.z == WorldCoordsScript.CHUNK_SIZE - 1:
		mark_dirty(Vector2i(key.x, key.y + 1))

func _refresh_streaming(center: Vector2i) -> void:
	var valid_queue: Array[Vector2i] = []
	for queued_key in load_queue:
		if maxi(abs(queued_key.x - center.x), abs(queued_key.y - center.y)) <= load_distance:
			valid_queue.append(queued_key)
		else:
			queued_chunks.erase(queued_key)
	load_queue = valid_queue
	var candidates: Array = []
	for x in range(center.x - load_distance, center.x + load_distance + 1):
		for z in range(center.y - load_distance, center.y + load_distance + 1):
			var key := Vector2i(x, z)
			if not chunks.has(key) and not queued_chunks.has(key):
				candidates.append({"key": key, "distance": maxi(abs(x - center.x), abs(z - center.y))})
	candidates.sort_custom(func(a, b): return a["distance"] < b["distance"])
	for candidate in candidates:
		var key: Vector2i = candidate["key"]
		load_queue.append(key)
		queued_chunks[key] = true

	for key in chunks.keys():
		var distance := maxi(abs(key.x - center.x), abs(key.y - center.y))
		chunks[key].visible = distance <= render_distance
		if distance > unload_distance:
			var old_chunk = chunks[key]
			chunks.erase(key)
			dirty_chunks.erase(key)
			old_chunk.queue_free()

func _load_next_chunk() -> void:
	if load_queue.is_empty():
		return
	var key: Vector2i = load_queue.pop_front()
	queued_chunks.erase(key)
	if not chunks.has(key):
		_load_chunk(key)

func _load_chunk(key: Vector2i, rebuild_immediately := true) -> void:
	var chunk_data = ChunkDataScript.new(key)
	for y in range(WorldCoordsScript.MIN_Y, WorldCoordsScript.MAX_Y + 1):
		for z in range(WorldCoordsScript.CHUNK_SIZE):
			for x in range(WorldCoordsScript.CHUNK_SIZE):
				var local := Vector3i(x, y, z)
				var world_coord := WorldCoordsScript.chunk_to_world(key, local)
				var block_id: int = modified_blocks.get(world_coord, generator.get_block_type(world_coord))
				chunk_data.set_block(local, block_id)
	var chunk = ChunkScript.new()
	chunk.configure(key, chunk_data, self, shared_materials)
	add_child(chunk)
	chunks[key] = chunk
	if rebuild_immediately:
		chunk.rebuild()
	mark_dirty(Vector2i(key.x - 1, key.y))
	mark_dirty(Vector2i(key.x + 1, key.y))
	mark_dirty(Vector2i(key.x, key.y - 1))
	mark_dirty(Vector2i(key.x, key.y + 1))

func _rebuild_next_dirty() -> void:
	if dirty_chunks.is_empty():
		return
	var key: Vector2i = dirty_chunks.keys()[0]
	dirty_chunks.erase(key)
	if chunks.has(key):
		chunks[key].rebuild()

func _create_materials() -> void:
	for block_id in BlockTypesScript.all_renderable():
		var material := StandardMaterial3D.new()
		material.roughness = 1.0
		match block_id:
			BlockTypesScript.GRASS: material.albedo_color = Color("#6fcf63")
			BlockTypesScript.DIRT: material.albedo_color = Color("#9b6b45")
			BlockTypesScript.STONE: material.albedo_color = Color("#88939b")
			BlockTypesScript.WOOD: material.albedo_color = Color("#a97449")
			BlockTypesScript.LEAF: material.albedo_color = Color("#4eae68")
		shared_materials[block_id] = material

func get_stats() -> Dictionary:
	var face_count := 0
	for key in chunks:
		face_count += chunks[key].visible_face_count
	return {"chunks": chunks.size(), "dirty": dirty_chunks.size(), "faces": face_count, "seed": world_seed}
