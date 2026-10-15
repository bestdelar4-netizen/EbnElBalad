extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const JOYSTICK_SCRIPT: GDScript = preload("res://scripts/virtual_joystick.gd")

var player_reference: CharacterBody3D

func _ready() -> void:
    create_environment()
    create_street()
    create_player()
    create_mobile_controls()
    print("أهلاً بك في ابن البلد المصرية!")

# ------------------------------
# الإضاءة والسماء
# ------------------------------

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

# ------------------------------
# الشارع المصري
# ------------------------------

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

# ------------------------------
# إنشاء اللاعب
# ------------------------------

func create_player() -> void:
    player_reference = PLAYER_SCENE.instantiate() as CharacterBody3D

    if player_reference == null:
        push_error("تعذر إنشاء اللاعب. راجع scenes/player.tscn")
        return

    player_reference.name = "Player"
    player_reference.position = Vector3(0, 0.1, 5)
    add_child(player_reference)

# ------------------------------
# واجهة تحكم الموبايل
# ------------------------------

func create_mobile_controls() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "TouchControls"
    add_child(canvas)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    canvas.add_child(root)

    # عصا تحكم متحركة
    var joystick := Control.new()
    joystick.name = "VirtualJoystick"
    joystick.set_script(JOYSTICK_SCRIPT)
    joystick.add_to_group("virtual_joystick")
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.offset_left = 25
    joystick.offset_top = -210
    joystick.offset_right = 205
    joystick.offset_bottom = -30
    root.add_child(joystick)

    # زر القفز
    make_action_button(
        root, "قفز", -125, -115, "jump"
    )

    # زر الجري
    make_action_button(
        root, "جري", -230, -115, "run"
    )

    # زر التفاعل
    make_action_button(
        root, "تفاعل", -125, -220, "interact"
    )

func make_action_button(
    root: Control,
    label: String,
    left_offset: float,
    top_offset: float,
    action_type: String
) -> void:
    var button := Button.new()

    button.text = label
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)

    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    button.offset_left = left_offset
    button.offset_top = top_offset
    button.offset_right = left_offset + 90
    button.offset_bottom = top_offset + 75

    root.add_child(button)

    if action_type == "jump":
        button.button_down.connect(_jump_pressed)

    elif action_type == "run":
        button.button_down.connect(_run_pressed)
        button.button_up.connect(_run_released)

    elif action_type == "interact":
        button.pressed.connect(_interact_pressed)

func _jump_pressed() -> void:
    if player_reference != null:
        Input.action_press("ui_accept")
        Input.action_release("ui_accept")

func _run_pressed() -> void:
    if player_reference != null:
        player_reference.set_running(true)

func _run_released() -> void:
    if player_reference != null:
        player_reference.set_running(false)

func _interact_pressed() -> void:
    if player_reference != null:
        player_reference.interact()

# ------------------------------
# إنشاء المجسمات والتصادمات
# ------------------------------

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