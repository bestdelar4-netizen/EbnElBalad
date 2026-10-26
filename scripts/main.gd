
extends Node3D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const WORLD_MANAGER_SCRIPT = preload("res://scripts/world/world_manager.gd")
const WORLD_EXTRAS_SCRIPT = preload("res://scripts/world/world_extras.gd")
const WORLD_LIFE_SCRIPT = preload("res://scripts/world/world_life.gd")
const EGYPT_REGIONS_SCRIPT = preload("res://scripts/world/egypt_regions.gd")
const EGYPT_REGION_BUILDER_SCRIPT = preload("res://scripts/world/egypt_region_builder.gd")

var player_reference: Node3D
var world_manager: Node3D
var world_extras: Node3D
var world_life: Node3D
var region_builder: Node3D


func _ready() -> void:
	# ارسم مشهد اختبار مرئي أولًا، قبل أي أنظمة إضافية قد تتعطل.
	create_emergency_visible_world()
	create_environment()
	create_world_manager()
	create_world()
	create_egyptian_village()
	create_egyptian_landmarks()
	create_mobile_controls()
	create_player()
	create_world_extras()
	create_world_life()
	create_starter_neighborhood()


func create_emergency_visible_world() -> void:
	# أرض كبيرة بلون واضح حول نقطة البداية.
	make_box("EmergencyGround", Vector3(0.0, -0.65, -8.0), Vector3(90.0, 0.3, 120.0), Color("#b9a47d"), false)
	# طريق واضح تحت اللاعب وأمامه.
	make_box("EmergencyRoad", Vector3(0.0, -0.42, -10.0), Vector3(12.0, 0.12, 100.0), Color("#333438"), false)
	for z in range(-48, 36, 8):
		make_box("EmergencyRoadStripe", Vector3(0.0, -0.345, float(z)), Vector3(0.22, 0.025, 3.0), Color("#f7e7b5"), false)
	# مبانٍ ضخمة قريبة في الاتجاهين، وواجهة مباشرة أمام اللاعب.
	make_box("EmergencyBuildingLeft", Vector3(-11.0, 4.0, -12.0), Vector3(9.0, 8.0, 8.0), Color("#dfc9a4"), false)
	make_box("EmergencyBuildingRight", Vector3(11.0, 5.0, -18.0), Vector3(9.0, 10.0, 8.0), Color("#c9b18d"), false)
	make_box("EmergencyBuildingFar", Vector3(0.0, 5.0, -32.0), Vector3(18.0, 10.0, 5.0), Color("#e5d6b9"), false)
	make_box("EmergencyShopSign", Vector3(0.0, 4.0, -29.35), Vector3(8.0, 0.8, 0.15), Color("#17613d"), false)
	create_shop_sign_text("شارع ابن البلد", Vector3(0.0, 4.0, -29.2))
	# تأكد من وجود كاميرا فعالة حتى لو كانت الكاميرا الأصلية غير محددة.
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		var emergency_camera := Camera3D.new()
		emergency_camera.name = "EmergencyCamera"
		emergency_camera.position = Vector3(0.0, 5.0, 14.0)
		emergency_camera.rotation_degrees = Vector3(-10.0, 0.0, 0.0)
		emergency_camera.current = true
		add_child(emergency_camera)



# --------------------------------------------------
# معالم مصر: أهرامات الجيزة وبرج القاهرة ومآذن
# --------------------------------------------------

func create_egyptian_landmarks() -> void:
	# هضبة رملية واسعة غرب المدينة
	make_box(
		"GizaDesert",
		Vector3(265.0, -0.12, -70.0),
		Vector3(210.0, 0.18, 280.0),
		Color("#c8a66e"),
		true
	)

	# الأهرامات الثلاثة مع قاعدة حجرية وتفاصيل صفوف الأحجار
	create_pyramid(Vector3(250.0, 0.0, -80.0), 48.0, 42.0, Color("#d7bd8b"))
	create_pyramid(Vector3(306.0, 0.0, -58.0), 36.0, 32.0, Color("#cbb080"))
	create_pyramid(Vector3(208.0, 0.0, -35.0), 27.0, 25.0, Color("#e0c99b"))

	# طريق صحراوي يقود ناحية منطقة الأهرامات
	make_box(
		"DesertAccessRoad",
		Vector3(180.0, 0.015, -15.0),
		Vector3(7.0, 0.08, 120.0),
		Color("#766b5a"),
		true
	)

	# برج القاهرة بشكل أسطواني متدرج مع قرص علوي
	create_cairo_tower(Vector3(-178.0, 0.0, 75.0))

	# مآذن مسجد في الحي؛ مع قاعدة وشرفة وقمة مدببة
	create_minaret(Vector3(-160.0, 0.0, -65.0))
	create_minaret(Vector3(-151.0, 0.0, -65.0))


func create_pyramid(pos: Vector3, base_size: float, pyramid_height: float, stone_color: Color) -> void:
	var pyramid := MeshInstance3D.new()
	pyramid.name = "GizaPyramid"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = base_size * 0.5
	var a := Vector3(-half, 0.0, -half)
	var b := Vector3(half, 0.0, -half)
	var c := Vector3(half, 0.0, half)
	var d := Vector3(-half, 0.0, half)
	var apex := Vector3(0.0, pyramid_height, 0.0)

	# كل وجه مثلث مستقل حتى تظهر أوجه الهرم بوضوح
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(apex)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(apex)
	surface.add_vertex(c)
	surface.add_vertex(d)
	surface.add_vertex(apex)
	surface.add_vertex(d)
	surface.add_vertex(a)
	surface.add_vertex(apex)
	# قاعدة الهرم
	surface.add_vertex(a)
	surface.add_vertex(d)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)

	surface.generate_normals()
	pyramid.mesh = surface.commit()
	pyramid.position = pos

	var stone := StandardMaterial3D.new()
	stone.albedo_color = stone_color
	stone.roughness = 1.0
	stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	pyramid.material_override = stone
	add_child(pyramid)

	# خطوط حجرية خفيفة على الواجهات لإظهار طبقات البناء من بعيد
	for row in range(1, 7):
		var y: float = float(row) * pyramid_height / 7.0
		var width_at_row: float = base_size * (1.0 - y / pyramid_height)
		if width_at_row > 1.5:
			make_box(
				"PyramidStoneCourse",
				pos + Vector3(0.0, y, -half * (1.0 - y / pyramid_height)),
				Vector3(width_at_row, 0.12, 0.22),
				stone_color.darkened(0.08),
				false
			)


