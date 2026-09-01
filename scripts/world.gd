extends Node3D
class_name VoxeWorld

## Primeiro protótipo: blocos individuais mantêm a lógica simples e clara.
## O próximo passo de performance será trocar isso por chunks/meshes combinadas.
const WORLD_RADIUS := 9
var blocks: Dictionary = {}
var materials: Dictionary = {}

func _ready() -> void:
    _create_materials()
    generate()

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

func generate() -> void:
    for x in range(-WORLD_RADIUS, WORLD_RADIUS):
        for z in range(-WORLD_RADIUS, WORLD_RADIUS):
            var wave := sin(float(x) * 0.55) + cos(float(z) * 0.43) + sin(float(x + z) * 0.21)
            var height := clampi(2 + int(round(wave * 0.45)), 1, 4)
            for y in range(height):
                var kind := "grass" if y == height - 1 else ("dirt" if y > 0 else "stone")
                add_block(Vector3i(x, y, z), kind)

            # Árvores esparsas: já dão escala e identidade ao primeiro bioma.
            if height >= 3 and abs(x * 3 + z * 5) % 29 == 0:
                _add_tree(Vector3i(x, height, z))

func _add_tree(base: Vector3i) -> void:
    for y in range(3):
        add_block(base + Vector3i(0, y, 0), "wood")
    for dx in range(-2, 3):
        for dz in range(-2, 3):
            for dy in range(1, 3):
                if abs(dx) + abs(dz) + dy <= 4:
                    add_block(base + Vector3i(dx, 2 + dy, dz), "leaf")

func add_block(coord: Vector3i, kind: String = "grass") -> bool:
    if blocks.has(coord):
        return false

    var body := StaticBody3D.new()
    body.name = "Block_%d_%d_%d" % [coord.x, coord.y, coord.z]
    body.position = Vector3(coord.x + 0.5, coord.y + 0.5, coord.z + 0.5)
    body.set_meta("block_coord", coord)
    body.set_meta("block_kind", kind)
    body.collision_layer = 1
    body.collision_mask = 0

    var mesh_instance := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE
    mesh_instance.mesh = cube
    mesh_instance.material_override = materials.get(kind, materials["grass"])
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE
    collision.shape = shape
    body.add_child(collision)

    add_child(body)
    blocks[coord] = body
    return true

func remove_block(coord: Vector3i) -> bool:
    if coord.y <= 0 or not blocks.has(coord):
        return false
    var body: Node3D = blocks[coord]
    blocks.erase(coord)
    body.queue_free()
    return true

func has_block(coord: Vector3i) -> bool:
    return blocks.has(coord)
