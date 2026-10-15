extends RefCounted

# نظام إنشاء البيوت المصرية - Godot 4

const STREET_LENGTH: float = 60.0

func build(parent: Node3D) -> void:
    # الأرض والطريق والأرصفة
    _box(parent, "EgyptGround",
        Vector3(60, 0.5, STREET_LENGTH),
        Vector3(0, -0.25, 0),
        Color(0.60, 0.49, 0.36), true)

    _box(parent, "EgyptRoad",
        Vector3(10, 0.08, STREET_LENGTH),
        Vector3(0, 0.025, 0),
        Color(0.16, 0.17, 0.17), false)

    _box(parent, "LeftSidewalk",
        Vector3(2, 0.18, STREET_LENGTH),
        Vector3(-6, 0.09, 0),
        Color(0.69, 0.64, 0.54), true)

    _box(parent, "RightSidewalk",
        Vector3(2, 0.18, STREET_LENGTH),
        Vector3(6, 0.09, 0),
        Color(0.69, 0.64, 0.54), true)

    for i in range(10):
        _box(parent, "RoadMark" + str(i),
            Vector3(0.14, 0.025, 2.0),
            Vector3(0, 0.08, -27.0 + float(i) * 6.0),
            Color(0.92, 0.83, 0.59), false)

    # ستة مبانٍ على كل جانب
    for i in range(6):
        var z := -23.0 + float(i) * 9.0

        _make_building(parent, -1, i, z)
        _make_building(parent, 1, i + 2, z)

    print("تم إنشاء الحارة المصرية والمباني!")

func _make_building(
    parent: Node3D,
    side: int,
    index: int,
    z: float
) -> void:
    var is_village: bool = index % 3 == 1
    var floors: int

    if is_village:
        floors = 2 + (index % 2)
    else:
        floors = 3 + (index % 2)

    var height: float = 3.0 + float(floors - 1) * 2.7
    var center_x: float = float(side) * 11.0
    var facade_x: float = float(side) * 7.94

    var colors: Array[Color] = [
        Color(0.72, 0.61, 0.48),
        Color(0.78, 0.72, 0.60),
        Color(0.66, 0.62, 0.53),
        Color(0.75, 0.55, 0.40),
        Color(0.82, 0.77, 0.66),
        Color(0.59, 0.43, 0.31)
    ]

    var facade_color: Color = colors[index % colors.size()]

    if is_village:
        facade_color = Color(0.61, 0.32, 0.21)

    var building_name := "EgyptBuilding_" + str(side) + "_" + str(index)

    # جسم المبنى الرئيسي
    _box(parent, building_name,
        Vector3(6.0, height, 7.0),
        Vector3(center_x, height / 2.0, z),
        facade_color, true)

    # حواف الأدوار لإظهار الخرسانة والبروزات
    for floor in range(1, floors):
        var floor_y: float = 3.0 + float(floor - 1) * 2.7

        _box(parent, "FloorBand",
            Vector3(0.16, 0.12, 6.15),
            Vector3(facade_x, floor_y, z),
            Color(0.82, 0.77, 0.67), false)

        # شباكان في كل دور
        for window_index in range(2):
            var window_z: float = z + (float(window_index) - 0.5) * 2.8
            var window_y: float = floor_y + 1.05

            _make_window(
                parent, facade_x, window_y,
                window_z, side, index, floor
            )

            # بلكونة أمام بعض الشبابيك
            if (window_index + floor + index) % 2 == 0:
                _make_balcony(
                    parent, facade_x, floor_y,
                    window_z, side, index
                )

            # وحدة تكييف أسفل بعض الشبابيك
            if (window_index + index) % 3 == 0:
                _box(parent, "AirConditioner",
                    Vector3(0.34, 0.34, 0.65),
                    Vector3(
                        facade_x - float(side) * 0.14,
                        window_y - 0.92,
                        window_z
                    ),
                    Color(0.79, 0.81, 0.78), false)

    if is_village:
        _make_village_gate(parent, facade_x, z, side, index)
    else:
        _make_shop(parent, facade_x, z, side, index)

    # تفاصيل السطح
    _make_roof(parent, center_x, height, z, index)

func _make_window(
    parent: Node3D,
    facade_x: float,
    y: float,
    z: float,
    side: int,
    index: int,
    floor: int
) -> void:
    var outward: float = -float(side)

    # إطار النافذة
    _box(parent, "WindowFrame",
        Vector3(0.13, 1.42, 1.12),
        Vector3(facade_x, y, z),
        Color(0.88, 0.83, 0.72), false)

    # الزجاج الداكن
    _box(parent, "WindowGlass",
        Vector3(0.06, 1.20, 0.90),
        Vector3(facade_x + outward * 0.08, y, z),
        Color(0.16, 0.28, 0.34), false)

    # فاصل معدني رأسي
    _box(parent, "WindowDivider",
        Vector3(0.07, 1.18, 0.055),
        Vector3(facade_x + outward * 0.13, y, z),
        Color(0.67, 0.68, 0.64), false)

    # فاصل أفقي
    _box(parent, "WindowCrossbar",
        Vector3(0.07, 0.055, 0.90),
        Vector3(facade_x + outward * 0.13, y, z),
        Color(0.67, 0.68, 0.64), false)