func create_cairo_tower(pos: Vector3) -> void:
	var tower := Node3D.new()
	tower.name = "CairoTower"
	tower.position = pos
	add_child(tower)

	var base := MeshInstance3D.new()
	base.name = "TowerBase"
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 4.0
	base_mesh.bottom_radius = 5.5
	base_mesh.height = 5.0
	base.mesh = base_mesh
	base.position.y = 2.5
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color("#b9a98b")
	concrete.roughness = 0.8
	base.material_override = concrete
	tower.add_child(base)

	var shaft := MeshInstance3D.new()
	shaft.name = "LatticeTowerShaft"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 2.2
	shaft_mesh.bottom_radius = 4.0
	shaft_mesh.height = 32.0
	shaft.mesh = shaft_mesh
	shaft.position.y = 21.0
	shaft.material_override = concrete
	tower.add_child(shaft)

	var viewing_deck := MeshInstance3D.new()
	viewing_deck.name = "ViewingDeck"
	var deck_mesh := CylinderMesh.new()
	deck_mesh.top_radius = 4.8
	deck_mesh.bottom_radius = 4.8
	deck_mesh.height = 2.0
	viewing_deck.mesh = deck_mesh
	viewing_deck.position.y = 37.0
	viewing_deck.material_override = concrete
	tower.add_child(viewing_deck)

	var crown := MeshInstance3D.new()
	crown.name = "TowerCrown"
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 1.1
	crown_mesh.bottom_radius = 2.4
	crown_mesh.height = 6.0
	crown.mesh = crown_mesh
	crown.position.y = 41.0
	crown.material_override = concrete
	tower.add_child(crown)


func create_minaret(pos: Vector3) -> void:
	var minaret := Node3D.new()
	minaret.name = "MosqueMinaret"
	minaret.position = pos
	add_child(minaret)

	var plaster := StandardMaterial3D.new()
	plaster.albedo_color = Color("#e0d3b7")
	plaster.roughness = 0.9

	var shaft := MeshInstance3D.new()
	shaft.name = "MinaretShaft"
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.65
	shaft_mesh.bottom_radius = 1.0
	shaft_mesh.height = 12.0
	shaft.mesh = shaft_mesh
	shaft.position.y = 6.0
	shaft.material_override = plaster
	minaret.add_child(shaft)

	var balcony := MeshInstance3D.new()
	balcony.name = "MinaretBalcony"
	var balcony_mesh := CylinderMesh.new()
	balcony_mesh.top_radius = 1.35
	balcony_mesh.bottom_radius = 1.35
	balcony_mesh.height = 0.35
	balcony.mesh = balcony_mesh
	balcony.position.y = 9.0
	balcony.material_override = plaster
	minaret.add_child(balcony)

	var cap := MeshInstance3D.new()
	cap.name = "MinaretTop"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.05
	cap_mesh.bottom_radius = 0.75
	cap_mesh.height = 2.0
	cap.mesh = cap_mesh
	cap.position.y = 13.0
	cap.material_override = plaster
	minaret.add_child(cap)


# --------------------------------------------------
# البيئة والإضاءة
# --------------------------------------------------

func create_environment() -> void:
	# إضاءة نهارية مصرية دافئة، مع تباين وظلال أوضح دون مؤثرات ثقيلة على الهاتف.
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	sun.light_color = Color("#fff0d7")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	add_child(sun)

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 6.0
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.05
	environment.fog_enabled = true
	environment.fog_light_color = Color("#d9c9a9")
	environment.fog_density = 0.0012
	environment.fog_sky_affect = 0.35

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#32649b")
	sky_material.sky_horizon_color = Color("#e4c9a0")
	sky_material.sky_curve = 0.18
	sky_material.ground_bottom_color = Color("#4c4638")
	sky_material.ground_horizon_color = Color("#b9a783")
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.12
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_128

	environment.sky = sky
	world_env.environment = environment
	add_child(world_env)


# --------------------------------------------------
# إنشاء العالم والمدينة
# --------------------------------------------------

func create_world_manager() -> void:
	world_manager = Node3D.new()
	world_manager.name = "WorldManager"
	world_manager.set_script(WORLD_MANAGER_SCRIPT)
	add_child(world_manager)


func create_world() -> void:
	# أنشئ أرضًا وشارعًا ومباني واضحة حول نقطة البداية أولًا.
	create_ground()
	create_roads()
	create_buildings()
	create_park()
	create_street_lights()
	create_spawn_street()



