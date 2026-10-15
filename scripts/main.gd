
extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const JOYSTICK_SCRIPT: GDScript = preload("res://scripts/virtual_joystick.gd")
const WORLD_MANAGER_SCRIPT: GDScript = preload("res://scripts/world/world_manager.gd")

var player_reference: CharacterBody3D
var world_manager: Node3D

const ROAD_SPACING: float = 60.0
const ROAD_LENGTH: float = 480.0
const STREET_COUNT: int = 5

var wall_colors: Array[Color] = [
    Color(0.76, 0.65, 0.51),
    Color(0.83, 0.77, 0.66),
    Color(0.65, 0.43, 0.31),
    Color(0.72, 0.70, 0.62),
    Color(0.58, 0.35, 0.25),
    Color(0.78, 0.57, 0.40),
    Color(0.72, 0.68, 0.58),
    Color(0.61, 0.57, 0.48)
]

var shop_colors: Array[Color] = [
    Color(0.10, 0.36, 0.25),
    Color(0.12, 0.30, 0.62),
    Color(0.68, 0.19, 0.13),
    Color(0.72, 0.43, 0.08),
    Color(0.30, 0.25, 0.44)
]

var shop_names: Array[String] = [
    "بقالة", "حلاق", "مخبز",
    "ملابس", "موبايلات", "كشري",
    "خضار", "مطعم", "قهوة"
]


func _ready() -> void:
    create_environment()
    create_world_manager()
    create_world()
    create_mobile_controls()
    create_player()

    print("أهلاً بك في ابن البلد المصرية!")
    print("تم إنشاء الحي المصري الأول.")


# ==================================================
# البيئة والسماء والإضاءة
# ==================================================

func create_environment() -> void:
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-42, -30, 0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    var world := WorldEnvironment.new()
    var environment := Environment.new()

    environment.background_mode = Environment.BG_SKY

    var sky := Sky.new()
    var sky_material := ProceduralSkyMaterial.new()
    sky_material.sky_top_color = Color(0.15, 0.39, 0.68)
    sky_material.sky_horizon_color = Color(0.65, 0.76, 0.86)
    sky_material.ground_bottom_color = Color(0.19, 0.17, 0.14)
    sky_material.ground_horizon_color = Color(0.57, 0.53, 0.44)

    sky.sky_material = sky_material
    environment.sky = sky

    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.78, 0.77, 0.71)
    environment.ambient_light_energy = 0.8
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

    world.environment = environment
    add_child(world)


# ==================================================
# مدير العالم
# ==================================================

func create_world_manager() -> void:
    world_manager = Node3D.new()
    world_manager.name = "WorldManager"
    world_manager.set_script(WORLD_MANAGER_SCRIPT)
    add_child(world_manager)


# ==================================================
# إنشاء الحي المصري الواسع
# ==================================================

func create_world() -> void:
    make_box(
        "WorldGround",
        Vector3(340, 0.5, ROAD_LENGTH + 40.0),
        Vector3(0, -0.30, 0),
        Color(0.48, 0.42, 0.32),
        true
    )

    # شوارع طولية متوازية
    for street_index in range(STREET_COUNT):
        var road_x := (float(street_index) - 2.0) * ROAD_SPACING
        create_long_street(road_x, street_index)

    # شوارع عرضية تربط الشوارع الطولية
    for cross_index in range(7):
        var cross_z := -180.0 + float(cross_index) * 60.0
        create_cross_street(cross_z, cross_index)

    # المباني على جانبي الشوارع الطولية
    for street_index in range(STREET_COUNT):
        var road_x := (float(street_index) - 2.0) * ROAD_SPACING

        for building_index in range(16):
            var building_z := -210.0 + float(building_index) * 28.0

            if is_near_cross_street(building_z):
                continue

            create_building(
                road_x,
                -1,
                street_index * 100 + building_index,
                building_z
            )

            create_building(
                road_x,
                1,
                street_index * 100 + building_index + 35,
                building_z
            )

    create_landmarks()


func is_near_cross_street(z: float) -> bool:
    for cross_index in range(7):
        var cross_z := -180.0 + float(cross_index) * 60.0

        if absf(z - cross_z) < 13.0:
            return true

    return false


# ==================================================
# الشوارع الطولية
# ==================================================

