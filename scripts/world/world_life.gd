
extends Node3D

var player: Node3D = null

var cars: Array[Node3D] = []
var npcs: Array[Node3D] = []
var mission_markers: Array[MeshInstance3D] = []

var mission_index: int = 0
var money: int = 250

var hud_label: Label
var status_label: Label

var mission_positions: Array[Vector3] = [
    Vector3(15.0, 0.0, 20.0),
    Vector3(-75.0, 0.0, 100.0),
    Vector3(75.0, 0.0, -120.0)
]

var mission_names: Array[String] = [
    "توصيل طلب للحديقة",
    "توصيل طلب للحي الغربي",
    "توصيل طلب للشارع الرئيسي"
]

var mission_rewards: Array[int] = [100, 150, 200]


const SAVE_PATH: String = "user://ebnelbalad_save.cfg"

func _ready() -> void:
    name = "WorldLife"
    load_game()
    create_cars()
    create_npcs()
    create_mission_markers()
    create_hud()
    update_hud()


func set_player(target: Node3D) -> void:
    player = target
    if is_instance_valid(player):
        var config := ConfigFile.new()
        if config.load(SAVE_PATH) == OK:
            var saved_position: Vector3 = config.get_value(
                "player",
                "position",
                Vector3(0.0, 0.2, 5.0)
            )

            # لا تستعد موقع حفظ خارج منطقة المدينة؛ قد يترك اللاعب بعيدًا
            # عن المباني والطرق التي يتم إنشاؤها حول نقطة البداية.
            var saved_position_is_valid: bool = (
                absf(saved_position.x) <= 300.0
                and absf(saved_position.z) <= 420.0
                and saved_position.y >= -2.0
                and saved_position.y <= 80.0
            )

            if saved_position_is_valid:
                player.global_position = saved_position
            else:
                player.global_position = Vector3(0.0, 0.2, 5.0)
                player.velocity = Vector3.ZERO
                push_warning(
                    "موقع الحفظ كان خارج المدينة؛ تمت إعادة اللاعب إلى شارع البداية."
                )
    update_hud()


func load_game() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return
    money = int(config.get_value("progress", "money", 250))
    mission_index = clampi(int(config.get_value("progress", "mission_index", 0)), 0, mission_positions.size())


func save_game() -> void:
    var config := ConfigFile.new()
    config.set_value("progress", "money", money)
    config.set_value("progress", "mission_index", mission_index)
    if is_instance_valid(player):
        config.set_value("player", "position", player.global_position)
    var error: Error = config.save(SAVE_PATH)
    if error != OK:
        push_warning("تعذر حفظ التقدم: %s" % error)


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_game()