func create_spawn_street() -> void:
	# عناصر ضخمة وقريبة جدًا من الكاميرا لضمان ظهور الشارع والمباني من أول لحظة.
	make_box("SpawnStreetRoad", Vector3(0.0, 0.035, -3.0), Vector3(14.0, 0.12, 52.0), Color("#292a2b"), true)
	make_box("SpawnSidewalkLeft", Vector3(-10.0, 0.12, -3.0), Vector3(3.0, 0.24, 52.0), Color("#bdb5a5"), true)
	make_box("SpawnSidewalkRight", Vector3(10.0, 0.12, -3.0), Vector3(3.0, 0.24, 52.0), Color("#bdb5a5"), true)
	for z in range(-27, 22, 7):
		make_box("SpawnRoadMarking", Vector3(0.0, 0.105, float(z)), Vector3(0.22, 0.025, 2.8), Color("#f0dfaa"), false)

	# واجهات مبانٍ بمحاذاة مجال رؤية الكاميرا، على مسافة قصيرة من اللاعب.
	for side in [-1.0, 1.0]:
		for i in range(4):
			var z: float = -18.0 + float(i) * 12.0
			var x: float = side * 10.5
			var height: float = 9.0 + float(i % 3) * 2.0
			var wall_colors: Array[Color] = [Color("#d8c5a4"), Color("#c7b18e"), Color("#e0d3b8"), Color("#c4b8a1")]
			var wall_color: Color = wall_colors[i]
			make_box("SpawnStreetBuilding", Vector3(x, height * 0.5, z), Vector3(7.0, height, 9.0), wall_color, true)
			var front_x: float = x - side * 3.56
			make_box("SpawnStreetShopfront", Vector3(front_x, 1.3, z), Vector3(0.12, 2.4, 3.5), Color("#274754"), false)
			make_box("SpawnStreetShopAwning", Vector3(front_x - side * 0.16, 2.65, z), Vector3(0.55, 0.22, 4.2), [Color("#b84a36"), Color("#d5b34e"), Color("#28744a"), Color("#a8a49a")][i], false)
			make_box("SpawnStreetSign", Vector3(front_x - side * 0.02, 3.35, z), Vector3(0.14, 0.48, 3.6), Color("#185b3d"), false)
			for floor_y in range(4, int(height), 3):
				for window_side in [-1.0, 1.0]:
					make_box("SpawnStreetWindow", Vector3(front_x, float(floor_y), z + window_side * 2.25), Vector3(0.12, 1.1, 1.1), Color("#456b7c"), false)

	# أعمدة إنارة واضحة على جانبي الطريق.
	for side in [-1.0, 1.0]:
		make_box("SpawnLampPole", Vector3(side * 8.5, 2.6, -2.0), Vector3(0.16, 5.2, 0.16), Color("#41413d"), false)
		make_box("SpawnLampHead", Vector3(side * 8.5, 5.15, -2.0), Vector3(0.8, 0.2, 0.35), Color("#f0dca8"), false)

	# واجهة مبنى مركزية مباشرة أمام الكاميرا؛ لا تعتمد على رؤية جانبي الطريق.
	make_box("SpawnCentralVisibleBuilding", Vector3(0.0, 4.5, -17.0), Vector3(12.0, 9.0, 3.0), Color("#d9c39e"), true)
	make_box("SpawnCentralShopDoor", Vector3(-2.4, 1.25, -15.42), Vector3(1.5, 2.5, 0.12), Color("#543b2b"), false)
	make_box("SpawnCentralShopWindowLeft", Vector3(0.0, 2.0, -15.42), Vector3(1.7, 1.7, 0.12), Color("#315d70"), false)
	make_box("SpawnCentralShopWindowRight", Vector3(2.4, 2.0, -15.42), Vector3(1.7, 1.7, 0.12), Color("#315d70"), false)
	make_box("SpawnCentralShopSign", Vector3(0.0, 3.65, -15.4), Vector3(5.8, 0.65, 0.14), Color("#185b3d"), false)
	create_shop_sign_text("محلات ابن البلد", Vector3(0.0, 3.65, -15.25))
	# حاجز بصري بسيط في نهاية الشارع يوضح عمق المشهد حتى من دون تحريك اللاعب.
	make_box("SpawnFarBuilding", Vector3(0.0, 5.0, -34.0), Vector3(18.0, 10.0, 4.0), Color("#cbb99a"), true)

func create_ground() -> void:
	make_box(
		"CityGround",
		Vector3(0.0, -0.5, 0.0),
		Vector3(700.0, 1.0, 1100.0),
		Color(0.65, 0.57, 0.4),
		true
	)


func create_roads() -> void:
	for road_x in [-120.0, -60.0, 0.0, 60.0, 120.0]:
		make_box(
			"MainRoad",
			Vector3(road_x, 0.02, 0.0),
			Vector3(10.0, 0.12, 480.0),
			Color(0.16, 0.16, 0.17),
			true
		)

		for side in [-1.0, 1.0]:
			make_box(
				"Sidewalk",
				Vector3(road_x + side * 7.0, 0.08, 0.0),
				Vector3(3.5, 0.2, 480.0),
				Color(0.62, 0.6, 0.54),
				true
			)

		for z in range(-230, 231, 12):
			make_box(
				"RoadMarking",
				Vector3(road_x, 0.095, float(z)),
				Vector3(0.16, 0.02, 4.0),
				Color(0.95, 0.88, 0.62),
				false
			)

	for road_z in range(-240, 241, 60):
		make_box(
			"CrossRoad",
			Vector3(0.0, 0.025, float(road_z)),
			Vector3(300.0, 0.13, 9.0),
			Color(0.17, 0.17, 0.18),
			true
		)


func create_buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13579

	for road_x in [-120.0, -60.0, 0.0, 60.0, 120.0]:
		for side in [-1.0, 1.0]:
			for z in range(-220, 221, 24):
				var nearest_crossing := absf(
					float(z) - roundf(float(z) / 60.0) * 60.0
				)

				if nearest_crossing < 15.0:
					continue

				var height := rng.randf_range(7.0, 19.0)
				var width := rng.randf_range(7.0, 10.0)
				var depth := rng.randf_range(8.0, 12.0)

				var building_x: float = road_x + side * 15.0
				var building_z := float(z) + rng.randf_range(-2.0, 2.0)

				create_building(
					Vector3(building_x, 0.0, building_z),
					Vector3(width, height, depth),
					rng
				)