func create_long_street(road_x: float, street_index: int) -> void:
    make_box(
        "Road_%d" % street_index,
        Vector3(12.0, 0.08, ROAD_LENGTH),
        Vector3(road_x, 0.0, 0.0),
        Color(0.13, 0.14, 0.14),
        false
    )

    for side in [-1, 1]:
        make_box(
            "Sidewalk_%d_%d" % [street_index, side],
            Vector3(2.0, 0.20, ROAD_LENGTH),
            Vector3(road_x + float(side) * 7.0, 0.10, 0.0),
            Color(0.65, 0.60, 0.51),
            true
        )

        make_box(
            "Curb_%d_%d" % [street_index, side],
            Vector3(0.20, 0.25, ROAD_LENGTH),
            Vector3(road_x + float(side) * 6.0, 0.12, 0.0),
            Color(0.79, 0.74, 0.65),
            true
        )

    # علامات منتصف الطريق
    for mark_index in range(48):
        var mark_z := -230.0 + float(mark_index) * 9.5

        make_box(
            "RoadMark_%d_%d" % [street_index, mark_index],
            Vector3(0.14, 0.025, 2.8),
            Vector3(road_x, 0.055, mark_z),
            Color(0.93, 0.86, 0.68),
            false
        )

    # أعمدة الإنارة
    for lamp_index in range(12):
        var lamp_z := -215.0 + float(lamp_index) * 39.0

        create_lamp(road_x - 7.7, lamp_z, 1)
        create_lamp(road_x + 7.7, lamp_z, -1)


# ==================================================
# الشوارع العرضية
# ==================================================

func create_cross_street(z: float, index: int) -> void:
    make_box(
        "CrossRoad_%d" % index,
        Vector3(340.0, 0.085, 12.0),
        Vector3(0, 0.015, z),
        Color(0.14, 0.15, 0.15),
        false
    )

    make_box(
        "CrossSidewalkA_%d" % index,
        Vector3(340.0, 0.18, 1.8),
        Vector3(0, 0.09, z - 7.0),
        Color(0.65, 0.60, 0.51),
        true
    )

    make_box(
        "CrossSidewalkB_%d" % index,
        Vector3(340.0, 0.18, 1.8),
        Vector3(0, 0.09, z + 7.0),
        Color(0.65, 0.60, 0.51),
        true
    )

    # خطوط عبور بسيطة عند التقاطعات
    for mark_index in range(15):
        var mark_x := -140.0 + float(mark_index) * 20.0

        make_box(
            "CrossMark_%d_%d" % [index, mark_index],
            Vector3(1.5, 0.025, 0.18),
            Vector3(mark_x, 0.065, z),
            Color(0.84, 0.81, 0.72),
            false
        )


# ==================================================
# إنشاء المباني
# ==================================================

func create_building(
    road_x: float,
    side: int,
    index: int,
    z: float
) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = abs(index * 7919 + int(road_x * 31.0) + 101)

    var is_village := index % 4 == 1
    var floors := rng.randi_range(3, 5)

    if is_village:
        floors = rng.randi_range(1, 2)

    var floor_height := 2.9
    var building_height := float(floors) * floor_height
    var center_x := road_x + float(side) * 11.0
    var front_x := road_x + float(side) * 8.0
    var facade := wall_colors[rng.randi_range(0, wall_colors.size() - 1)]

    # جسم المبنى
    make_box(
        "Building_%d" % index,
        Vector3(6.0, building_height, 8.0),
        Vector3(center_x, building_height / 2.0, z),
        facade,
        true
    )

    # السطح والحافة الخرسانية
    make_box(
        "RoofEdge_%d" % index,
        Vector3(6.1, 0.30, 8.1),
        Vector3(center_x, building_height + 0.12, z),
        Color(0.62, 0.57, 0.48),
        false
    )

    # تفاصيل كل دور
    for floor_index in range(floors):
        var base_y := float(floor_index) * floor_height
        var window_y := base_y + 1.65

        make_box(
            "FloorBand_%d_%d" % [index, floor_index],
            Vector3(0.13, 0.12, 8.05),
            Vector3(front_x, base_y + 0.10, z),
            Color(0.87, 0.80, 0.68),
            false
        )

        for window_index in range(2):
            var window_z := z + (float(window_index) - 0.5) * 3.0

            create_window(
                front_x,
                window_y,
                window_z,
                side,
                index,
                floor_index,
                window_index
            )

            if (index + floor_index + window_index) % 2 == 0:
                create_balcony(
                    front_x,
                    base_y,
                    window_z,
                    side,
                    index
                )

            if (index + floor_index + window_index) % 3 == 0:
                create_air_conditioner(
                    front_x,
                    window_y,
                    window_z,
                    side
                )

    if is_village:
        create_village_entrance(front_x, z, side)
    else:
        create_shop(front_x, z, side, index)

    create_roof_details(center_x, building_height, z, index)


# ==================================================
# الشبابيك
# ==================================================

