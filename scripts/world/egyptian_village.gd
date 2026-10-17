
extends Node3D

const WALL := Color("#b69b75")
const ROOF := Color("#75644f")
const DIRT := Color("#9b8057")
const WATER := Color("#477f91")
const GREEN := Color("#42723a")
const WOOD := Color("#503a27")
const SKIN := Color("#B9794F")

var player: CharacterBody3D
var villagers: Array[Node3D] = []
var origins: Array[Vector3] = []
var directions: Array[float] = []

var tuk_tuk: Node3D
var vehicle_camera: Camera3D
var player_camera: Camera3D
var driving := false

var forward_pressed := false
var reverse_pressed := false
var left_pressed := false
var right_pressed := false

var speed := 0.0
var steering := 0.0


func _ready() -> void:
	build_village()
	build_cafe_and_market()
	build_villagers()
	build_tuk_tuk()
	build_controls()


func set_player(value: CharacterBody3D) -> void:
	player = value
	player_camera = player.get_node_or_null(
		"CameraPivot/Camera3D"
	) as Camera3D


func build_village() -> void:
	box("VillageRoad", Vector3(145, 0.05, 350),
		Vector3(5, 0.1, 300), DIRT, true)

	box("Canal", Vector3(166, 0.03, 350),
		Vector3(3, 0.05, 280), WATER, false)

	for x in [163.9, 168.1]:
		box("CanalBank", Vector3(x, 0.12, 350),
			Vector3(0.7, 0.25, 280), DIRT, true)

	for z in [-105.0, -85.0, -65.0, -45.0, -25.0, -5.0]:
		build_house(Vector3(156, 0, z))

	for z in [35.0, 75.0, 115.0, 155.0, 195.0]:
		box("FarmSoil", Vector3(155, 0.03, z),
			Vector3(14, 0.06, 25), Color("#76583a"), true)

		for i in range(8):
			box("CropRow",
				Vector3(150 + i * 1.5, 0.35, z),
				Vector3(0.2, 0.5, 21), GREEN, false)

	for z in [-125.0, -15.0, 145.0, 205.0, 245.0]:
		build_palm(Vector3(161, 0, z))


func build_house(pos: Vector3) -> void:
	box("RuralHouse", pos + Vector3(0, 2.5, 0),
		Vector3(8, 5, 8), WALL, true)

	box("HouseRoof", pos + Vector3(0, 5.15, 0),
		Vector3(8.4, 0.3, 8.4), ROOF, true)

	var front_x := pos.x - 4.08

	box("HouseDoor", Vector3(front_x, 1.1, pos.z),
		Vector3(0.12, 2.2, 1.2), WOOD, false)

	for z in [pos.z - 2.2, pos.z + 2.2]:
		box("HouseWindow", Vector3(front_x, 2.8, z),
			Vector3(0.1, 1.0, 1.0),
			Color("#476779"), false)


