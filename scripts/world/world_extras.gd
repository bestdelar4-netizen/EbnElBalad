
extends Node3D

## إضافات العالم: الأشجار والخريطة المصغرة

var player: Node3D
var map_camera: Camera3D
var map_viewport: SubViewport
var map_panel: PanelContainer
var map_texture: TextureRect
var area_label: Label
var expanded := false
var map_button: Button


func _ready() -> void:
    name = "WorldExtras"
    create_trees()


func set_player(target: Node3D) -> void:
    player = target


func create_trees() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261015

    # أشجار على امتداد الشوارع الرئيسية
    var road_positions: Array[float] = [
        -120.0, -60.0, 0.0, 60.0, 120.0
    ]

    for road_x in road_positions:
        for side in [-1.0, 1.0]:
            var z := -235.0

            while z <= 235.0:
                # ترك مساحة عند تقاطعات الطرق
                var nearest_crossing := absf(
                    z - roundf(z / 60.0) * 60.0
                )

                if nearest_crossing > 13.0:
                    var tree_x: float = float(road_x) + float(side) * 22.0
                    var tree_z: float = float(z) + rng.randf_range(-2.0, 2.0)
                    create_tree(Vector3(tree_x, 0.0, tree_z), rng)

                z += 22.0


func create_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
    var tree := Node3D.new()
    tree.position = pos
    add_child(tree)

    var trunk_height := rng.randf_range(2.0, 3.2)
    var crown_size := rng.randf_range(1.4, 2.1)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.3
    trunk_mesh.height = trunk_height
    trunk.mesh = trunk_mesh
    trunk.position.y = trunk_height / 2.0

    var bark := StandardMaterial3D.new()
    bark.albedo_color = Color(0.30, 0.16, 0.08)
    trunk.material_override = bark
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = crown_size
    crown_mesh.height = crown_size * 2.0
    crown.mesh = crown_mesh
    crown.position.y = trunk_height + crown_size * 0.55
    crown.scale = Vector3(1.0, 1.15, 1.0)

    var leaves := StandardMaterial3D.new()
    leaves.albedo_color = Color(
        rng.randf_range(0.08, 0.18),
        rng.randf_range(0.32, 0.48),
        rng.randf_range(0.08, 0.16)
    )
    crown.material_override = leaves
    tree.add_child(crown)


func create_minimap() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MinimapLayer"
    layer.layer = 10
    add_child(layer)

    var screen := Control.new()
    screen.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    screen.mouse_filter = Control.MOUSE_FILTER_PASS
    layer.add_child(screen)

    map_panel = PanelContainer.new()
    map_panel.name = "MinimapPanel"
    map_panel.anchor_left = 1.0
    map_panel.anchor_right = 1.0
    map_panel.anchor_top = 0.0
    map_panel.anchor_bottom = 0.0
    map_panel.offset_left = -220.0
    map_panel.offset_right = -12.0
    map_panel.offset_top = 12.0
    map_panel.offset_bottom = 250.0
    screen.add_child(map_panel)

    var content := VBoxContainer.new()
    map_panel.add_child(content)

    var title := Label.new()
    title.text = "خريطة المدينة"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(title)

    map_viewport = SubViewport.new()
    map_viewport.size = Vector2i(256, 256)
    map_viewport.own_world_3d = false
    map_viewport.transparent_bg = false
    map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    content.add_child(map_viewport)

    # تستخدم الخريطة عالم اللعبة نفسه حتى تظهر الشوارع والمباني بدل أرضية فارغة.
    map_camera = Camera3D.new()
    map_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    map_camera.size = 180.0
    map_camera.position = Vector3(0.0, 100.0, 0.0)
    map_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
    map_viewport.add_child(map_camera)
    map_camera.current = true

    map_texture = TextureRect.new()
    map_texture.texture = map_viewport.get_texture()
    map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map_texture.stretch_mode = TextureRect.STRETCH_SCALE
    map_texture.custom_minimum_size = Vector2(190.0, 170.0)
    content.add_child(map_texture)

    # الضغط على الخريطة يكبّرها أو يعيدها لحجمها
    map_button = Button.new()
    map_button.text = "تكبير / تصغير الخريطة"
    map_button.pressed.connect(toggle_map)
    content.add_child(map_button)

    area_label = Label.new()
    area_label.text = "المنطقة: جارٍ تحديد الموقع..."
    area_label.autowrap_mode = TextServer.AUTOWRAP_WORD
    content.add_child(area_label)


func toggle_map() -> void:
    expanded = not expanded

    if expanded:
        map_panel.offset_left = -390.0
        map_panel.offset_right = -12.0
        map_panel.offset_bottom = 440.0
        map_camera.size = 320.0
        map_texture.custom_minimum_size = Vector2(350.0, 350.0)
        map_button.text = "تصغير الخريطة"
    else:
        map_panel.offset_left = -220.0
        map_panel.offset_right = -12.0
        map_panel.offset_bottom = 250.0
        map_camera.size = 120.0
        map_texture.custom_minimum_size = Vector2(190.0, 170.0)
        map_button.text = "تكبير الخريطة"


func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        return

    map_camera.global_position = Vector3(
        player.global_position.x,
        100.0,
        player.global_position.z
    )

    var x := int(floor(player.global_position.x / 120.0))
    var z := int(floor(player.global_position.z / 120.0))

    area_label.text = (
        "المنطقة: قطاع %d - %d\nالموقع: X %.0f | Z %.0f"
        % [
            x,
            z,
            player.global_position.x,
            player.global_position.z
        ]
    )