func create_window(
    front_x: float,
    y: float,
    z: float,
    side: int,
    building_id: int,
    floor_id: int,
    window_id: int
) -> void:
    var outward := -float(side)

    make_box(
        "WindowFrame_%d_%d_%d" % [building_id, floor_id, window_id],
        Vector3(0.16, 1.35, 1.25),
        Vector3(front_x, y, z),
        Color(0.86, 0.79, 0.66),
        false
    )

    make_box(
        "WindowGlass",
        Vector3(0.055, 1.12, 1.02),
        Vector3(front_x + outward * 0.10, y, z),
        Color(0.12, 0.25, 0.32),
        false
    )

    make_box(
        "WindowBarVertical",
        Vector3(0.06, 1.10, 0.055),
        Vector3(front_x + outward * 0.14, y, z),
        Color(0.35, 0.37, 0.36),
        false
    )

    make_box(
        "WindowBarHorizontal",
        Vector3(0.06, 0.055, 1.02),
        Vector3(front_x + outward * 0.14, y, z),
        Color(0.35, 0.37, 0.36),
        false
    )


# ==================================================
# البلكونات
# ==================================================

func create_balcony(
    front_x: float,
    floor_y: float,
    z: float,
    side: int,
    building_id: int
) -> void:
    var outward := -float(side)
    var bx := front_x + outward * 0.42

    make_box(
        "BalconyFloor",
        Vector3(0.85, 0.15, 1.85),
        Vector3(bx, floor_y + 0.05, z),
        Color(0.75, 0.70, 0.61),
        false
    )

    make_box(
        "BalconyTopRail",
        Vector3(0.08, 0.08, 1.85),
        Vector3(front_x + outward * 0.83, floor_y + 0.83, z),
        Color(0.22, 0.24, 0.23),
        false
    )

    for bar_index in range(8):
        var bar_z := z - 0.78 + float(bar_index) * 0.22

        make_box(
            "BalconyBar",
            Vector3(0.065, 0.75, 0.045),
            Vector3(
                front_x + outward * 0.83,
                floor_y + 0.43,
                bar_z
            ),
            Color(0.26, 0.28, 0.27),
            false
        )

    # بعض الملابس المعلقة
    if building_id % 2 == 0:
        make_box(
            "LaundryRed",
            Vector3(0.035, 0.40, 0.38),
            Vector3(front_x + outward * 0.67, floor_y + 1.08, z + 0.25),
            Color(0.72, 0.18, 0.16),
            false
        )

        make_box(
            "LaundryBlue",
            Vector3(0.035, 0.32, 0.36),
            Vector3(front_x + outward * 0.67, floor_y + 1.02, z - 0.27),
            Color(0.20, 0.36, 0.68),
            false
        )


# ==================================================
# وحدات التكييف
# ==================================================

func create_air_conditioner(
    front_x: float,
    y: float,
    z: float,
    side: int
) -> void:
    make_box(
        "AirConditioner",
        Vector3(0.36, 0.34, 0.65),
        Vector3(front_x + float(side) * 0.18, y - 0.92, z),
        Color(0.78, 0.80, 0.77),
        false
    )


# ==================================================
# المحلات واللافتات العربية
# ==================================================

func create_shop(
    front_x: float,
    z: float,
    side: int,
    index: int
) -> void:
    var outward := -float(side)

    make_box(
        "ShopDoor",
        Vector3(0.14, 2.15, 1.85),
        Vector3(front_x, 1.16, z),
        Color(0.26, 0.28, 0.27),
        false
    )

    for ridge_index in range(8):
        make_box(
            "ShutterRidge",
            Vector3(0.045, 0.035, 1.72),
            Vector3(
                front_x + outward * 0.09,
                0.35 + float(ridge_index) * 0.23,
                z
            ),
            Color(0.53, 0.55, 0.52),
            false
        )

    make_box(
        "ShopSignBoard",
        Vector3(0.16, 0.56, 2.5),
        Vector3(front_x + outward * 0.05, 2.65, z),
        shop_colors[index % shop_colors.size()],
        false
    )

    var sign := Label3D.new()
    sign.name = "ArabicShopSign"
    sign.text = shop_names[index % shop_names.size()]
    sign.font_size = 32
    sign.pixel_size = 0.008
    sign.modulate = Color(1.0, 0.91, 0.68)
    sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    sign.position = Vector3(
        front_x + outward * 0.15,
        2.65,
        z
    )
    sign.rotation.y = -float(side) * PI / 2.0
    add_child(sign)


# ==================================================
# مداخل البيوت الريفية
# ==================================================