func create_building(
	pos: Vector3,
	dimensions: Vector3,
	rng: RandomNumberGenerator
) -> void:
	var height := dimensions.y

	var colors: Array[Color] = [
		Color(0.76, 0.65, 0.5),
		Color(0.83, 0.76, 0.63),
		Color(0.68, 0.62, 0.53),
		Color(0.78, 0.72, 0.64),
		Color(0.61, 0.57, 0.49)
	]

	var wall_color: Color = colors[
		rng.randi_range(0, colors.size() - 1)
	]

	make_box(
		"Building",
		pos + Vector3(0.0, height / 2.0, 0.0),
		dimensions,
		wall_color,
		true
	)

	make_box(
		"RoofEdge",
		pos + Vector3(0.0, height + 0.15, 0.0),
		Vector3(dimensions.x + 0.3, 0.3, dimensions.z + 0.3),
		Color(0.48, 0.43, 0.36),
		true
	)

	var front_x := pos.x - signf(pos.x) * (
		dimensions.x / 2.0 + 0.04
	)

	for floor_index in range(1, int(height / 3.0)):
		for window_index in range(2):
			var window_z := pos.z + (
				float(window_index) - 0.5
			) * 3.0

			make_box(
				"Window",
				Vector3(
					front_x,
					float(floor_index) * 3.0,
					window_z
				),
				Vector3(0.08, 1.25, 1.3),
				Color(0.18, 0.35, 0.48),
				false
			)

			make_box(
				"WindowFrame",
				Vector3(
					front_x - 0.05,
					float(floor_index) * 3.0,
					window_z
				),
				Vector3(0.08, 1.4, 1.45),
				Color(0.85, 0.79, 0.65),
				false
			)

	make_box(
		"Entrance",
		Vector3(front_x - 0.08, 1.1, pos.z),
		Vector3(0.12, 2.2, 1.4),
		Color(0.25, 0.18, 0.12),
		false
	)

	add_rooftop_detail(pos, height)

	if height > 10.0:
		make_box("BalconySlab", Vector3(front_x - 0.32, 3.0, pos.z), Vector3(0.7, 0.14, 2.4), Color("#a99b83"), false)
		make_box("BalconyRail", Vector3(front_x - 0.68, 3.35, pos.z), Vector3(0.08, 0.6, 2.4), Color("#514d46"), false)

	if rng.randf() > 0.45:
		make_box("AirConditioner", Vector3(front_x - 0.22, 2.6, pos.z + dimensions.z * 0.28), Vector3(0.42, 0.38, 0.7), Color("#d8d6cd"), false)


func add_rooftop_detail(building_pos: Vector3, building_height: float) -> void:
	var tank := MeshInstance3D.new()
	tank.name = "RooftopWaterTank"
	var tank_mesh := CylinderMesh.new()
	tank_mesh.top_radius = 0.65
	tank_mesh.bottom_radius = 0.65
	tank_mesh.height = 1.35
	tank.mesh = tank_mesh
	tank.position = building_pos + Vector3(0.0, building_height + 0.85, 0.0)
	var tank_material := StandardMaterial3D.new()
	tank_material.albedo_color = Color("#777c7b")
	tank_material.roughness = 0.95
	tank.material_override = tank_material
	add_child(tank)



# --------------------------------------------------
# الحديقة والأشجار
# --------------------------------------------------

func create_park() -> void:
	var park_position := Vector3(25.0, 0.0, 20.0)

	make_box(
		"ParkGrass",
		park_position,
		Vector3(28.0, 0.12, 30.0),
		Color(0.2, 0.42, 0.17),
		true
	)

	make_box(
		"ParkPath",
		park_position + Vector3(0.0, 0.08, 0.0),
		Vector3(3.0, 0.08, 28.0),
		Color(0.72, 0.67, 0.55),
		false
	)

	var rng := RandomNumberGenerator.new()
	rng.seed = 24680

	for i in range(18):
		var tree_x := rng.randf_range(12.0, 38.0)
		var tree_z := rng.randf_range(7.0, 33.0)
		create_tree(Vector3(tree_x, 0.0, tree_z), rng)

	for z in [12.0, 25.0]:
		make_box(
			"ParkBenchSeat",
			Vector3(20.0, 0.65, z),
			Vector3(2.0, 0.18, 0.6),
			Color(0.35, 0.18, 0.08),
			false
		)


func create_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var trunk_height := rng.randf_range(2.0, 3.2)
	var crown_size := rng.randf_range(1.4, 2.1)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = trunk_height
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0.0, trunk_height / 2.0, 0.0)

	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.3, 0.16, 0.08)
	trunk.material_override = bark
	add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = crown_size
	crown_mesh.height = crown_size * 2.0
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(
		0.0, trunk_height + crown_size * 0.55, 0.0
	)
	crown.scale = Vector3(1.0, 1.15, 1.0)

	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.12, 0.4, 0.12)
	crown.material_override = leaves
	add_child(crown)


func create_street_lights() -> void:
	for road_x in [-120.0, -60.0, 0.0, 60.0, 120.0]:
		for side in [-1.0, 1.0]:
			for z in range(-220, 221, 40):
				var lamp_pos := Vector3(
					road_x + side * 8.5,
					0.0,
					float(z)
				)

				make_box(
					"LampPole",
					lamp_pos + Vector3(0.0, 3.0, 0.0),
					Vector3(0.16, 6.0, 0.16),
					Color(0.2, 0.2, 0.2),
					true
				)

				make_box(
					"LampHead",
					lamp_pos + Vector3(0.0, 6.0, -0.5),
					Vector3(0.65, 0.18, 1.0),
					Color(1.0, 0.86, 0.55),
					false
				)


# --------------------------------------------------
# القرية المصرية
# --------------------------------------------------

func create_egyptian_village() -> void:
	# الطريق الترابي
	make_box(
		"VillageRoad",
		Vector3(145.0, 0.02, 350.0),
		Vector3(5.0, 0.12, 300.0),
		Color("#9b8057"),
		true
	)

	# الترعة
	make_box(
		"VillageCanal",
		Vector3(180.0, 0.025, 350.0),
		Vector3(3.0, 0.05, 300.0),
		Color("#477f91"),
		false
	)

	for bank_x in [177.9, 182.1]:
		make_box(
			"CanalBank",
			Vector3(bank_x, 0.12, 350.0),
			Vector3(0.7, 0.25, 300.0),
			Color("#9b8057"),
			true
		)

	# بيوت القرية
	for house_z in [255.0, 280.0, 305.0, 330.0, 355.0, 380.0]:
		create_rural_house(Vector3(156.0, 0.0, house_z))

	# الحقول
	for field_z in [420.0, 465.0]:
		create_rural_field(Vector3(156.0, 0.0, field_z))

	# النخيل
	for palm_z in [250.0, 410.0, 485.0]:
		create_palm_tree(Vector3(174.0, 0.0, palm_z))

	# القهوة والسوق
	create_baladi_cafe(Vector3(133.0, 0.0, 280.0))
	create_baladi_market(Vector3(133.0, 0.0, 310.0))

	# أهل القرية
	create_village_npcs()

	# توك توك متوقف بجوار الطريق
	create_tuk_tuk(Vector3(139.0, 0.0, 350.0))


