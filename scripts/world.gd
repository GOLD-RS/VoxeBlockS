extends Node3D
class_name VoxeWorld

## Mundo em voxels dividido em chunks. Cada chunk vira uma malha única,
## reduzindo drasticamente os nós e draw calls em relação ao protótipo inicial.
const WORLD_RADIUS := 16
const CHUNK_SIZE := 8
const DIRECTIONS := [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0),
	Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)
]
const NORMALS := [
	Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0),
	Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)
]
const FACE_CORNERS := [
	[Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)],
	[Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)],
	[Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)],
	[Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1)],
	[Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)]
]

var blocks: Dictionary = {}
var chunk_nodes: Dictionary = {}
var materials: Dictionary = {}

func _ready() -> void:
	_create_materials()
	_generate()
	_rebuild_all_chunks()

func _create_materials() -> void:
	materials["grass"] = _material(Color("#6fcf63"))
	materials["dirt"] = _material(Color("#9b6b45"))
	materials["stone"] = _material(Color("#88939b"))
	materials["wood"] = _material(Color("#a97449"))
	materials["leaf"] = _material(Color("#4eae68"))

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func _generate() -> void:
	for x in range(-WORLD_RADIUS, WORLD_RADIUS):
		for z in range(-WORLD_RADIUS, WORLD_RADIUS):
			var wave := sin(float(x) * 0.55) + cos(float(z) * 0.43) + sin(float(x + z) * 0.21)
			var height := clampi(2 + int(round(wave * 0.45)), 1, 4)
			for y in range(height):
				var kind := "grass" if y == height - 1 else ("dirt" if y > 0 else "stone")
				blocks[Vector3i(x, y, z)] = kind
			if height >= 3 and abs(x * 3 + z * 5) % 29 == 0:
				_add_tree(Vector3i(x, height, z))

func _add_tree(base: Vector3i) -> void:
	for y in range(3):
		blocks[base + Vector3i(0, y, 0)] = "wood"
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			for dy in range(1, 3):
				if abs(dx) + abs(dz) + dy <= 4:
					blocks[base + Vector3i(dx, 2 + dy, dz)] = "leaf"

func add_block(coord: Vector3i, kind: String = "grass") -> bool:
	if blocks.has(coord):
		return false
	blocks[coord] = kind
	_rebuild_near(coord)
	return true

func remove_block(coord: Vector3i) -> bool:
	if coord.y <= 0 or not blocks.has(coord):
		return false
	blocks.erase(coord)
	_rebuild_near(coord)
	return true

func has_block(coord: Vector3i) -> bool:
	return blocks.has(coord)

func _chunk_key(coord: Vector3i) -> Vector2i:
	return Vector2i(floori(float(coord.x) / CHUNK_SIZE), floori(float(coord.z) / CHUNK_SIZE))

func _rebuild_all_chunks() -> void:
	var keys: Dictionary = {}
	for coord in blocks:
		keys[_chunk_key(coord)] = true
	for key in keys:
		_rebuild_chunk(key)

func _rebuild_near(coord: Vector3i) -> void:
	var center := _chunk_key(coord)
	for x in range(center.x - 1, center.x + 2):
		for z in range(center.y - 1, center.y + 2):
			_rebuild_chunk(Vector2i(x, z))

func _rebuild_chunk(key: Vector2i) -> void:
	if chunk_nodes.has(key):
		chunk_nodes[key].queue_free()
		chunk_nodes.erase(key)

	var by_kind: Dictionary = {}
	var collision_faces: Array[Vector3] = []
	for coord in blocks:
		if _chunk_key(coord) != key:
			continue
		var kind: String = blocks[coord]
		if not by_kind.has(kind):
			by_kind[kind] = {"vertices": [], "normals": [], "uvs": [], "indices": []}
		for face_index in range(DIRECTIONS.size()):
			var neighbor: Vector3i = coord + DIRECTIONS[face_index]
			if blocks.has(neighbor):
				continue
			_append_face(by_kind[kind], collision_faces, coord, face_index)

	if by_kind.is_empty():
		return

	var chunk := Node3D.new()
	chunk.name = "Chunk_%d_%d" % [key.x, key.y]
	var mesh := ArrayMesh.new()
	for kind in by_kind:
		var data: Dictionary = by_kind[kind]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(data["vertices"])
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(data["normals"])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(data["uvs"])
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(data["indices"])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, materials[kind])

	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	chunk.add_child(visual)

	var body := StaticBody3D.new()
	body.name = "Collision"
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("voxel_chunk", true)
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(PackedVector3Array(collision_faces))
	collision.shape = shape
	body.add_child(collision)
	chunk.add_child(body)
	add_child(chunk)
	chunk_nodes[key] = chunk

func _append_face(data: Dictionary, collision_faces: Array[Vector3], coord: Vector3i, face_index: int) -> void:
	var corners: Array = FACE_CORNERS[face_index]
	var origin := Vector3(coord.x, coord.y, coord.z)
	var normal: Vector3 = NORMALS[face_index]
	var vertices: Array = data["vertices"]
	var normals: Array = data["normals"]
	var uvs: Array = data["uvs"]
	var indices: Array = data["indices"]
	var start := vertices.size()
	for corner in corners:
		vertices.append(origin + corner)
		normals.append(normal)
	uvs.append(Vector2(corner.x + corner.z, corner.y))
	indices.append(start)
	indices.append(start + 1)
	indices.append(start + 2)
	indices.append(start)
	indices.append(start + 2)
	indices.append(start + 3)
	for triangle_index in [0, 1, 2, 0, 2, 3]:
		collision_faces.append(origin + corners[triangle_index])
