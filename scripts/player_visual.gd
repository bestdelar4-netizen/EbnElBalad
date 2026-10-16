extends Node3D

# شخصية ابن البلد - نموذج ثلاثي الأبعاد متحرك
# يوضع هذا السكربت على CharacterVisual

const SKIN := Color("#B9794F")
const HAIR := Color("#211B19")
const SHIRT := Color("#D7D0BD")
const PANTS := Color("#303944")
const SHOES := Color("#EEE9DF")
const DARK := Color("#30241F")

var body_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D

var player: CharacterBody3D
var walk_time := 0.0


func _ready() -> void:
    player = get_parent() as CharacterBody3D
    build_character()


func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return

    var speed := Vector2(
        player.velocity.x,
        player.velocity.z
    ).length()

    var moving := speed > 0.15

    if moving:
        walk_time += delta * (12.0 if speed > 6.0 else 8.0)

    var swing := sin(walk_time) * 0.65 if moving else 0.0

    left_leg.rotation.x = swing
    right_leg.rotation.x = -swing

    left_arm.rotation.x = -swing * 0.8
    right_arm.rotation.x = swing * 0.8

    body_root.position.y = (
        0.025 + absf(sin(walk_time * 2.0)) * 0.035
        if moving else 0.0
    )


func build_character() -> void:
    body_root = Node3D.new()
    body_root.name = "IbnElBaladModel"
    add_child(body_root)

    # الجسم والقميص
    make_capsule(
        body_root, "Torso",
        Vector3(0, 1.12, 0),
        0.24, 0.72, SHIRT,
        Vector3(1.15, 1.0, 0.85)
    )

    # الرقبة والرأس
    make_capsule(
        body_root, "Neck",
        Vector3(0, 1.60, 0),
        0.09, 0.18, SKIN
    )

    make_sphere(
        body_root, "Head",
        Vector3(0, 1.84, 0),
        Vector3(0.23, 0.28, 0.21), SKIN
    )

    # الشعر
    make_sphere(
        body_root, "Hair",
        Vector3(0, 2.025, 0.015),
        Vector3(0.235, 0.115, 0.215), HAIR
    )

    # العينان والشارب - الوجه باتجاه -Z
    make_sphere(
        body_root, "LeftEye",
        Vector3(-0.08, 1.86, -0.195),
        Vector3(0.025, 0.025, 0.018), DARK
    )

    make_sphere(
        body_root, "RightEye",
        Vector3(0.08, 1.86, -0.195),
        Vector3(0.025, 0.025, 0.018), DARK
    )

    make_sphere(
        body_root, "Mustache",
        Vector3(0, 1.765, -0.205),
        Vector3(0.085, 0.025, 0.025), HAIR
    )

    # الذراعان
    left_arm = make_limb(
        body_root, "LeftArm",
        Vector3(-0.34, 1.43, 0),
        0.085, 0.48, SHIRT
    )

    right_arm = make_limb(
        body_root, "RightArm",
        Vector3(0.34, 1.43, 0),
        0.085, 0.48, SHIRT
    )

    # اليدان
    make_sphere(
        left_arm, "Hand",
        Vector3(0, -0.28, 0),
        Vector3(0.075, 0.085, 0.075), SKIN
    )

    make_sphere(
        right_arm, "Hand",
        Vector3(0, -0.28, 0),
        Vector3(0.075, 0.085, 0.075), SKIN
    )

    # الرجلان
    left_leg = make_limb(
        body_root, "LeftLeg",
        Vector3(-0.145, 0.78, 0),
        0.105, 0.48, PANTS
    )

    right_leg = make_limb(
        body_root, "RightLeg",
        Vector3(0.145, 0.78, 0),
        0.105, 0.48, PANTS
    )

    # الحذاء
    make_box(
        left_leg, "LeftShoe",
        Vector3(0, -0.255, -0.055),
        Vector3(0.17, 0.09, 0.26), SHOES
    )

    make_box(
        right_leg, "RightShoe",
        Vector3(0, -0.255, -0.055),
        Vector3(0.17, 0.09, 0.26), SHOES
    )

    # جيب القميص
    make_box(
        body_root, "ShirtPocket",
        Vector3(0.18, 1.28, -0.202),
        Vector3(0.07, 0.09, 0.018),
        Color("#B9AF9A")
    )


func make_limb(
    parent: Node3D,
    node_name: String,
    at: Vector3,
    radius: float,
    height: float,
    color: Color
) -> Node3D:
    var pivot := Node3D.new()
    pivot.name = node_name
    pivot.position = at
    parent.add_child(pivot)

    make_capsule(
        pivot, "Limb",
        Vector3(0, -height * 0.5, 0),
        radius, height, color
    )

    return pivot


func make_capsule(
    parent: Node3D,
    node_name: String,
    at: Vector3,
    radius: float,
    height: float,
    color: Color,
    stretch: Vector3 = Vector3.ONE
) -> MeshInstance3D:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name

    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = maxf(height, radius * 2.0)

    mesh_instance.mesh = mesh
    mesh_instance.position = at
    mesh_instance.scale = stretch
    mesh_instance.material_override = make_material(color)

    parent.add_child(mesh_instance)
    return mesh_instance


func make_sphere(
    parent: Node3D,
    node_name: String,
    at: Vector3,
    dimensions: Vector3,
    color: Color
) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name

    var mesh := SphereMesh.new()
    mesh.radius = 1.0
    mesh.height = 2.0

    instance.mesh = mesh
    instance.position = at
    instance.scale = dimensions
    instance.material_override = make_material(color)

    parent.add_child(instance)
    return instance


func make_box(
    parent: Node3D,
    node_name: String,
    at: Vector3,
    dimensions: Vector3,
    color: Color
) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name

    var mesh := BoxMesh.new()
    mesh.size = dimensions

    instance.mesh = mesh
    instance.position = at
    instance.material_override = make_material(color)

    parent.add_child(instance)
    return instance


func make_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    return material