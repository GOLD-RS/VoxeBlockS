extends RefCounted
class_name ChunkData

const BlockTypesScript = preload("res://scripts/block_types.gd")
const WorldCoordsScript = preload("res://scripts/world_coords.gd")

var coordinate := Vector2i.ZERO
var blocks := PackedByteArray()

func _init(chunk_coordinate: Vector2i = Vector2i.ZERO) -> void:
	coordinate = chunk_coordinate
	blocks.resize(WorldCoordsScript.CHUNK_SIZE * (WorldCoordsScript.MAX_Y + 1) * WorldCoordsScript.CHUNK_SIZE)

func get_block(local: Vector3i) -> int:
	if not WorldCoordsScript.is_valid_local(local):
		return BlockTypesScript.AIR
	return blocks[_index(local)]

func set_block(local: Vector3i, block_id: int) -> void:
	if not WorldCoordsScript.is_valid_local(local):
		return
	blocks[_index(local)] = clampi(block_id, BlockTypesScript.AIR, BlockTypesScript.LEAF)

func _index(local: Vector3i) -> int:
	return local.x + local.y * WorldCoordsScript.CHUNK_SIZE + local.z * WorldCoordsScript.CHUNK_SIZE * (WorldCoordsScript.MAX_Y + 1)