func create_cars() -> void:
    var road_positions: Array[float] = [-120.0, -60.0, 0.0, 60.0, 120.0]
    var car_colors: Array[Color] = [
        Color(0.75, 0.12, 0.08),
        Color(0.12, 0.28, 0.72),
        Color(0.86, 0.82, 0.66),
        Color(0.15, 0.15, 0.17),
        Color(0.12, 0.48, 0.25)
    ]

    for i in range(road_positions.size()):
        var car: Node3D = Node3D.new()
        car.name = "CityCar_%d" % i
        car.position = Vector3(
            road_positions[i],
            0.0,
            -190.0 + float(i) * 75.0
        )
        car.set_meta("direction", 1.0 if i % 2 == 0 else -1.0)
        car.set_meta("hit_cooldown", 0.0)
        add_child(car)

        var body_color: Color = car_colors[i % car_colors.size()]

        _add_part(
            car, "CarBody",
            Vector3(0.0, 0.65, 0.0),
            Vector3(1.8, 0.65, 3.6),
            body_color
        )

        _add_part(
            car, "CarRoof",
            Vector3(0.0, 1.15, 0.15),
            Vector3(1.4, 0.55, 1.8),
            Color(0.25, 0.32, 0.36)
        )

        _add_part(
            car, "FrontWindow",
            Vector3(0.0, 1.23, -0.48),
            Vector3(1.22, 0.32, 0.08),
            Color(0.12, 0.22, 0.29)
        )

        _add_part(
            car, "RearWindow",
            Vector3(0.0, 1.23, 0.78),
            Vector3(1.22, 0.32, 0.08),
            Color(0.12, 0.22, 0.29)
        )

        for side in [-1.0, 1.0]:
            for end_z in [-1.05, 1.05]:
                var wheel: MeshInstance3D = MeshInstance3D.new()
                wheel.name = "Wheel"
                var wheel_mesh: CylinderMesh = CylinderMesh.new()
                wheel_mesh.top_radius = 0.32
                wheel_mesh.bottom_radius = 0.32
                wheel_mesh.height = 0.2
                wheel.mesh = wheel_mesh
                wheel.position = Vector3(
                    float(side) * 0.92,
                    0.34,
                    end_z
                )
                wheel.rotation_degrees.z = 90.0

                var wheel_material: StandardMaterial3D = StandardMaterial3D.new()
                wheel_material.albedo_color = Color(0.08, 0.08, 0.08)
                wheel.material_override = wheel_material
                car.add_child(wheel)

        _add_part(
            car, "FrontBumper",
            Vector3(0.0, 0.42, -1.82),
            Vector3(1.75, 0.18, 0.12),
            Color(0.72, 0.72, 0.68)
        )

        _add_part(
            car, "RearBumper",
            Vector3(0.0, 0.42, 1.82),
            Vector3(1.75, 0.18, 0.12),
            Color(0.5, 0.5, 0.5)
        )

        cars.append(car)


func create_npcs() -> void:
    var positions: Array[Vector3] = [
        Vector3(10.0, 0.0, -20.0),
        Vector3(-70.0, 0.0, 45.0),
        Vector3(70.0, 0.0, 75.0),
        Vector3(10.0, 0.0, 140.0),
        Vector3(-10.0, 0.0, -150.0),
        Vector3(130.0, 0.0, 30.0)
    ]

    var clothes: Array[Color] = [
        Color(0.18, 0.35, 0.72),
        Color(0.68, 0.22, 0.16),
        Color(0.22, 0.48, 0.25),
        Color(0.72, 0.58, 0.31),
        Color(0.42, 0.28, 0.55),
        Color(0.35, 0.35, 0.35)
    ]

    for i in range(positions.size()):
        var npc: Node3D = Node3D.new()
        npc.name = "Resident_%d" % i
        npc.position = positions[i]
        npc.set_meta("direction", 1.0 if i % 2 == 0 else -1.0)
        npc.set_meta("start_x", positions[i].x)
        npc.set_meta("min_x", positions[i].x - 4.0)
        npc.set_meta("max_x", positions[i].x + 4.0)
        npc.set_meta("knocked_timer", 0.0)
        npc.set_meta("hit_cooldown", 0.0)
        npc.set_meta("stand_rotation", npc.rotation.z)
        add_child(npc)

        _add_capsule(
            npc,
            "Body",
            Vector3(0.0, 0.85, 0.0),
            0.32,
            1.1,
            clothes[i % clothes.size()]
        )

        _add_sphere(
            npc,
            "Head",
            Vector3(0.0, 1.65, 0.0),
            0.24,
            Color(0.68, 0.48, 0.34)
        )

        _add_part(
            npc, "Hair",
            Vector3(0.0, 1.84, 0.0),
            Vector3(0.35, 0.12, 0.35),
            Color(0.12, 0.09, 0.07)
        )

        npcs.append(npc)