func _make_balcony(
    parent: Node3D,
    facade_x: float,
    floor_y: float,
    z: float,
    side: int,
    index: int
) -> void:
    var outward: float = -float(side)
    var balcony_x: float = facade_x + outward * 0.38

    # أرضية البلكونة
    _box(parent, "BalconyFloor",
        Vector3(0.72, 0.13, 1.65),
        Vector3(balcony_x, floor_y + 0.05, z),
        Color(0.76, 0.71, 0.62), false)

    # السور الأمامي
    _box(parent, "BalconyRailTop",
        Vector3(0.08, 0.09, 1.65),
        Vector3(
            facade_x + outward * 0.76,
            floor_y + 0.77,
            z
        ),
        Color(0.24, 0.26, 0.26), false)

    # جوانب السور
    for bar_index in range(7):
        var bar_z: float = z - 0.70 + float(bar_index) * 0.23

        _box(parent, "BalconyBar",
            Vector3(0.07, 0.70, 0.045),
            Vector3(
                facade_x + outward * 0.76,
                floor_y + 0.42,
                bar_z
            ),
            Color(0.30, 0.31, 0.30), false)

    # قطعة غسيل ملونة في بعض البلكونات
    if index % 2 == 0:
        var cloth_color: Color = Color(0.73, 0.23, 0.18)

        if index % 4 == 0:
            cloth_color = Color(0.20, 0.38, 0.68)

        _box(parent, "HangingLaundry",
            Vector3(0.04, 0.40, 0.52),
            Vector3(
                facade_x + outward * 0.61,
                floor_y + 0.93,
                z + 0.20
            ),
            cloth_color, false)

func _make_shop(
    parent: Node3D,
    facade_x: float,
    z: float,
    side: int,
    index: int
) -> void:
    var outward: float = -float(side)

    # باب محل معدني
    _box(parent, "ShopShutter",
        Vector3(0.13, 2.15, 1.75),
        Vector3(facade_x, 1.15, z),
        Color(0.34, 0.36, 0.35), false)

    # خطوط باب المحل
    for line_index in range(7):
        _box(parent, "ShutterLine",
            Vector3(0.04, 0.035, 1.65),
            Vector3(
                facade_x + outward * 0.09,
                0.35 + float(line_index) * 0.25,
                z
            ),
            Color(0.58, 0.59, 0.56), false)

    # شريط أعلى المحل
    _box(parent, "ShopSign",
        Vector3(0.16, 0.52, 2.25),
        Vector3(facade_x + outward * 0.05, 2.58, z),
        Color(0.12, 0.36, 0.30), false)

    var shop_names: Array[String] = [
        "بقالة", "حلاق", "مخبز",
        "ملابس", "موبايلات", "كشري"
    ]

    var sign := Label3D.new()
    sign.name = "ArabicShopSign"
    sign.text = shop_names[index % shop_names.size()]
    sign.font_size = 32
    sign.pixel_size = 0.008
    sign.modulate = Color(1.0, 0.88, 0.52)
    sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    sign.position = Vector3(
        facade_x + outward * 0.15,
        2.58,
        z
    )
    sign.rotation.y = -float(side) * PI / 2.0
    parent.add_child(sign)

func _make_village_gate(
    parent: Node3D,
    facade_x: float,
    z: float,
    side: int,
    index: int
) -> void:
    var outward: float = -float(side)

    # بوابة منزل ريفي
    _box(parent, "VillageGateFrame",
        Vector3(0.18, 2.35, 2.0),
        Vector3(facade_x, 1.20, z),
        Color(0.75, 0.66, 0.52), false)

    _box(parent, "VillageGateDoor",
        Vector3(0.10, 2.05, 1.65),
        Vector3(facade_x + outward * 0.11, 1.12, z),
        Color(0.28, 0.22, 0.16), false)

    # نافذة صغيرة بجانب البوابة
    _box(parent, "VillageWindow",
        Vector3(0.12, 0.85, 0.90),
        Vector3(facade_x, 1.95, z + 2.1),
        Color(0.18, 0.28, 0.31), false)

    # درجات أمام المنزل
    _box(parent, "VillageStep",
        Vector3(0.65, 0.12, 2.15),
        Vector3(facade_x + outward * 0.30, 0.12, z),
        Color(0.66, 0.60, 0.50), false)

func _make_roof(
    parent: Node3D,
    center_x: float,
    height: float,
    z: float,
    index: int
) -> void:
    # حافة السطح
    _box(parent, "RoofParapet",
        Vector3(5.9, 0.35, 6.9),
        Vector3(center_x, height + 0.12, z),
        Color(0.68, 0.62, 0.52), false)

    # خزان مياه فوق السطح
    _box(parent, "WaterTank",
        Vector3(1.0, 1.15, 1.0),
        Vector3(center_x + 1.4, height + 0.85, z + 1.3),
        Color(0.32, 0.38, 0.39), false)

    # قاعدة الخزان
    _box(parent, "TankBase",
        Vector3(1.2, 0.16, 1.2),
        Vector3(center_x + 1.4, height + 0.25, z + 1.3),
        Color(0.55, 0.53, 0.47), false)

    # عمود هوائي على بعض الأسطح
    if index % 2 == 0:
        _box(parent, "RoofAntenna",
            Vector3(0.055, 1.6, 0.055),
            Vector3(center_x - 1.5, height + 0.95, z - 1.5),
            Color(0.38, 0.39, 0.37), false)

func _box(
    parent: Node3D,
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
    material.metallic = 0.05
    mesh_instance.material_override = material

    holder.add_child(mesh_instance)
    parent.add_child(holder)