func create_rural_house(pos: Vector3) -> void:
	make_box(
		"RuralHouse",
		pos + Vector3(0.0, 2.5, 0.0),
		Vector3(8.0, 5.0, 8.0),
		Color("#b69b75"),
		true
	)

	make_box(
		"RuralHouseRoof",
		pos + Vector3(0.0, 5.15, 0.0),
		Vector3(8.4, 0.3, 8.4),
		Color("#75644f"),
		true
	)

	var front_x: float = pos.x - 4.08

	make_box(
		"RuralHouseDoor",
		Vector3(front_x, 1.1, pos.z),
		Vector3(0.12, 2.2, 1.2),
		Color("#503a27"),
		false
	)

	for window_z in [pos.z - 2.2, pos.z + 2.2]:
		make_box(
			"RuralHouseWindow",
			Vector3(front_x - 0.01, 2.8, window_z),
			Vector3(0.1, 1.0, 1.0),
			Color("#476779"),
			false
		)


func create_rural_field(pos: Vector3) -> void:
	make_box(
		"FarmSoil",
		pos + Vector3(0.0, 0.03, 0.0),
		Vector3(14.0, 0.06, 25.0),
		Color("#76583a"),
		true
	)

	for i in range(8):
		var crop_x: float = pos.x - 5.5 + float(i) * 1.55

		make_box(
			"FarmCropRow",
			Vector3(crop_x, 0.32, pos.z),
			Vector3(0.18, 0.5, 21.0),
			Color("#42723a"),
			false
		)


func create_palm_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	trunk.name = "PalmTrunk"

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = 4.0
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0.0, 2.0, 0.0)

	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color("#725032")
	trunk.material_override = trunk_material
	add_child(trunk)

	for i in range(7):
		var angle: float = TAU * float(i) / 7.0

		var leaf := MeshInstance3D.new()
		leaf.name = "PalmLeaf"

		var leaf_mesh := BoxMesh.new()
		leaf_mesh.size = Vector3(0.22, 0.12, 2.5)
		leaf.mesh = leaf_mesh
		leaf.position = pos + Vector3(0.0, 4.0, 0.0)
		leaf.rotation.y = angle
		leaf.rotation.x = -0.35

		var leaf_material := StandardMaterial3D.new()
		leaf_material.albedo_color = Color("#356b32")
		leaf.material_override = leaf_material
		add_child(leaf)


# --------------------------------------------------
# القهوة البلدي
# --------------------------------------------------

func create_baladi_cafe(pos: Vector3) -> void:
	make_box(
		"BaladiCafe",
		pos + Vector3(0.0, 1.8, 0.0),
		Vector3(9.0, 3.6, 7.0),
		Color("#c5a477"),
		true
	)

	# واجهة القهوة
	make_box(
		"CafeFront",
		pos + Vector3(-4.56, 1.5, 0.0),
		Vector3(0.12, 2.8, 5.0),
		Color("#70462b"),
		false
	)

	# لافتة القهوة
	make_box(
		"CafeSign",
		pos + Vector3(-4.7, 3.35, 0.0),
		Vector3(0.18, 0.75, 4.8),
		Color("#294a2c"),
		false
	)

	# ترابيزات وكراسي
	for table_z in [pos.z - 2.0, pos.z + 2.0]:
		make_box(
			"CafeTable",
			Vector3(pos.x - 6.0, 0.8, table_z),
			Vector3(1.4, 0.15, 1.4),
			Color("#6b3e20"),
			false
		)

		for chair_x in [pos.x - 7.0, pos.x - 5.0]:
			make_box(
				"CafeChair",
				Vector3(chair_x, 0.45, table_z),
				Vector3(0.65, 0.75, 0.65),
				Color("#38543a"),
				false
			)


# --------------------------------------------------
# السوق البلدي
# --------------------------------------------------

func create_baladi_market(pos: Vector3) -> void:
	make_box(
		"MarketShop",
		pos + Vector3(0.0, 1.7, 0.0),
		Vector3(8.0, 3.4, 6.0),
		Color("#d1b58a"),
		true
	)

	make_box(
		"MarketAwning",
		pos + Vector3(-4.3, 2.7, 0.0),
		Vector3(0.9, 0.25, 6.8),
		Color("#9c3429"),
		false
	)

	make_box(
		"MarketCounter",
		pos + Vector3(-4.7, 0.7, 0.0),
		Vector3(0.8, 1.2, 4.5),
		Color("#654326"),
		false
	)

	# صناديق الخضار
	var produce_colors: Array[Color] = [
		Color("#4d8b35"),
		Color("#bd3e2d"),
		Color("#d9a63b")
	]

	for i in range(3):
		make_box(
			"ProduceCrate",
			pos + Vector3(-5.3, 1.45, -1.5 + float(i) * 1.5),
			Vector3(0.65, 0.45, 1.2),
			produce_colors[i],
			false
		)


# --------------------------------------------------
# أهل القرية
# --------------------------------------------------

func create_village_npcs() -> void:
	var positions: Array[Vector3] = [
		Vector3(139.0, 0.0, 265.0),
		Vector3(141.0, 0.0, 273.0),
		Vector3(145.0, 0.0, 292.0),
		Vector3(137.0, 0.0, 305.0),
		Vector3(143.0, 0.0, 322.0),
		Vector3(137.0, 0.0, 365.0)
	]

	var clothes: Array[Color] = [
		Color("#e0d1b4"),
		Color("#466b45"),
		Color("#78523c"),
		Color("#a8a8a0"),
		Color("#344f78"),
		Color("#b18a52")
	]

	for i in range(positions.size()):
		var npc := Node3D.new()
		npc.name = "VillageResident_%d" % i
		npc.position = positions[i]
		add_child(npc)

		make_child_capsule(
			npc,
			"Galabeya",
			Vector3(0.0, 0.85, 0.0),
			0.34,
			1.25,
			clothes[i]
		)

		make_child_sphere(
			npc,
			"Head",
			Vector3(0.0, 1.65, 0.0),
			0.24,
			Color("#a87551")
		)

		make_child_box(
			npc,
			"Hair",
			Vector3(0.0, 1.83, 0.0),
			Vector3(0.35, 0.12, 0.35),
			Color("#30251d")
		)


