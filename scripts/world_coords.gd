extends RefCounted
class_name WorldCoords

const CHUNK_SIZE := 16
const MIN_Y := 0
const MAX_Y := 31
const HIT_EPSILON := 0.001

static func world_to_chunk(world: Vector3i) -> Vector2i:
	return Vector2i(floori(float(world.x) / CHUNK_SIZE), floori(float(world.z) / CHUNK_SIZE))

static func world_to_local(world: Vector3i) -> Vector3i:
	var chunk := world_to_chunk(world)
	return Vector3i(world.x - chunk.x * CHUNK_SIZE, world.y, world.z - chunk.y * CHUNK_SIZE)

static func chunk_to_world(chunk: Vector2i, local: Vector3i) -> Vector3i:
	return Vector3i(chunk.x * CHUNK_SIZE + local.x, local.y, chunk.y * CHUNK_SIZE + local.z)

static func is_valid_local(local: Vector3i) -> bool:
	return local.x >= 0 and local.x < CHUNK_SIZE and local.z >= 0 and local.z < CHUNK_SIZE and local.y >= MIN_Y and local.y <= MAX_Y

static func is_valid_world(world: Vector3i) -> bool:
	return world.y >= MIN_Y and world.y <= MAX_Y and abs(world.x) <= 1000000 and abs(world.z) <= 1000000

static func is_boundary(local: Vector3i, direction: Vector3i) -> bool:
	return (direction.x < 0 and local.x == 0) or (direction.x > 0 and local.x == CHUNK_SIZE - 1) or (direction.z < 0 and local.z == 0) or (direction.z > 0 and local.z == CHUNK_SIZE - 1)

static func hit_to_block(hit_position: Vector3, face_normal: Vector3) -> Vector3i:
	# O epsilon só compensa o arredondamento do raycast na superfície do cubo.
	var sample := hit_position - face_normal * HIT_EPSILON
	return Vector3i(floori(sample.x), floori(sample.y), floori(sample.z))