func create_mission_markers() -> void:
    for i in range(mission_positions.size()):
        var marker: MeshInstance3D = MeshInstance3D.new()
        marker.name = "MissionMarker_%d" % i

        var mesh: SphereMesh = SphereMesh.new()
        mesh.radius = 1.0
        mesh.height = 2.0
        marker.mesh = mesh
        marker.position = mission_positions[i] + Vector3(0.0, 1.5, 0.0)

        var material: StandardMaterial3D = StandardMaterial3D.new()
        material.albedo_color = Color(1.0, 0.75, 0.05)
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.emission_enabled = true
        material.emission = Color(1.0, 0.55, 0.02)
        marker.material_override = material

        add_child(marker)
        mission_markers.append(marker)

    update_mission_markers()


func create_hud() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "LifeHUD"
    layer.layer = 8
    add_child(layer)

    var panel: PanelContainer = PanelContainer.new()
    panel.name = "InfoPanel"
    panel.position = Vector2(12.0, 12.0)
    panel.custom_minimum_size = Vector2(255.0, 100.0)
    layer.add_child(panel)

    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 4)
    panel.add_child(column)

    hud_label = Label.new()
    hud_label.name = "MoneyAndMission"
    hud_label.add_theme_font_size_override("font_size", 17)
    hud_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.68))
    hud_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05))
    hud_label.add_theme_constant_override("outline_size", 3)
    hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(hud_label)

    status_label = Label.new()
    status_label.name = "StatusMessage"
    status_label.text = "أهلاً بيك في ابن البلد!"
    status_label.add_theme_font_size_override("font_size", 15)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(status_label)


func handle_interaction() -> void:
    if not is_instance_valid(player):
        return

    if mission_index < mission_positions.size():
        var target: Vector3 = mission_positions[mission_index]
        var distance: float = _flat_distance(player.global_position, target)

        if distance <= 8.0:
            var reward: int = mission_rewards[mission_index]
            money += reward

            status_label.text = "أحسنت! استلمت مكافأة %d جنيه." % reward
            mission_index += 1
            save_game()

            update_mission_markers()
            update_hud()
            return

    # التفاعل مع السكان القريبين
    var closest_npc_distance: float = 999999.0

    for npc in npcs:
        var distance: float = _flat_distance(
            player.global_position,
            npc.global_position
        )
        closest_npc_distance = minf(closest_npc_distance, distance)

    if closest_npc_distance <= 3.5:
        status_label.text = "أهلاً يا معلم! شوف علامة المهمة الصفراء."
        return

    status_label.text = "قرّب من علامة المهمة الصفراء واضغط زر التفاعل."