# --------------------------------------------------
# توك توك
# --------------------------------------------------

func create_tuk_tuk(pos: Vector3) -> void:
	var tuk := Node3D.new()
	tuk.name = "BaladiTukTuk"
	tuk.position = pos
	add_child(tuk)

	# قاعدة التوك توك
	make_child_box(
		tuk,
		"TukChassis",
		Vector3(0.0, 0.55, 0.0),
		Vector3(1.6, 0.3, 2.6),
		Color("#252525")
	)

	# جسم التوك توك
	make_child_box(
		tuk,
		"TukBody",
		Vector3(0.0, 1.0, 0.1),
		Vector3(1.5, 0.8, 1.8),
		Color("#d5b72c")
	)

	# السقف
	make_child_box(
		tuk,
		"TukRoof",
		Vector3(0.0, 1.9, 0.0),
		Vector3(1.7, 0.16, 2.1),
		Color("#247343")
	)

	# المقعد
	make_child_box(
		tuk,
		"TukSeat",
		Vector3(0.0, 1.05, 0.65),
		Vector3(1.1, 0.35, 0.5),
		Color("#292929")
	)

	# الزجاج الأمامي
	make_child_box(
		tuk,
		"TukWindshield",
		Vector3(0.0, 1.55, -0.7),
		Vector3(1.15, 0.55, 0.06),
		Color("#75a8b8")
	)

	# العجلات
	for side in [-1.0, 1.0]:
		for end_z in [-0.85, 0.85]:
			var wheel := MeshInstance3D.new()
			wheel.name = "TukWheel"

			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.32
			wheel_mesh.bottom_radius = 0.32
			wheel_mesh.height = 0.2
			wheel.mesh = wheel_mesh

			wheel.position = Vector3(
				side * 0.82,
				0.35,
				end_z
			)
			wheel.rotation_degrees.z = 90.0

			var wheel_material := StandardMaterial3D.new()
			wheel_material.albedo_color = Color("#171717")
			wheel.material_override = wheel_material
			tuk.add_child(wheel)

	# عجلة أمامية إضافية
	var front_wheel := MeshInstance3D.new()
	front_wheel.name = "TukFrontWheel"

	var front_mesh := CylinderMesh.new()
	front_mesh.top_radius = 0.28
	front_mesh.bottom_radius = 0.28
	front_mesh.height = 0.2
	front_wheel.mesh = front_mesh
	front_wheel.position = Vector3(0.0, 0.3, -1.25)
	front_wheel.rotation_degrees.z = 90.0

	var front_material := StandardMaterial3D.new()
	front_material.albedo_color = Color("#171717")
	front_wheel.material_override = front_material
	tuk.add_child(front_wheel)


func create_shop_sign_text(sign_text: String, sign_position: Vector3) -> void:
	var label := Label3D.new()
	label.name = "AbuSenShopName"
	label.text = sign_text
	label.position = sign_position
	label.font_size = 64
	label.pixel_size = 0.012
	label.modulate = Color("#fff1c8")
	label.outline_size = 10
	label.outline_modulate = Color("#10251b")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


# --------------------------------------------------
# حي البداية: مشهد واضح حول نقطة ظهور اللاعب
# --------------------------------------------------

func create_starter_neighborhood() -> void:
	# محلات وواجهات قريبة من اللاعب بدل بدء اللعبة في مساحة تبدو فارغة.
	for i in range(4):
		var x: float = -18.0 + float(i) * 12.0
		var wall: Color = [Color("#cbb99a"), Color("#bda98a"), Color("#d8c7a7"), Color("#b8b5a6")][i]
		make_box("StarterShopBuilding", Vector3(x, 3.2, -13.0), Vector3(8.5, 6.4, 7.0), wall, true)
		make_box("StarterShopFront", Vector3(x, 1.25, -9.38), Vector3(3.0, 2.25, 0.12), Color("#334b50"), false)
		make_box("StarterShopAwning", Vector3(x, 2.55, -9.8), Vector3(4.2, 0.25, 1.0), [Color("#b93f32"), Color("#e2c24c"), Color("#28754a"), Color("#e7e0d1")][i], false)
		if i == 0:
			# محل موبايلات «أبو سن»: لافتة مخصصة وفاترينة زجاج وأجهزة معروضة.
			make_box("AbuSenSignBoard", Vector3(x, 3.15, -9.34), Vector3(5.8, 0.85, 0.18), Color("#153f2c"), false)
			create_shop_sign_text("أبو سن للموبايلات", Vector3(x, 3.15, -9.20))
			make_box("AbuSenPhoneDisplay", Vector3(x, 1.25, -9.25), Vector3(3.5, 1.65, 0.10), Color("#182c35"), false)
			for phone_index in range(5):
				var phone_x: float = x - 1.35 + float(phone_index) * 0.68
				make_box("AbuSenDisplayPhone", Vector3(phone_x, 1.25, -9.16), Vector3(0.34, 0.62, 0.07), [Color("#17191c"), Color("#252a31"), Color("#b7b9bd"), Color("#202c3a"), Color("#8d9a9c")][phone_index], false)
				make_box("AbuSenPhoneScreen", Vector3(phone_x, 1.28, -9.115), Vector3(0.26, 0.47, 0.025), [Color("#4386a8"), Color("#547fa4"), Color("#6d9c9a"), Color("#536b91"), Color("#7da5b7")][phone_index], false)
			# واجهة مصورة مفصلة للمحل، كخامة على سطح ثلاثي الأبعاد بدل الاعتماد على الصناديق وحدها.
			var facade := MeshInstance3D.new()
			facade.name = "AbuSenPhotographicStyleFacade"
			var facade_mesh := QuadMesh.new()
			facade_mesh.size = Vector2(8.0, 4.8)
			facade.mesh = facade_mesh
			facade.position = Vector3(x, 2.75, -8.94)
			var facade_material := StandardMaterial3D.new()
			facade_material.albedo_texture = load("res://assets/textures/abu_sen_mobile_shop.svg")
			facade_material.roughness = 0.82
			facade_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			facade_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			facade.material_override = facade_material
			add_child(facade)
		else:
			make_box("StarterShopSign", Vector3(x, 3.15, -9.34), Vector3(4.8, 0.55, 0.16), Color("#185b3d"), false)
	# توك توك ظاهر من نقطة البداية، وليس بعيدًا في القرية فقط.
	create_tuk_tuk(Vector3(8.0, 0.0, 16.0))
	# أشخاص ثابتون كبداية مرئية في الشارع، بملابس مختلفة.
	var npc_positions: Array[Vector3] = [
		Vector3(-5.5, 0.0, 19.0),
		Vector3(3.8, 0.0, 25.0),
		Vector3(13.0, 0.0, 8.0),
		Vector3(-10.0, 0.0, -1.0)
	]
	var npc_colors: Array[Color] = [
		Color("#e0d1b4"), Color("#466b45"), Color("#78523c"), Color("#344f78")
	]
	for i in range(npc_positions.size()):
		var npc := Node3D.new()
		npc.name = "StarterResident_%d" % i
		npc.position = npc_positions[i]
		add_child(npc)
		make_child_capsule(npc, "Galabeya", Vector3(0.0, 0.85, 0.0), 0.34, 1.25, npc_colors[i])
		make_child_sphere(npc, "Head", Vector3(0.0, 1.65, 0.0), 0.24, Color("#a87551"))
		make_child_box(npc, "Hair", Vector3(0.0, 1.83, 0.0), Vector3(0.35, 0.12, 0.35), Color("#30251d"))
	# أعمدة إنارة قريبة ومقاعد على الرصيف.
	for side in [-1.0, 1.0]:
		make_box("StarterLampPole", Vector3(side * 10.0, 2.5, 11.0), Vector3(0.16, 5.0, 0.16), Color("#41413d"), false)
		make_box("StarterLampHead", Vector3(side * 10.0, 5.0, 11.0), Vector3(0.8, 0.2, 0.35), Color("#e4d9b7"), false)


