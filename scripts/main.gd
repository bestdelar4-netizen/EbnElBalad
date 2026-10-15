
extends Node3D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const WORLD_MANAGER_SCRIPT = preload("res://scripts/world/world_manager.gd")
const WORLD_EXTRAS_SCRIPT = preload("res://scripts/world/world_extras.gd")
const WORLD_LIFE_SCRIPT = preload("res://scripts/world/world_life.gd")

var player_reference: Node3D
var world_manager: Node3D
var world_extras: Node3D
var world_life: Node3D


func _ready() -> void:
	create_environment()
	create_world_manager()
	create_world()
	create_mobile_controls()
	create_player()
	create_world_extras()
	create_world_life()


func create_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.35, 0.68)
	sky_material.sky_horizon_color = Color(0.65, 0.78, 0.9)
	sky_material.ground_bottom_color = Color(0.22, 0.2, 0.16)
	sky_material.ground_horizon_color = Color(0.55, 0.53, 0.45)
	sky.sky_material = sky_material

	environment.sky = sky
	world_env.environment = environment
	add_child(world_env)


func create_world_manager() -> void:
	world_manager = Node3D.new()
	world_manager.name = "WorldManager"
	world_manager.set_script(WORLD_MANAGER_SCRIPT)
	add_child(world_manager)


func create_world() -> void:
	create_ground()
	create_roads()
	create_buildings()
	create_park()
	create_street_lights()


func create_ground() -> void:
	make_box(
		"CityGround",
		Vector3(0.0, -0.5, 0.0),
		Vector3(340.0, 1.0, 520.0),
		Color(0.65, 0.57, 0.4),
		true
	)


func create_roads() -> void:
	# الشوارع الرئيسية
	for road_x in [-120.0, -60.0, 0.0, 60.0, 120.0]:
		make_box(
			"MainRoad",
			Vector3(road_x, 0.02, 0.0),
			Vector3(10.0, 0.12, 480.0),
			Color(0.16, 0.16, 0.17),
			true
		)

		# الأرصفة
		for side in [-1.0, 1.0]:
			make_box(
				"Sidewalk",
				Vector3(road_x + side * 7.0, 0.08, 0.0),
				Vector3(3.5, 0.2, 480.0),
				Color(0.62, 0.6, 0.54),
				true
			)

		# خطوط الطريق
		for z in range(-230, 231, 12):
			make_box(
				"RoadMarking",
				Vector3(road_x, 0.095, float(z)),
				Vector3(0.16, 0.02, 4.0),
				Color(0.95, 0.88, 0.62),
				false
			)

	# الشوارع العرضية
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

	# حافة سطح المبنى
	make_box(
		"RoofEdge",
		pos + Vector3(0.0, height + 0.15, 0.0),
		Vector3(dimensions.x + 0.3, 0.3, dimensions.z + 0.3),
		Color(0.48, 0.43, 0.36),
		true
	)

	# الواجهة الأمامية
	var front_x := pos.x - signf(pos.x) * (
		dimensions.x / 2.0 + 0.04
	)

	# الشبابيك
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

	# باب أو محل
	make_box(
		"Entrance",
		Vector3(front_x - 0.08, 1.1, pos.z),
		Vector3(0.12, 2.2, 1.4),
		Color(0.25, 0.18, 0.12),
		false
	)

	# تكييف خارجي
	if rng.randf() > 0.35:
		make_box(
			"AirConditioner",
			Vector3(
				front_x - 0.15,
				minf(height - 1.0, 4.0),
				pos.z + 2.0
			),
			Vector3(0.35, 0.55, 0.8),
			Color(0.78, 0.78, 0.73),
			false
		)


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

	# مقاعد الحديقة
	for z in [12.0, 25.0]:
		make_box(
			"ParkBenchSeat",
			Vector3(20.0, 0.65, z),
			Vector3(2.0, 0.18, 0.6),
			Color(0.35, 0.18, 0.08),
			false
		)

		make_box(
			"ParkBenchLegs",
			Vector3(20.0, 0.35, z),
			Vector3(1.6, 0.5, 0.15),
			Color(0.15, 0.15, 0.15),
			false
		)


func create_tree(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var trunk_height := rng.randf_range(2.0, 3.2)
	var crown_size := rng.randf_range(1.4, 2.1)

	var trunk := MeshInstance3D.new()
	trunk.name = "TreeTrunk"

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = trunk_height
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(
		0.0, trunk_height / 2.0, 0.0
	)

	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.3, 0.16, 0.08)
	trunk.material_override = bark
	add_child(trunk)

	var crown := MeshInstance3D.new()
	crown.name = "TreeCrown"

	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = crown_size
	crown_mesh.height = crown_size * 2.0
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(
		0.0,
		trunk_height + crown_size * 0.55,
		0.0
	)
	crown.scale = Vector3(1.0, 1.15, 1.0)

	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(
		rng.randf_range(0.08, 0.18),
		rng.randf_range(0.32, 0.48),
		rng.randf_range(0.08, 0.16)
	)
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


func create_player() -> void:
	var player_instance := PLAYER_SCENE.instantiate()
	player_instance.name = "Player"
	add_child(player_instance)

	player_reference = player_instance as Node3D
	player_reference.position = Vector3(0.0, 0.2, 5.0)

	if is_instance_valid(world_manager):
		world_manager.call("set_player", player_reference)


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


func create_mobile_controls() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "MobileControls"
	canvas.layer = 5
	add_child(canvas)

	var joystick := Control.new()
	joystick.name = "VirtualJoystick"
	joystick.set_script(JOYSTICK_SCRIPT)
	joystick.position = Vector2(35.0, 430.0)
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

	var jump_button := create_action_button("×")
	buttons.add_child(jump_button)
	jump_button.pressed.connect(_on_jump_pressed)

	var run_button := create_action_button("R2")
	buttons.add_child(run_button)
	run_button.button_down.connect(_on_run_pressed)
	run_button.button_up.connect(_on_run_released)

	var interact_button := create_action_button("□")
	buttons.add_child(interact_button)
	interact_button.pressed.connect(_on_interact_pressed)


func create_action_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(100.0, 70.0)
	button.add_theme_font_size_override("font_size", 26)

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
