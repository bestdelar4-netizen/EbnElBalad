
extends Node3D

const WALL := Color("#b69b75")
const ROOF := Color("#75644f")
const DIRT := Color("#9b8057")
const WATER := Color("#477f91")
const GREEN := Color("#42723a")
const WOOD := Color("#503a27")


func _ready() -> void:
	build_village()


func build_village() -> void:
	# طريق القرية
	make_box(
		"VillageDirtRoad",
		Vector3(145, 0.04, 55),
		Vector3(5, 0.08, 300),
		DIRT,
		true
	)

	# الترعة
	make_box(
		"VillageCanal",
		Vector3(166, 0.025, 55),
		Vector3(3, 0.05, 280),
		WATER,
		false
	)

	# حافتا الترعة
	for x in [163.9, 168.1]:
		make_box(
			"CanalBank",
			Vector3(x, 0.12, 55),
			Vector3(0.7, 0.25, 280),
			DIRT,
			true
		)

	# بيوت القرية
	for z in [-105.0, -85.0, -65.0, -45.0, -25.0, -5.0]:
		make_house(Vector3(156, 0, z))

	# الحقول الزراعية
	for z in [35.0, 75.0, 115.0]:
		make_field(Vector3(155.5, 0, z))

	# النخيل
	for z in [-125.0, -15.0, 145.0, 175.0]:
		make_palm(Vector3(161, 0, z))


func make_house(pos: Vector3) -> void:
	var height := 5.0
	var width := 8.0
	var depth := 8.0

	# جدران البيت
	make_box(
		"RuralHouse",
		pos + Vector3(0, height / 2.0, 0),
		Vector3(width, height, depth),
		WALL,
		true
	)

	# حافة السطح
	make_box(
		"HouseRoofRim",
		pos + Vector3(0, height + 0.15, 0),
		Vector3(width + 0.35, 0.3, depth + 0.35),
		ROOF,
		true
	)

	# الباب في واجهة البيت
	var front_x: float = pos.x - width / 2.0 - 0.07

	make_box(
		"HouseDoor",
		Vector3(front_x, 1.1, pos.z),
		Vector3(0.12, 2.2, 1.15),
		WOOD,
		false
	)

	# الشبابيك
	for window_z in [pos.z - 2.2, pos.z + 2.2]:
		make_box(
			"HouseWindow",
			Vector3(front_x, 2.8, window_z),
			Vector3(0.12, 1.0, 1.0),
			Color("#476779"),
			false
		)

	# عتبة الباب
	make_box(
		"DoorStep",
		Vector3(front_x - 0.2, 0.08, pos.z),
		Vector3(0.6, 0.16, 1.5),
		Color("#8d795e"),
		true
	)


func make_field(pos: Vector3) -> void:
	# تربة الحقل
	make_box(
		"FarmSoil",
		pos + Vector3(0, 0.03, 0),
		Vector3(12, 0.06, 25),
		Color("#76583a"),
		true
	)

	# صفوف الزرع
	for i in range(7):
		var x := pos.x - 5.0 + float(i) * 1.65

		make_box(
			"CropRow",
			Vector3(x, 0.34, pos.z),
			Vector3(0.12, 0.55, 21),
			GREEN,
			false
		)


func make_palm(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	trunk.name = "PalmTrunk"

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = 4.0

	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 2, 0)
	trunk.material_override = make_material(
		Color("#725032")
	)
	add_child(trunk)

	# سعف النخيل
	for i in range(6):
		var angle := TAU * float(i) / 6.0

		var leaf := MeshInstance3D.new()
		leaf.name = "PalmLeaf"

		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 0.12, 2.5)

		leaf.mesh = mesh
		leaf.position = pos + Vector3(0, 4.0, 0)
		leaf.rotation.y = angle
		leaf.rotation.x = -0.35
		leaf.material_override = make_material(
			Color("#356b32")
		)
		add_child(leaf)


func make_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat


func make_box(
	object_name: String,
	pos: Vector3,
	dimensions: Vector3,
	color: Color,
	with_collision: bool
) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = object_name

	var mesh := BoxMesh.new()
	mesh.size = dimensions

	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = make_material(color)
	add_child(mesh_instance)

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
