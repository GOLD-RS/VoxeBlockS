extends SceneTree

const BlockTypesScript = preload("res://scripts/block_types.gd")
const ChunkDataScript = preload("res://scripts/chunk_data.gd")
const TerrainGeneratorScript = preload("res://scripts/terrain_generator.gd")

func _init() -> void:
	var first = TerrainGeneratorScript.new(123456)
	var second = TerrainGeneratorScript.new(123456)
	for x in range(-20, 21, 5):
		for z in range(-20, 21, 5):
			for y in range(0, 12, 3):
				var coordinate := Vector3i(x, y, z)
				assert(first.get_block_type(coordinate) == second.get_block_type(coordinate))
	var data = ChunkDataScript.new(Vector2i(-1, 2))
	data.set_block(Vector3i(15, 4, 15), BlockTypesScript.STONE)
	assert(data.get_block(Vector3i(15, 4, 15)) == BlockTypesScript.STONE)
	assert(data.get_block(Vector3i(-1, 4, 0)) == BlockTypesScript.AIR)
	assert(data.get_block(Vector3i(0, 32, 0)) == BlockTypesScript.AIR)
	print("terrain_test: PASS")
	quit(0)