func _process(delta: float) -> void:
    for car in cars:
        if not is_instance_valid(car):
            continue
        var direction: float = float(car.get_meta("direction", 1.0))
        var cooldown: float = maxf(0.0, float(car.get_meta("hit_cooldown", 0.0)) - delta)
        car.set_meta("hit_cooldown", cooldown)
        var knocked_timer: float = maxf(0.0, float(car.get_meta("knocked_timer", 0.0)) - delta)
        car.set_meta("knocked_timer", knocked_timer)

        if knocked_timer <= 0.0:
            car.position.z += direction * 7.0 * delta
            car.rotation.z = lerpf(car.rotation.z, 0.0, minf(1.0, delta * 3.0))

        if car.position.z > 245.0:
            car.position.z = -245.0
        elif car.position.z < -245.0:
            car.position.z = 245.0

        if is_instance_valid(player) and cooldown <= 0.0:
            var player_distance: float = Vector2(
                car.global_position.x - player.global_position.x,
                car.global_position.z - player.global_position.z
            ).length()
            if player_distance < 2.15:
                var away: Vector3 = car.global_position - player.global_position
                away.y = 0.0
                if away.length_squared() < 0.01:
                    away = Vector3(1.0, 0.0, 0.0)
                away = away.normalized()
                car.set_meta("direction", -direction)
                car.set_meta("hit_cooldown", 1.0)
                car.set_meta("knocked_timer", 0.45)
                car.rotation.z = 0.12 if away.x >= 0.0 else -0.12
                car.position += away * 1.8
                if player is CharacterBody3D:
                    var player_body: CharacterBody3D = player as CharacterBody3D
                    player_body.velocity.x -= away.x * 3.0
                    player_body.velocity.z -= away.z * 3.0

    for npc in npcs:
        if not is_instance_valid(npc):
            continue
        var cooldown: float = maxf(0.0, float(npc.get_meta("hit_cooldown", 0.0)) - delta)
        npc.set_meta("hit_cooldown", cooldown)
        var knocked_timer: float = maxf(0.0, float(npc.get_meta("knocked_timer", 0.0)) - delta)
        npc.set_meta("knocked_timer", knocked_timer)

        if knocked_timer > 0.0:
            continue

        var direction: float = float(npc.get_meta("direction", 1.0))
        var min_x: float = float(npc.get_meta("min_x", npc.position.x - 4.0))
        var max_x: float = float(npc.get_meta("max_x", npc.position.x + 4.0))
        npc.position.x += direction * 1.0 * delta

        if npc.position.x >= max_x:
            npc.position.x = max_x
            npc.set_meta("direction", -1.0)
        elif npc.position.x <= min_x:
            npc.position.x = min_x
            npc.set_meta("direction", 1.0)

        if is_instance_valid(player) and cooldown <= 0.0:
            var hit_distance: float = Vector2(
                npc.global_position.x - player.global_position.x,
                npc.global_position.z - player.global_position.z
            ).length()
            if hit_distance < 1.35:
                var push: Vector3 = npc.global_position - player.global_position
                push.y = 0.0
                if push.length_squared() < 0.01:
                    push = Vector3(1.0, 0.0, 0.0)
                push = push.normalized()
                npc.set_meta("hit_cooldown", 1.6)
                npc.set_meta("knocked_timer", 1.25)
                npc.set_meta("direction", -direction)
                npc.position += push * 2.4
                npc.rotation.z = 1.15 if push.x >= 0.0 else -1.15
                npc.rotation.y += 0.35

        if float(npc.get_meta("knocked_timer", 0.0)) <= 0.0:
            npc.rotation.z = lerpf(npc.rotation.z, 0.0, minf(1.0, delta * 2.5))


func update_mission_markers() -> void:
    for i in range(mission_markers.size()):
        mission_markers[i].visible = i == mission_index


func update_hud() -> void:
    if not is_instance_valid(hud_label):
        return

    var current_mission: String = "انتهت كل المهام!"

    if mission_index < mission_names.size():
        current_mission = mission_names[mission_index]

    hud_label.text = "💰 رصيدك: %d جنيه\n📦 المهمة: %s" % [
        money,
        current_mission
    ]


func _flat_distance(a: Vector3, b: Vector3) -> float:
    var a2: Vector2 = Vector2(a.x, a.z)
    var b2: Vector2 = Vector2(b.x, b.z)
    return a2.distance_to(b2)


func _add_part(
    parent: Node3D,
    part_name: String,
    local_pos: Vector3,
    dimensions: Vector3,
    color: Color
) -> MeshInstance3D:
    var part: MeshInstance3D = MeshInstance3D.new()
    part.name = part_name

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = dimensions
    part.mesh = mesh
    part.position = local_pos

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    part.material_override = material

    parent.add_child(part)
    return part


func _add_sphere(
    parent: Node3D,
    part_name: String,
    local_pos: Vector3,
    radius: float,
    color: Color
) -> MeshInstance3D:
    var part: MeshInstance3D = MeshInstance3D.new()
    part.name = part_name

    var mesh: SphereMesh = SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    part.mesh = mesh
    part.position = local_pos

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    part.material_override = material

    parent.add_child(part)
    return part


func _add_capsule(
    parent: Node3D,
    part_name: String,
    local_pos: Vector3,
    radius: float,
    height: float,
    color: Color
) -> MeshInstance3D:
    var part: MeshInstance3D = MeshInstance3D.new()
    part.name = part_name

    var mesh: CapsuleMesh = CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    part.mesh = mesh
    part.position = local_pos

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    part.material_override = material

    parent.add_child(part)
    return part