func build_palm(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.3
	mesh.height = 4.0
	trunk.mesh = mesh
	trunk.position = pos + Vector3(0, 2, 0)
	trunk.material_override = material(Color("#725032"))
	add_child(trunk)

	for i in range(7):
		var leaf := MeshInstance3D.new()
		var leaf_mesh := BoxMesh.new()
		leaf_mesh.size = Vector3(0.22, 0.12, 2.5)
		leaf.mesh = leaf_mesh
		leaf.position = pos + Vector3(0, 4, 0)
		leaf.rotation.y = TAU * float(i) / 7.0
		leaf.rotation.x = -0.35
		leaf.material_override = material(Color("#356b32"))
		add_child(leaf)


func build_cafe_and_market() -> void:
	# القهوة البلدي
	box("AhwaFloor", Vector3(133, 0.1, 280),
		Vector3(13, 0.2, 10), Color("#b7a17b"), true)

	box("AhwaBackWall", Vector3(133, 2, 275.3),
		Vector3(13, 4, 0.3), WALL, true)

	box("AhwaRoof", Vector3(133, 4.1, 280),
		Vector3(13.5, 0.3, 10.5), ROOF, true)

	box("AhwaCounter", Vector3(136, 1, 277),
		Vector3(4.5, 1.5, 1), WOOD, true)

	for z in [280.0, 283.0]:
		for x in [129.0, 132.0, 135.0]:
			box("CafeTable", Vector3(x, 0.85, z),
				Vector3(1.2, 0.12, 1.2), WOOD, false)

			box("CafeChair", Vector3(x, 0.4, z + 0.9),
				Vector3(0.6, 0.8, 0.6),
				Color("#427b86"), false)

	# أربعة محلات في السوق
	var awnings: Array[Color] = [
		Color("#b43c32"),
		Color("#e1d5b7"),
		Color("#34714a"),
		Color("#d6a13b")
	]

	for i in range(4):
		var x := 119.0 + float(i) * 8.0

		box("MarketShop", Vector3(x, 1.8, 300),
			Vector3(6.5, 3.6, 5), Color("#d0b58b"), true)

		box("ShopAwning", Vector3(x, 3.1, 296.9),
			Vector3(6.8, 0.35, 1.4), awnings[i], false)

		box("ShopCounter", Vector3(x, 0.8, 297),
			Vector3(5.5, 1.2, 0.45), WOOD, false)


func build_villagers() -> void:
	var clothes: Array[Color] = [
		Color("#d6c8a8"),
		Color("#6e8d70"),
		Color("#a66a45"),
		Color("#c4b39b")
	]

	for i in range(6):
		var pos := Vector3(
			139.0 + float(i % 3) * 4.0,
			0,
			260.0 + float(i / 3) * 12.0
		)

		var npc := Node3D.new()
		npc.name = "Villager_%d" % i
		npc.position = pos
		add_child(npc)

		make_box_child(npc, "Galabeya",
			Vector3(0, 0.9, 0),
			Vector3(0.55, 1.25, 0.35), clothes[i % 4])

		make_sphere_child(npc, "Head",
			Vector3(0, 1.72, 0),
			Vector3(0.22, 0.26, 0.22), SKIN)

		make_sphere_child(npc, "Hair",
			Vector3(0, 1.9, 0.02),
			Vector3(0.22, 0.1, 0.22), Color("#211b19"))

		make_box_child(npc, "LeftLeg",
			Vector3(-0.14, 0.25, 0),
			Vector3(0.16, 0.5, 0.18), Color("#303944"))

		make_box_child(npc, "RightLeg",
			Vector3(0.14, 0.25, 0),
			Vector3(0.16, 0.5, 0.18), Color("#303944"))

		villagers.append(npc)
		origins.append(pos)
		directions.append(1.0 if i % 2 == 0 else -1.0)


func build_tuk_tuk() -> void:
	tuk_tuk = Node3D.new()
	tuk_tuk.name = "EgyptianTukTuk"
	tuk_tuk.position = Vector3(5, 0, 10)
	add_child(tuk_tuk)

	box_child(tuk_tuk, "Chassis",
		Vector3(0, 0.65, 0), Vector3(1.7, 0.55, 2.5),
		Color("#247aab"))

	box_child(tuk_tuk, "FrontNose",
		Vector3(0, 0.85, -1.2), Vector3(1.2, 0.6, 0.5),
		Color("#e4c64d"))

	box_child(tuk_tuk, "Cabin",
		Vector3(0, 1.45, 0.65), Vector3(1.55, 1, 0.9),
		Color("#247aab"))

	box_child(tuk_tuk, "Roof",
		Vector3(0, 2.15, 0), Vector3(1.8, 0.18, 2.2),
		Color("#d7d0bd"))

	box_child(tuk_tuk, "Windshield",
		Vector3(0, 1.45, -0.72), Vector3(1.1, 0.55, 0.06),
		Color("#7fb5c9"))

	box_child(tuk_tuk, "Seat",
		Vector3(0, 1.05, -0.05), Vector3(0.9, 0.35, 0.5),
		Color("#30241f"))

	for x in [-0.9, 0.9]:
		for z in [-0.8, 0.8]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.32
			wheel_mesh.bottom_radius = 0.32
			wheel_mesh.height = 0.18
			wheel.mesh = wheel_mesh
			wheel.position = Vector3(x, 0.35, z)
			wheel.rotation.z = PI / 2.0
			wheel.material_override = material(Color("#242424"))
			tuk_tuk.add_child(wheel)

	vehicle_camera = Camera3D.new()
	vehicle_camera.position = Vector3(0, 4, 7)
	vehicle_camera.rotation_degrees = Vector3(-18, 0, 0)
	vehicle_camera.fov = 75
	tuk_tuk.add_child(vehicle_camera)


func build_controls() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "VehicleControls"
	canvas.layer = 8
	add_child(canvas)

	var enter := Button.new()
	enter.text = "ركوب / نزول"
	enter.position = Vector2(15, 15)
	enter.custom_minimum_size = Vector2(150, 55)
	canvas.add_child(enter)
	enter.pressed.connect(toggle_driving)

	var row := HBoxContainer.new()
	row.position = Vector2(15, 80)
	canvas.add_child(row)

	var left := control_button("◀")
	row.add_child(left)
	left.button_down.connect(func(): left_pressed = true)
	left.button_up.connect(func(): left_pressed = false)

	var forward := control_button("قدام")
	row.add_child(forward)
	forward.button_down.connect(func(): forward_pressed = true)
	forward.button_up.connect(func(): forward_pressed = false)

	var reverse := control_button("ورا")
	row.add_child(reverse)
	reverse.button_down.connect(func(): reverse_pressed = true)
	reverse.button_up.connect(func(): reverse_pressed = false)

	var right := control_button("▶")
	row.add_child(right)
	right.button_down.connect(func(): right_pressed = true)
	right.button_up.connect(func(): right_pressed = false)


func _process(delta: float) -> void:
	for i in range(villagers.size()):
		var npc := villagers[i]
		npc.position.z += directions[i] * delta * 0.7

		if absf(npc.position.z - origins[i].z) > 4:
			directions[i] *= -1

		npc.rotation.y = PI if directions[i] > 0 else 0

	if not driving:
		return

	if forward_pressed:
		speed = move_toward(speed, 8, delta * 4)
	elif reverse_pressed:
		speed = move_toward(speed, -3, delta * 4)
	else:
		speed = move_toward(speed, 0, delta * 6)

	var target_steering := 0.0
	if left_pressed:
		target_steering = 1.0
	elif right_pressed:
		target_steering = -1.0

	steering = move_toward(steering, target_steering, delta * 2.5)
	tuk_tuk.rotation.y += steering * delta * minf(absf(speed) / 4, 1)
	tuk_tuk.position += -tuk_tuk.global_transform.basis.z * speed * delta


func toggle_driving() -> void:
	if not is_instance_valid(player):
		return

	driving = not driving

	if driving:
		player_camera = player.get_node_or_null(
			"CameraPivot/Camera3D"
		) as Camera3D

		if is_instance_valid(player_camera):
			player_camera.current = false

		vehicle_camera.current = true
		player.set_physics_process(false)
	else:
		vehicle_camera.current = false

		if is_instance_valid(player_camera):
			player_camera.current = true

		player.set_physics_process(true)
		player.global_position = tuk_tuk.global_position + Vector3(2, 0, 0)
		player.velocity = Vector3.ZERO

	speed = 0
	forward_pressed = false
	reverse_pressed = false
	left_pressed = false
	right_pressed = false


func control_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(70, 55)
	return button


func box_child(parent: Node3D, label: String, pos: Vector3,
		size: Vector3, color: Color) -> void:
	make_box_child(parent, label, pos, size, color)


func make_box_child(parent: Node3D, label: String, pos: Vector3,
		size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material(color)
	parent.add_child(instance)
	return instance


func make_sphere_child(parent: Node3D, label: String, pos: Vector3,
		size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	instance.mesh = mesh
	instance.position = pos
	instance.scale = size
	instance.material_override = material(color)
	parent.add_child(instance)


func box(label: String, pos: Vector3, size: Vector3,
		color: Color, collision: bool) -> void:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material(color)
	add_child(instance)

	if collision:
		var body := StaticBody3D.new()
		body.name = label + "Body"
		body.position = pos

		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		add_child(body)


func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat
