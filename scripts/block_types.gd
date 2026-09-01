extends RefCounted
class_name BlockTypes

const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const WOOD := 4
const LEAF := 5

static func is_solid(block_id: int) -> bool:
	return block_id != AIR

static func name_of(block_id: int) -> String:
	match block_id:
		GRASS: return "grass"
		DIRT: return "dirt"
		STONE: return "stone"
		WOOD: return "wood"
		LEAF: return "leaf"
		_: return "air"

static func all_renderable() -> Array[int]:
	return [GRASS, DIRT, STONE, WOOD, LEAF]
