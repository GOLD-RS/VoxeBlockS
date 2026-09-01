extends Node
class_name VoxeWorldInteraction

const BlockTypesScript = preload("res://scripts/block_types.gd")
const WorldCoordsScript = preload("res://scripts/world_coords.gd")

var world
var player

func configure(world_ref, player_ref) -> void:
	world = world_ref
	player = player_ref

func try_break() -> bool:
	var hit := _raycast()
	if hit.is_empty():
		return false
	var target := _hit_block(hit)
	return world.remove_block(target)

func try_place() -> bool:
	var hit := _raycast()
	if hit.is_empty():
		return false
	var target := _hit_block(hit)
	var normal: Vector3 = hit.get("normal", Vector3.UP)
	var placement := target + Vector3i(roundi(normal.x), roundi(normal.y), roundi(normal.z))
	if not world.can_place_block(placement, player.global_position):
		return false
	return world.place_block(placement, BlockTypesScript.GRASS)

func _raycast() -> Dictionary:
	if world == null or player == null:
		return {}
	var origin: Vector3 = player.get_view_origin()
	var target: Vector3 = origin + player.get_view_direction() * 7.0
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	var collider = hit.get("collider")
	if collider == null or not collider.has_meta("voxel_chunk"):
		return {}
	return hit

func _hit_block(hit: Dictionary) -> Vector3i:
	return WorldCoordsScript.hit_to_block(hit.get("position", Vector3.ZERO), hit.get("normal", Vector3.UP))
