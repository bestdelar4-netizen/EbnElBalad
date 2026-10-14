extends Node3D

const PLAYER_SCENE = preload("res://scenes/player.tscn")

func _ready() -> void:
    create_world()
    create_street()
    create_player()
    print("أهلاً بك في ابن البلد المصرية!")

func create_world() -> void:
    var world_light := DirectionalLight3D.new()
    world_light.rotation_degrees = Vector3(-45, -30, 0)
    add_child(world_light)

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.environment = env
    add_child(environment)

func create_street() -> void:
    # الأرض
    make_box(
        "Ground",
        Vector3(60, 0.5, 60),
        Vector3(0, -0.25, 0),
        Color(0.55, 0.48, 0.36),
        true
    )

    # الطريق الأسفلتي
    make_box(
        "EgyptianRoad",
        Vector3(10, 0.08, 60),
        Vector3(0, 0.04, 0),
        Color(0.16, 0.17, 0.18),
        false
    )

    # خط منتصف الطريق
    for i in range(10):
        make_box(
            "RoadLine" + str(i),
            Vector3(0.15, 0.03, 2),
            Vector3(0, 0.1, -27 + i * 6),
            Color(0.95, 0.88, 0.58),
            false
        )

    # مباني على جانبي الشارع
    for i in range(6):
        var z := -24.0 + i * 9.0

        make_box(
            "LeftBuilding" + str(i),
            Vector3(6, 7 + (i % 3) * 2, 7),
            Vector3(-9, (7 + (i % 3) * 2) / 2.0, z),
            Color(0.72, 0.61, 0.46),
            true
        )

        make_box(
            "RightBuilding" + str(i),
            Vector3(6, 8 + (i % 2) * 3, 7),
            Vector3(9, (8 + (i % 2) * 3) / 2.0, z),
            Color(0.68, 0.66, 0.57),
            true
        )

func create_player() -> void:
    var player = PLAYER_SCENE.instantiate()
    player.position = Vector3(0, 0.1, 5)
    add_child(player)

func make_box(
    object_name: String,
    box_size: Vector3,
    box_position: Vector3,
    box_color: Color,
    has_collision: bool
) -> void:
    var holder: Node3D

    if has_collision:
        holder = StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = box_size
        collision.shape = shape
        holder.add_child(collision)
    else:
        holder = Node3D.new()

    holder.name = object_name
    holder.position = box_position

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = box_size
    mesh_instance.mesh = mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = box_color
    mesh_instance.material_override = material
    holder.add_child(mesh_instance)

    add_child(holder)