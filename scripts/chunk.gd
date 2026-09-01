extends Node3D
class_name VoxeChunk

const BlockTypesScript = preload("res://scripts/block_types.gd")
const WorldCoordsScript = preload("res://scripts/world_coords.gd")

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

var coordinate := Vector2i.ZERO
var data
var world
var shared_materials: Dictionary = {}
var visual: MeshInstance3D
var collision_body: StaticBody3D
var collision_shape: CollisionShape3D
var visible_face_count := 0

func _init() -> void:
	visual = MeshInstance3D.new()
	visual.name = "Visual"
	add_child(visual)
	collision_body = StaticBody3D.new()
	collision_body.name = "Collision"
	collision_body.collision_layer = 1
	collision_body.collision_mask = 0
	collision_body.set_meta("voxel_chunk", true)
	add_child(collision_body)
	collision_shape = CollisionShape3D.new()
	collision_body.add_child(collision_shape)

func configure(chunk_coordinate: Vector2i, chunk_data, world_ref, materials: Dictionary) -> void:
	coordinate = chunk_coordinate
	data = chunk_data
	world = world_ref
	shared_materials = materials
	position = Vector3(coordinate.x * WorldCoordsScript.CHUNK_SIZE, 0, coordinate.y * WorldCoordsScript.CHUNK_SIZE)
	collision_body.set_meta("chunk_coordinate", coordinate)

func rebuild() -> void:
	if data == null or world == null:
		return
	var by_material: Dictionary = {}
	var collision_faces: Array[Vector3] = []
	visible_face_count = 0

	for y in range(WorldCoordsScript.MIN_Y, WorldCoordsScript.MAX_Y + 1):
		for z in range(WorldCoordsScript.CHUNK_SIZE):
			for x in range(WorldCoordsScript.CHUNK_SIZE):
				var local := Vector3i(x, y, z)
				var block_id: int = data.get_block(local)
				if block_id == BlockTypesScript.AIR:
					continue
				var world_coord := WorldCoordsScript.chunk_to_world(coordinate, local)
				for face_index in range(DIRECTIONS.size()):
					var neighbor_id: int = world.get_block_for_mesh(world_coord + DIRECTIONS[face_index])
					if BlockTypesScript.is_solid(neighbor_id):
						continue
					if not by_material.has(block_id):
						by_material[block_id] = {"vertices": [], "normals": [], "uvs": [], "indices": []}
					_append_face(by_material[block_id], collision_faces, local, face_index)
					visible_face_count += 1

	var mesh := ArrayMesh.new()
	for block_id in by_material:
		var face_data: Dictionary = by_material[block_id]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(face_data["vertices"])
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(face_data["normals"])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(face_data["uvs"])
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(face_data["indices"])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, shared_materials[block_id])

	visual.mesh = mesh if mesh.get_surface_count() > 0 else null
	if collision_faces.is_empty():
		collision_shape.shape = null
	else:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(PackedVector3Array(collision_faces))
		collision_shape.shape = shape

func _append_face(face_data: Dictionary, collision_faces: Array[Vector3], local: Vector3i, face_index: int) -> void:
	var corners: Array = FACE_CORNERS[face_index]
	var origin := Vector3(local.x, local.y, local.z)
	var normal: Vector3 = NORMALS[face_index]
	var vertices: Array = face_data["vertices"]
	var normals: Array = face_data["normals"]
	var uvs: Array = face_data["uvs"]
	var indices: Array = face_data["indices"]
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