func create_village_entrance(
    front_x: float,
    z: float,
    side: int
) -> void:
    var outward := -float(side)

    make_box(
        "VillageDoorFrame",
        Vector3(0.20, 2.30, 1.95),
        Vector3(front_x, 1.20, z),
        Color(0.79, 0.67, 0.51),
        false
    )

    make_box(
        "VillageDoor",
        Vector3(0.10, 2.05, 1.60),
        Vector3(front_x + outward * 0.12, 1.12, z),
        Color(0.25, 0.18, 0.12),
        false
    )

    make_box(
        "VillageStep",
        Vector3(0.75, 0.14, 2.10),
        Vector3(front_x + outward * 0.35, 0.12, z),
        Color(0.63, 0.57, 0.47),
        false
    )


# ==================================================
# تفاصيل الأسطح
# ==================================================

func create_roof_details(
    center_x: float,
    height: float,
    z: float,
    index: int
) -> void:
    make_box(
        "WaterTankBase",
        Vector3(1.35, 0.15, 1.35),
        Vector3(center_x + 1.2, height + 0.30, z + 1.2),
        Color(0.53, 0.51, 0.45),
        false
    )

    make_box(
        "WaterTank",
        Vector3(1.0, 1.10, 1.0),
        Vector3(center_x + 1.2, height + 0.90, z + 1.2),
        Color(0.28, 0.36, 0.37),
        false
    )

    if index % 2 == 0:
        var dish := MeshInstance3D.new()
        dish.name = "SatelliteDish"

        var dish_mesh := SphereMesh.new()
        dish_mesh.radius = 0.48
        dish_mesh.height = 0.18
        dish.mesh = dish_mesh

        var material := StandardMaterial3D.new()
        material.albedo_color = Color(0.70, 0.72, 0.70)
        material.metallic = 0.4
        material.roughness = 0.5
        dish.material_override = material

        dish.position = Vector3(center_x - 1.25, height + 0.65, z - 1.0)
        dish.rotation_degrees = Vector3(35, 0, 0)
        add_child(dish)


# ==================================================
# أعمدة الإنارة
# ==================================================

func create_lamp(x: float, z: float, direction: int) -> void:
    make_box(
        "StreetLampPole",
        Vector3(0.12, 4.5, 0.12),
        Vector3(x, 2.25, z),
        Color(0.23, 0.25, 0.24),
        false
    )

    make_box(
        "StreetLampArm",
        Vector3(0.75, 0.09, 0.09),
        Vector3(x + float(direction) * 0.30, 4.45, z),
        Color(0.23, 0.25, 0.24),
        false
    )

    make_box(
        "StreetLampHead",
        Vector3(0.40, 0.16, 0.25),
        Vector3(x + float(direction) * 0.65, 4.40, z),
        Color(0.92, 0.80, 0.53),
        false
    )


# ==================================================
# علامات مميزة للحي
# ==================================================

func create_landmarks() -> void:
    # مساحة خضراء صغيرة
    make_box(
        "NeighborhoodPark",
        Vector3(24.0, 0.12, 22.0),
        Vector3(26.0, 0.02, 20.0),
        Color(0.25, 0.39, 0.20),
        true
    )

    # ممر داخل المساحة الخضراء
    make_box(
        "ParkPath",
        Vector3(3.0, 0.08, 22.0),
        Vector3(26.0, 0.12, 20.0),
        Color(0.68, 0.60, 0.46),
        false
    )


# ==================================================
# إنشاء اللاعب
# ==================================================

func create_player() -> void:
    player_reference = PLAYER_SCENE.instantiate() as CharacterBody3D

    if player_reference == null:
        push_error("تعذر إنشاء اللاعب. راجع scenes/player.tscn")
        return

    player_reference.name = "Player"
    player_reference.position = Vector3(0, 0.1, 5)
    add_child(player_reference)

    # ربط اللاعب بمدير العالم
    if world_manager != null and world_manager.has_method("set_player"):
        world_manager.call("set_player", player_reference)


# ==================================================
# أزرار التحكم بالموبايل
# ==================================================

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
    if is_instance_valid(player_reference):
        player_reference.request_jump()


func _run_pressed() -> void:
    if is_instance_valid(player_reference):
        player_reference.set_running(true)


func _run_released() -> void:
    if is_instance_valid(player_reference):
        player_reference.set_running(false)


func _interact_pressed() -> void:
    if is_instance_valid(player_reference):
        player_reference.interact()


# ==================================================
# إنشاء المجسمات والتصادمات
# ==================================================

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
        body.collision_layer = 1
        body.collision_mask = 1

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
