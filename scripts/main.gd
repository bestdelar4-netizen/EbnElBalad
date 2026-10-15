extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const JOYSTICK_SCRIPT: GDScript = preload("res://scripts/virtual_joystick.gd")

var player_reference: CharacterBody3D

# ألوان العمارات المصرية
var wall_colors: Array[Color] = [
    Color(0.76, 0.65, 0.51),
    Color(0.83, 0.77, 0.66),
    Color(0.65, 0.43, 0.31),
    Color(0.72, 0.70, 0.62),
    Color(0.58, 0.35, 0.25),
    Color(0.78, 0.57, 0.40)
]

func _ready() -> void:
    create_environment()
    create_street()
    create_mobile_controls()
    create_player()
    print("أهلاً بك في ابن البلد المصرية!")

# =========================================
# الإضاءة والسماء
# =========================================

func create_environment() -> void:
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-42, -30, 0)
    sun.light_energy = 1.25
    add_child(sun)

    var world := WorldEnvironment.new()
    var environment := Environment.new()

    environment.background_mode = Environment.BG_SKY

    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    environment.sky = sky

    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.78, 0.77, 0.71)
    environment.ambient_light_energy = 0.85

    world.environment = environment
    add_child(world)

# =========================================
# الشارع المصري
# =========================================

func create_street() -> void:
    make_box("Ground",
        Vector3(60, 0.5, 70),
        Vector3(0, -0.25, 0),
        Color(0.57, 0.46, 0.34), true)

    make_box("Road",
        Vector3(10, 0.08, 70),
        Vector3(0, 0.025, 0),
        Color(0.15, 0.16, 0.16), false)

    make_box("LeftSidewalk",
        Vector3(2, 0.18, 70),
        Vector3(-6, 0.09, 0),
        Color(0.69, 0.63, 0.52), true)

    make_box("RightSidewalk",
        Vector3(2, 0.18, 70),
        Vector3(6, 0.09, 0),
        Color(0.69, 0.63, 0.52), true)

    # علامات منتصف الطريق
    for i in range(12):
        make_box("RoadLine" + str(i),
            Vector3(0.13, 0.025, 2.1),
            Vector3(0, 0.08, -32 + i * 5.8),
            Color(0.93, 0.84, 0.61), false)

    # أعمدة إنارة على الجانبين
    for i in range(7):
        var z := -29.0 + float(i) * 9.0

        create_lamp(-7.0, z)
        create_lamp(7.0, z)

    # البيوت والمحلات على جانبي الشارع
    for i in range(7):
        var z := -27.0 + float(i) * 9.0

        create_building(-1, i, z)
        create_building(1, i + 2, z)

# =========================================
# بناء عمارة أو منزل ريفي
# =========================================

func create_building(
    side: int,
    index: int,
    z: float
) -> void:
    var village := index % 3 == 1
    var floors := 3 + (index % 3)

    if village:
        floors = 2 + (index % 2)

    var floor_height := 2.8
    var height := float(floors) * floor_height
    var center_x := float(side) * 11.0
    var front_x := float(side) * 7.96
    var facade := wall_colors[index % wall_colors.size()]

    # جسم المنزل
    make_box("Building_" + str(side) + "_" + str(index),
        Vector3(6.0, height, 7.0),
        Vector3(center_x, height / 2.0, z),
        facade, true)

    # خطوط وحواف خرسانية بين الأدوار
    for floor in range(1, floors):
        var y := float(floor) * floor_height

        make_box("ConcreteFloorBand",
            Vector3(0.15, 0.12, 6.15),
            Vector3(front_x, y, z),
            Color(0.86, 0.81, 0.70), false)

        # شبابيك الدور
        for window_index in range(2):
            var wz := z + (float(window_index) - 0.5) * 2.7
            var wy := y + 1.35

            create_window(front_x, wy, wz, side)

            # بلكونات مختلفة
            if (floor + window_index + index) % 2 == 0:
                create_balcony(front_x, y, wz, side, index)

            # تكييفات خارجية
            if (floor + window_index + index) % 3 == 0:
                make_box("AirConditioner",
                    Vector3(0.34, 0.35, 0.60),
                    Vector3(
                        front_x - float(side) * 0.15,
                        wy - 0.94,
                        wz
                    ),
                    Color(0.78, 0.80, 0.77), false)

    if village:
        create_village_entrance(front_x, z, side)
    else:
        create_shop(front_x, z, side, index)

    create_roof(center_x, height, z, index)

# =========================================
# الشبابيك
# =========================================