# --------------------------------------------------
# اللاعب
# --------------------------------------------------

func create_player() -> void:
	var player_instance := PLAYER_SCENE.instantiate() as CharacterBody3D

	if player_instance == null:
		push_error("مشهد اللاعب لا يحتوي على CharacterBody3D.")
		return

	player_instance.name = "Player"
	add_child(player_instance)

	player_reference = player_instance
	player_reference.position = Vector3(0.0, 0.2, 5.0)

	if is_instance_valid(world_manager):
		world_manager.call("set_player", player_reference)


# --------------------------------------------------
# إضافات العالم والحياة والمهام
# --------------------------------------------------

func create_world_extras() -> void:
	world_extras = Node3D.new()
	world_extras.name = "WorldExtras"
	world_extras.set_script(WORLD_EXTRAS_SCRIPT)
	add_child(world_extras)

	if is_instance_valid(player_reference):
		world_extras.call("set_player", player_reference)


func create_world_life() -> void:
	world_life = Node3D.new()
	world_life.name = "WorldLife"
	world_life.set_script(WORLD_LIFE_SCRIPT)
	add_child(world_life)

	if is_instance_valid(player_reference):
		world_life.call("set_player", player_reference)

		if player_reference.has_signal("interact_requested"):
			player_reference.connect(
				"interact_requested",
				Callable(world_life, "handle_interaction")
			)


# --------------------------------------------------
# أزرار الموبايل
# --------------------------------------------------

func create_mobile_controls() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "MobileControls"
	canvas.layer = 5
	add_child(canvas)

	var joystick := Control.new()
	joystick.name = "VirtualJoystick"
	joystick.set_script(JOYSTICK_SCRIPT)
	joystick.add_to_group("virtual_joystick")
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 24.0
	joystick.offset_top = -190.0
	joystick.offset_right = 174.0
	joystick.offset_bottom = -40.0
	joystick.custom_minimum_size = Vector2(150.0, 150.0)
	canvas.add_child(joystick)

	var buttons := VBoxContainer.new()
	buttons.name = "ActionButtons"
	buttons.anchor_left = 1.0
	buttons.anchor_top = 1.0
	buttons.anchor_right = 1.0
	buttons.anchor_bottom = 1.0
	buttons.offset_left = -150.0
	buttons.offset_top = -310.0
	buttons.offset_right = -20.0
	buttons.offset_bottom = -20.0
	buttons.add_theme_constant_override("separation", 12)
	canvas.add_child(buttons)
	create_region_menu(canvas)

	var jump_button := create_action_button("قفز")
	buttons.add_child(jump_button)
	jump_button.pressed.connect(_on_jump_pressed)

	var run_button := create_action_button("جري")
	buttons.add_child(run_button)
	run_button.button_down.connect(_on_run_pressed)
	run_button.button_up.connect(_on_run_released)

	var interact_button := create_action_button("تفاعل")
	buttons.add_child(interact_button)
	interact_button.pressed.connect(_on_interact_pressed)


