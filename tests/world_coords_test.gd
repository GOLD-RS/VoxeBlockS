extends SceneTree

const WorldCoordsScript = preload("res://scripts/world_coords.gd")

func _init() -> void:
	_check(Vector3i(-1, 3, -1), Vector2i(-1, -1), Vector3i(15, 3, 15))
	_check(Vector3i(-8, 3, -8), Vector2i(-1, -1), Vector3i(8, 3, 8))
	_check(Vector3i(-9, 3, -9), Vector2i(-1, -1), Vector3i(7, 3, 7))
	_check(Vector3i(15, 3, 15), Vector2i(0, 0), Vector3i(15, 3, 15))
	_check(Vector3i(16, 3, 16), Vector2i(1, 1), Vector3i(0, 3, 0))
	var chunk := Vector2i(-2, 4)
	var local := Vector3i(7, 12, 9)
	var world := WorldCoordsScript.chunk_to_world(chunk, local)
	assert(WorldCoordsScript.world_to_chunk(world) == chunk)
	assert(WorldCoordsScript.world_to_local(world) == local)
	print("world_coords_test: PASS")
	quit(0)

func _check(world: Vector3i, expected_chunk: Vector2i, expected_local: Vector3i) -> void:
	assert(WorldCoordsScript.world_to_chunk(world) == expected_chunk)
	assert(WorldCoordsScript.world_to_local(world) == expected_local)