func create_window(
    front_x: float,
    y: float,
    z: float,
    side: int
) -> void:
    var outward := -float(side)

    make_box("WindowFrame",
        Vector3(0.14, 1.35, 1.15),
        Vector3(front_x, y, z),
        Color(0.88, 0.82, 0.70), false)

    make_box("WindowGlass",
        Vector3(0.055, 1.12, 0.91),
        Vector3(front_x + outward * 0.08, y, z),
        Color(0.13, 0.25, 0.30), false)

    make_box("WindowVerticalBar",
        Vector3(0.07, 1.12, 0.055),
        Vector3(front_x + outward * 0.12, y, z),
        Color(0.58, 0.59, 0.56), false)

    make_box("WindowHorizontalBar",
        Vector3(0.07, 0.055, 0.91),
        Vector3(front_x + outward * 0.12, y, z),
        Color(0.58, 0.59, 0.56), false)

# =========================================
# البلكونات والدرابزين والغسيل
# =========================================

func create_balcony(
    front_x: float,
    floor_y: float,
    z: float,
    side: int,
    index: int
) -> void:
    var outward := -float(side)
    var bx := front_x + outward * 0.40

    make_box("BalconyFloor",
        Vector3(0.78, 0.14, 1.70),
        Vector3(bx, floor_y + 0.05, z),
        Color(0.79, 0.73, 0.63), false)

    make_box("BalconyTopRail",
        Vector3(0.08, 0.09, 1.70),
        Vector3(front_x + outward * 0.80,
            floor_y + 0.80, z),
        Color(0.24, 0.25, 0.24), false)

    for i in range(8):
        var bar_z := z - 0.72 + float(i) * 0.205

        make_box("BalconyMetalBar",
            Vector3(0.07, 0.72, 0.045),
            Vector3(front_x + outward * 0.80,
                floor_y + 0.43, bar_z),
            Color(0.28, 0.29, 0.28), false)

    # جوانب الدرابزين
    for side_offset in [-0.78, 0.78]:
        make_box("BalconySideRail",
            Vector3(0.65, 0.07, 0.07),
            Vector3(bx, floor_y + 0.78,
                z + float(side_offset)),
            Color(0.28, 0.29, 0.28), false)

    # قطع غسيل ملونة في بعض البلكونات
    if index % 2 == 0:
        var cloth_color := Color(0.75, 0.20, 0.17)

        make_box("HangingLaundry",
            Vector3(0.04, 0.42, 0.48),
            Vector3(front_x + outward * 0.64,
                floor_y + 1.02, z + 0.20),
            cloth_color, false)

        make_box("HangingLaundry2",
            Vector3(0.04, 0.35, 0.40),
            Vector3(front_x + outward * 0.64,
                floor_y + 0.98, z - 0.34),
            Color(0.19, 0.38, 0.70), false)

# =========================================
# المحلات المصرية
# =========================================

func create_shop(
    front_x: float,
    z: float,
    side: int,
    index: int
) -> void:
    var outward := -float(side)

    # باب المحل المعدني
    make_box("ShopShutter",
        Vector3(0.14, 2.15, 1.75),
        Vector3(front_x, 1.16, z),
        Color(0.32, 0.34, 0.33), false)

    for i in range(8):
        make_box("ShutterRidge",
            Vector3(0.045, 0.035, 1.65),
            Vector3(front_x + outward * 0.09,
                0.35 + float(i) * 0.23, z),
            Color(0.57, 0.58, 0.55), false)

    var sign_colors: Array[Color] = [
        Color(0.10, 0.36, 0.25),
        Color(0.12, 0.30, 0.62),
        Color(0.68, 0.19, 0.13),
        Color(0.72, 0.43, 0.08),
        Color(0.30, 0.25, 0.44)
    ]

    make_box("ShopSignBoard",
        Vector3(0.16, 0.56, 2.35),
        Vector3(front_x + outward * 0.05, 2.62, z),
        sign_colors[index % sign_colors.size()], false)

    var shop_names: Array[String] = [
        "بقالة", "حلاق", "مخبز",
        "ملابس", "موبايلات", "كشري", "خضار"
    ]

    var sign := Label3D.new()
    sign.name = "ShopArabicSign"
    sign.text = shop_names[index % shop_names.size()]
    sign.font_size = 32
    sign.pixel_size = 0.008
    sign.modulate = Color(1.0, 0.91, 0.68)
    sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    sign.position = Vector3(
        front_x + outward * 0.15, 2.62, z
    )
    sign.rotation.y = -float(side) * PI / 2.0
    add_child(sign)

# =========================================
# بوابات البيوت القروية
# =========================================