# --------------------------------------------------
# دليل محافظات مصر ومدنها ومراكزها
# --------------------------------------------------
func create_region_menu(canvas: CanvasLayer) -> void:
	var open_button := create_action_button("خريطة مصر")
	open_button.name = "EgyptMapButton"
	open_button.custom_minimum_size = Vector2(145.0, 52.0)
	open_button.anchor_left = 1.0
	open_button.anchor_right = 1.0
	open_button.anchor_top = 0.0
	open_button.anchor_bottom = 0.0
	open_button.position = Vector2(-165.0, 18.0)
	canvas.add_child(open_button)

	var panel := PanelContainer.new()
	panel.name = "EgyptRegionPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.08
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.92
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.visible = false
	canvas.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "دليل محافظات مصر الـ٢٧"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "اختار محافظة لعرض المدن والمراكز"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)

	var region_scroll := ScrollContainer.new()
	region_scroll.custom_minimum_size = Vector2(155.0, 0.0)
	region_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(region_scroll)

	var region_list := VBoxContainer.new()
	region_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_scroll.add_child(region_list)

	var details_scroll := ScrollContainer.new()
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(details_scroll)

	var details_content := VBoxContainer.new()
	details_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.add_child(details_content)
	var details := Label.new()
	details.name = "RegionDetails"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.text = "اختار محافظة من القائمة"
	details_content.add_child(details)
	var places_box := VBoxContainer.new()
	places_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_content.add_child(places_box)

	var close_button := create_action_button("إغلاق")
	close_button.custom_minimum_size = Vector2(100.0, 48.0)
	layout.add_child(close_button)
	close_button.pressed.connect(func(): panel.visible = false)
	open_button.pressed.connect(func(): panel.visible = not panel.visible)

	var selected_region: Dictionary = {}
	var selected_place: String = ""
	var travel_button := create_action_button("سافر للمكان المختار")
	travel_button.custom_minimum_size = Vector2(190.0, 52.0)
	layout.add_child(travel_button)
	travel_button.pressed.connect(func():
		if not selected_region.is_empty() and not selected_place.is_empty():
			var destination_data: Dictionary = selected_region.duplicate(true)
			destination_data["settlement_type"] = "قرية" if selected_place.begins_with("قرية ") else ("مركز" if selected_place.begins_with("مركز ") else "مدينة")
			travel_to_region(destination_data, selected_place)
			panel.visible = false
	)
	var regions: Array[Dictionary] = EGYPT_REGIONS_SCRIPT.all_regions()
	for item in regions:
		var region_button := Button.new()
		region_button.text = str(item.get("name", ""))
		region_button.custom_minimum_size = Vector2(135.0, 44.0)
		region_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		region_list.add_child(region_button)
		region_button.pressed.connect(func():
			selected_region = item
			selected_place = ""
			details.text = str(item.get("name", "")) + "\\n" + str(item.get("zone", "")) + "\\nاختار مدينة أو مركزًا أو قرية من القائمة بالأسفل."
			for child in places_box.get_children():
				child.queue_free()
			var places: Array = item.get("places", [])
			for place_variant in places:
				var place_name := str(place_variant)
				var place_button := Button.new()
				place_button.text = "مدينة: " + place_name
				place_button.custom_minimum_size = Vector2(170.0, 42.0)
				place_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				places_box.add_child(place_button)
				place_button.pressed.connect(func():
					selected_place = place_name
					details.text = str(item.get("name", "")) + "\\nالمكان المختار: " + place_name + "\\nسيتم توليد منطقة مستقلة لهذا المكان."
				)
				var village_button := Button.new()
				village_button.text = "قرية من " + place_name
				village_button.custom_minimum_size = Vector2(170.0, 38.0)
				village_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var center_button := Button.new()
				center_button.text = "مركز: " + place_name
				center_button.custom_minimum_size = Vector2(170.0, 38.0)
				center_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				places_box.add_child(center_button)
				center_button.pressed.connect(func():
					selected_place = "مركز " + place_name
					details.text = str(item.get("name", "")) + "\\nالمركز المختار: " + place_name + "\\nسيتم توليد نموذج مركز مستقل."
				)
				places_box.add_child(village_button)
				village_button.pressed.connect(func():
					selected_place = "قرية " + place_name
					details.text = str(item.get("name", "")) + "\\nالقرية المختارة: " + place_name + "\\nسيتم توليد نموذج قرية مستقل."
				)
		)


func create_action_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(100.0, 70.0)
	button.add_theme_font_size_override("font_size", 22)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.08, 0.09, 0.88)
	normal.border_color = Color(0.85, 0.72, 0.35)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(18)
	button.add_theme_stylebox_override("normal", normal)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.35, 0.27, 0.12, 0.95)
	pressed_style.border_color = Color(1.0, 0.82, 0.3)
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(18)
	button.add_theme_stylebox_override("pressed", pressed_style)

	return button


func _on_jump_pressed() -> void:
	if is_instance_valid(player_reference):
		if player_reference.has_method("request_jump"):
			player_reference.call("request_jump")


func _on_run_pressed() -> void:
	if is_instance_valid(player_reference):
		if player_reference.has_method("set_running"):
			player_reference.call("set_running", true)


func _on_run_released() -> void:
	if is_instance_valid(player_reference):
		if player_reference.has_method("set_running"):
			player_reference.call("set_running", false)


func _on_interact_pressed() -> void:
	if is_instance_valid(player_reference):
		if player_reference.has_method("interact"):
			player_reference.call("interact")


# --------------------------------------------------
# دوال إنشاء المجسمات
# --------------------------------------------------

func make_box(
	object_name: String,
	pos: Vector3,
	dimensions: Vector3,
	color: Color,
	with_collision: bool
) -> Node3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material

	if with_collision:
		var body := StaticBody3D.new()
		body.name = object_name + "Body"
		body.position = pos

		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape

		body.add_child(collision)
		add_child(body)
		add_child(mesh_instance)
		return body

	add_child(mesh_instance)
	return mesh_instance


func make_child_box(
	parent: Node3D,
	object_name: String,
	pos: Vector3,
	dimensions: Vector3,
	color: Color
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = object_name

	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	part.material_override = material

	parent.add_child(part)
	return part


func make_child_sphere(
	parent: Node3D,
	object_name: String,
	pos: Vector3,
	radius: float,
	color: Color
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = object_name

	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	part.mesh = mesh
	part.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	part.material_override = material

	parent.add_child(part)
	return part


func make_child_capsule(
	parent: Node3D,
	object_name: String,
	pos: Vector3,
	radius: float,
	height: float,
	color: Color
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = object_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = pos

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	part.material_override = material

	parent.add_child(part)
	return part


# --------------------------------------------------
# الانتقال إلى المدينة أو المركز أو القرية المختارة
# --------------------------------------------------
func travel_to_region(region: Dictionary, settlement_name: String = "") -> void:
	if region_builder == null or not is_instance_valid(region_builder):
		region_builder = Node3D.new()
		region_builder.name = "EgyptRegionBuilder"
		region_builder.set_script(EGYPT_REGION_BUILDER_SCRIPT)
		add_child(region_builder)

	var destination: Vector3 = Vector3(500.0, 0.0, 500.0)
	region_builder.call("build_region", region, destination, settlement_name)

	if is_instance_valid(player_reference):
		player_reference.global_position = destination + Vector3(0.0, 1.0, 0.0)
		if player_reference is CharacterBody3D:
			(player_reference as CharacterBody3D).velocity = Vector3.ZERO
