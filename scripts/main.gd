extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

func _ready() -> void:
    create_environment()
    create_street()
    create_player()
    create_mobile_controls()
    print("ابن البلد المصرية جاهزة للتجربة!")

func create_environment() -> void:
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-45, -30, 0)
    sun.light_energy = 1.2
    add_child(sun)

    var world_environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY

    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.75, 0.78, 0.85)
    env.ambient_light_energy = 0.8

    world_environment.environment = env
    add_child(world_environment)

func create_street() -> void:
    make_box(
        "Ground",
        Vector3(60, 0.5, 60),
        Vector3(0, -0.25, 0),
        Color(0.68, 0.57, 0.42),
        true
    )

    make_box(
        "Road",
        Vector3(10, 0.08, 60),
        Vector3(0, 0.025, 0),
        Color(0.20, 0.21, 0.22),
        false
    )

    make_box(
        "LeftSidewalk",
        Vector3(2, 0.18, 60),
        Vector3(-6, 0.09, 0),
        Color(0.78, 0.72, 0.61),
        true
    )

    make_box(
        "RightSidewalk",
        Vector3(2, 0.18, 60),
        Vector3(6, 0.09, 0),
        Color(0.78, 0.72, 0.61),
        true
    )

    for i in range(10):
        make_box(
            "RoadLine" + str(i),
            Vector3(0.15, 0.025, 2.2),
            Vector3(0, 0.08, -27 + i * 6),
            Color(1.0, 0.88, 0.52),
            false
        )

    for i in range(6):
        var z_position := -23.0 + float(i) * 9.0
        var left_height := 7.0 + float(i % 3) * 2.0
        var right_height := 8.0 + float(i % 2) * 3.0

        make_box(
            "LeftBuilding" + str(i),
            Vector3(6, left_height, 7),
            Vector3(-11, left_height / 2.0, z_position),
            building_color(i),
            true
        )

        make_box(
            "RightBuilding" + str(i),
            Vector3(6, right_height, 7),
            Vector3(11, right_height / 2.0, z_position),
            building_color(i + 2),
            true
        )

        make_box(
            "LeftShopFront" + str(i),
            Vector3(0.12, 1.2, 2.4),
            Vector3(-7.94, 1.5, z_position),
            Color(0.12, 0.48, 0.58),
            false
        )

        make_box(
            "RightShopFront" + str(i),
            Vector3(0.12, 1.2, 2.4),
            Vector3(7.94, 1.5, z_position),
            Color(0.66, 0.28, 0.16),
            false
        )

func building_color(index: int) -> Color:
    var colors: Array[Color] = [
        Color(0.78, 0.66, 0.51),
        Color(0.82, 0.76, 0.63),
        Color(0.67, 0.65, 0.57),
        Color(0.76, 0.59, 0.45),
        Color(0.73, 0.72, 0.62)
    ]
    return colors[index % colors.size()]

func create_player() -> void:
    var player := PLAYER_SCENE.instantiate() as CharacterBody3D

    if player == null:
        push_error("تعذر إنشاء اللاعب. راجع scenes/player.tscn")
        return

    player.name = "Player"
    player.position = Vector3(0, 0.1, 5)
    add_child(player)

func create_mobile_controls() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "MobileControls"
    add_child(canvas)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    canvas.add_child(root)

    # أزرار الحركة في أسفل يسار الشاشة
    make_touch_button(root, "↑", "ui_up", 100, -215, 170, -145)
    make_touch_button(root, "↓", "ui_down", 100, -75, 170, -5)
    make_touch_button(root, "←", "ui_left", 25, -145, 95, -75)
    make_touch_button(root, "→", "ui_right", 175, -145, 245, -75)

    # زر القفز أسفل يمين الشاشة
    var jump_button := Button.new()
    jump_button.text = "قفز"
    jump_button.focus_mode = Control.FOCUS_NONE
    jump_button.add_theme_font_size_override("font_size", 22)
    jump_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    jump_button.offset_left = -125
    jump_button.offset_top = -115
    jump_button.offset_right = -30
    jump_button.offset_bottom = -30
    root.add_child(jump_button)

    jump_button.button_down.connect(
        _press_action.bind("ui_accept")
    )
    jump_button.button_up.connect(
        _release_action.bind("ui_accept")
    )

func make_touch_button(
    root: Control,
    label: String,
    action_name: String,
    left: float,
    top: float,
    right: float,
    bottom: float
) -> void:
    var button := Button.new()
    button.text = label
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 28)
    button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    button.offset_left = left
    button.offset_top = top
    button.offset_right = right
    button.offset_bottom = bottom
    root.add_child(button)

    button.button_down.connect(
        _press_action.bind(action_name)
    )
    button.button_up.connect(
        _release_action.bind(action_name)
    )

func _press_action(action_name: String) -> void:
    Input.action_press(action_name)

func _release_action(action_name: String) -> void:
    Input.action_release(action_name)

func make_box(
    object_name: String,
    box_size: Vector3,
    box_position: Vector3,
    box_color: Color,
    has_collision: bool
) -> void:
    var holder: Node3D

    if has_collision:
        var body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = box_size
        collision.shape = shape
        body.add_child(collision)
        holder = body
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
    material.roughness = 0.85
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_instance.material_override = material

    holder.add_child(mesh_instance)
    add_child(holder)