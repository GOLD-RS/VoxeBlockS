extends RefCounted
class_name TerrainGenerator

const BlockTypesScript = preload("res://scripts/block_types.gd")
const WorldCoordsScript = preload("res://scripts/world_coords.gd")

var world_seed: int

func _init(seed_value: int = 20260831) -> void:
	world_seed = seed_value

func height_at(x: int, z: int) -> int:
	var seed_x := posmod(world_seed, 997)
	var seed_z := posmod(world_seed, 991)
	var wave := sin(float(x + seed_x) * 0.055) * 2.0
	wave += cos(float(z - seed_z) * 0.071) * 1.5
	wave += sin(float(x + z + world_seed) * 0.021) * 1.2
	return clampi(4 + int(round(wave)), 1, WorldCoordsScript.MAX_Y - 6)

func get_block_type(world: Vector3i) -> int:
	if not WorldCoordsScript.is_valid_world(world):
		return BlockTypesScript.AIR

	var structure_block := _tree_block_at(world)
	if structure_block != BlockTypesScript.AIR:
		return structure_block

	var surface_height := height_at(world.x, world.z)
	if world.y >= surface_height:
		return BlockTypesScript.AIR
	if world.y == surface_height - 1:
		return BlockTypesScript.GRASS
	if world.y >= surface_height - 4:
		return BlockTypesScript.DIRT
	return BlockTypesScript.STONE

func _tree_block_at(world: Vector3i) -> int:
	if world.y < 3:
		return BlockTypesScript.AIR
	for anchor_x in range(world.x - 2, world.x + 3):
		for anchor_z in range(world.z - 2, world.z + 3):
			if not _is_tree_anchor(anchor_x, anchor_z):
				continue
			var base_y := height_at(anchor_x, anchor_z)
			var delta_x := world.x - anchor_x
			var delta_z := world.z - anchor_z
			if delta_x == 0 and delta_z == 0 and world.y >= base_y and world.y < base_y + 3:
				return BlockTypesScript.WOOD
			var leaf_layer := world.y - base_y - 2
			if leaf_layer >= 1 and leaf_layer <= 2 and abs(delta_x) + abs(delta_z) + leaf_layer <= 4:
				return BlockTypesScript.LEAF
	return BlockTypesScript.AIR

func _is_tree_anchor(x: int, z: int) -> bool:
	return height_at(x, z) >= 5 and posmod(_hash2(x, z), 31) == 0

func _hash2(x: int, z: int) -> int:
	var value: int = world_seed
	value ^= x * 374761393
	value ^= z * 668265263
	value = (value ^ (value >> 13)) * 1274126177
	value ^= value >> 16
	return value & 0x7fffffff