func create_village_entrance(
    front_x: float,
    z: float,
    side: int
) -> void:
    var outward := -float(side)

    make_box("VillageGateFrame",
        Vector3(0.20, 2.35, 2.0),
        Vector3(front_x, 1.20, z),
        Color(0.80, 0.69, 0.54), false)

    make_box("VillageGateDoor",
        Vector3(0.10, 2.05, 1.62),
        Vector3(front_x + outward * 0.12, 1.12, z),
        Color(0.27, 0.20, 0.14), false)

    make_box("VillageSmallWindow",
        Vector3(0.12, 0.80, 0.85),
        Vector3(front_x, 1.85, z + 2.1),
        Color(0.17, 0.27, 0.30), false)

    make_box("VillageStep",
        Vector3(0.70, 0.13, 2.15),
        Vector3(front_x + outward * 0.35, 0.12, z),
        Color(0.66, 0.59, 0.49), false)

# =========================================
# الأسطح والخزانات وأطباق الدش
# =========================================

func create_roof(
    center_x: float,
    height: float,
    z: float,
    index: int
) -> void:
    make_box("RoofConcreteEdge",
        Vector3(5.95, 0.35, 6.95),
        Vector3(center_x, height + 0.12, z),
        Color(0.66, 0.60, 0.50), false)

    # خزان المياه
    make_box("RoofWaterTank",
        Vector3(1.0, 1.15, 1.0),
        Vector3(center_x + 1.3, height + 0.85, z + 1.2),
        Color(0.29, 0.36, 0.37), false)

    make_box("WaterTankBase",
        Vector3(1.2, 0.15, 1.2),
        Vector3(center_x + 1.3, height + 0.25, z + 1.2),
        Color(0.53, 0.51, 0.45), false)

    # أطباق دش فوق بعض البيوت
    if index % 2 == 0:
        var dish := MeshInstance3D.new()
        dish.name = "SatelliteDish"

        var dish_mesh := SphereMesh.new()
        dish_mesh.radius = 0.55
        dish_mesh.height = 0.18
        dish.mesh = dish_mesh

        var dish_material := StandardMaterial3D.new()
        dish_material.albedo_color = Color(0.72, 0.73, 0.70)
        dish_material.metallic = 0.45
        dish.material_override = dish_material

        dish.position = Vector3(
            center_x - 1.2, height + 0.65, z - 1.0
        )
        dish.rotation_degrees = Vector3(35, 0, 0)
        add_child(dish)

    # عمود هوائي
    if index % 3 == 0:
        make_box("RoofAntenna",
            Vector3(0.055, 1.5, 0.055),
            Vector3(center_x - 1.7, height + 0.95, z - 1.5),
            Color(0.35, 0.36, 0.34), false)

# =========================================
# أعمدة إنارة الشارع
# =========================================

func create_lamp(x: float, z: float) -> void:
    make_box("StreetLampPole",
        Vector3(0.12, 4.5, 0.12),
        Vector3(x, 2.25, z),
        Color(0.25, 0.26, 0.25), false)

    make_box("StreetLampArm",
        Vector3(0.75, 0.09, 0.09),
        Vector3(x - signf(x) * 0.30, 4.45, z),
        Color(0.25, 0.26, 0.25), false)

    make_box("StreetLampHead",
        Vector3(0.40, 0.16, 0.25),
        Vector3(x - signf(x) * 0.65, 4.40, z),
        Color(0.92, 0.80, 0.53), false)

# =========================================
# اللاعب
# =========================================

func create_player() -> void:
    player_reference = PLAYER_SCENE.instantiate() as CharacterBody3D

    if player_reference == null:
        push_error("تعذر إنشاء اللاعب. راجع scenes/player.tscn")
        return

    player_reference.name = "Player"
    player_reference.position = Vector3(0, 0.1, 5)
    add_child(player_reference)

# =========================================
# تحكم الموبايل
# =========================================

func create_mobile_controls() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "TouchControls"
    add_child(canvas)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    canvas.add_child(root)

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

    make_action_button(root, "قفز", -125, -115, "jump")
    make_action_button(root, "جري", -230, -115, "run")
    make_action_button(root, "تفاعل", -125, -220, "interact")

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
        player_reference.request_jump()

func _run_pressed() -> void:
    if player_reference != null:
        player_reference.set_running(true)

func _run_released() -> void:
    if player_reference != null:
        player_reference.set_running(false)

func _interact_pressed() -> void:
    if player_reference != null:
        player_reference.interact()

# =========================================
# إنشاء المجسمات والتصادمات
# =========================================

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
    material.roughness = 0.88
    material.metallic = 0.04

    mesh_instance.material_override = material
    holder.add_child(mesh_instance)
    add_child(holder)