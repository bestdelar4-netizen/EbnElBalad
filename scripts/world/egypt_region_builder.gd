extends Node3D
class_name EgyptRegionBuilder

# مولّد مناطق أولي: ينشئ مركز مدينة قابلًا للاستكشاف لكل محافظة عند اختيارها.
# الهدف إبقاء عدد المجسمات معقولًا على الهواتف، وليس الادعاء أن هذه خريطة جغرافية دقيقة.
var active_root: Node3D
var active_region_name: String = ""

func build_region(region: Dictionary, origin: Vector3) -> Node3D:
	if is_instance_valid(active_root):
		active_root.queue_free()
	active_root = Node3D.new()
	active_root.name = "Region_" + str(region.get("name", "مصر"))
	add_child(active_root)
	active_root.position = origin
	active_region_name = str(region.get("name", "مصر"))
	var zone := str(region.get("zone", "وادي النيل"))
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(active_region_name.hash())
	var ground_color := Color("#b8a27a")
	if zone == "دلتا النيل":
		ground_color = Color("#71834a")
	elif zone == "الساحل الشمالي" or zone == "الساحل الشمالي والصحراء الغربية" or zone == "البحر الأحمر والصحراء الشرقية":
		ground_color = Color("#d2c19a")
	elif zone == "سيناء" or zone == "الصحراء الغربية":
		ground_color = Color("#c6a06c")
	elif zone == "قناة السويس":
		ground_color = Color("#b9b19b")
	_box("RegionalGround", Vector3(0,-0.55,0), Vector3(210,1,210), ground_color, true)
	_box("RegionalMainRoad", Vector3(0,0.02,0), Vector3(10,0.12,190), Color("#292929"), true)
	_box("RegionalCrossRoad", Vector3(0,0.03,0), Vector3(190,0.12,9), Color("#292929"), true)
	for side in [-1.0, 1.0]:
		for i in range(7):
			var z := -72.0 + float(i) * 23.0
			if absf(z) < 12.0:
				continue
			_build_house(Vector3(side * 18.0,0,z), rng, zone)
		for i in range(5):
			var x := -70.0 + float(i) * 35.0
			if absf(x) < 12.0:
				continue
			_build_house(Vector3(x,0,side * 19.0), rng, zone)
	# لافتة دخول المحافظة
	_box("RegionSign", Vector3(0,4,-86), Vector3(15,4,0.7), Color("#15583d"), false)
	_box("SignPostLeft", Vector3(-6,2,-86), Vector3(0.35,4,0.35), Color("#5e5a50"), false)
	_box("SignPostRight", Vector3(6,2,-86), Vector3(0.35,4,0.35), Color("#5e5a50"), false)
	var label := Label3D.new()
	label.name = "GovernorateName"
	label.text = active_region_name
	label.position = Vector3(0,4.2,-85.5)
	label.font_size = 64
	label.modulate = Color("#fff4d6")
	label.outline_size = 8
	active_root.add_child(label)
	_add_local_features(zone, rng)
	return active_root

func _build_house(pos: Vector3, rng: RandomNumberGenerator, zone: String) -> void:
	var floors := rng.randi_range(1,4)
	var h := float(floors) * 3.0
	var wall := Color("#d6c5a5")
	if zone == "دلتا النيل":
		wall = [Color("#d7c6a6"), Color("#b9c49a"), Color("#c9b18c")][rng.randi_range(0,2)]
	elif zone == "الساحل الشمالي" or zone == "الساحل الشمالي والصحراء الغربية" or zone == "البحر الأحمر والصحراء الشرقية":
		wall = Color("#e0d5bd")
	elif zone == "جنوب الصعيد":
		wall = Color("#d2b18b")
	_box("House", pos + Vector3(0,h/2,0), Vector3(rng.randf_range(7,10),h,rng.randf_range(7,10)), wall, true)
	_box("FrontDoor", pos + Vector3(0,1.0,-4.2), Vector3(1.2,2,0.12), Color("#493124"), false)
	for floor_no in range(floors):
		for window_no in [-1.0,1.0]:
			_box("Window", pos + Vector3(window_no*2.0,1.7+float(floor_no)*3.0,-4.25), Vector3(1.15,1.1,0.12), Color("#587e91"), false)
	_box("RoofTank", pos + Vector3(1.5,h+0.7,1), Vector3(1.5,1.4,1.5), Color("#777b7b"), false)
	if rng.randf() > 0.55:
		_box("Balcony", pos + Vector3(0,3.0,-4.8), Vector3(3.5,0.15,1.0), Color("#8e8170"), false)

func _add_local_features(zone: String, rng: RandomNumberGenerator) -> void:
	if zone == "دلتا النيل":
		for i in range(12):
			var x := -88.0 + float(i)*16.0
			_box("GreenField", Vector3(x,-0.02,77), Vector3(12,0.08,28), Color("#597a37"), false)
			_cylinder("PalmTrunk", Vector3(x,2,62), 0.32, 4.0, Color("#70502e"))
			_cylinder("PalmCrown", Vector3(x,4.4,62), 1.6, 0.6, Color("#35652d"))
	elif zone == "الساحل الشمالي" or zone == "الساحل الشمالي والصحراء الغربية" or zone == "البحر الأحمر والصحراء الشرقية":
		_box("Sea", Vector3(0,-0.1,90), Vector3(205,0.15,25), Color("#287da1"), false)
		_box("Beach", Vector3(0,-0.01,72), Vector3(205,0.12,12), Color("#e1d0a0"), false)
	elif zone == "قناة السويس":
		_box("Canal", Vector3(78,-0.08,0), Vector3(22,0.15,185), Color("#2e87a5"), false)
	elif zone == "سيناء" or zone == "الصحراء الغربية":
		for i in range(5):
			var hill := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 1.0
			mesh.height = 2.0
			hill.mesh = mesh
			hill.scale = Vector3(12.0, rng.randf_range(3,8), 18.0)
			hill.position = Vector3(-85.0+float(i)*42.0,2.0,85.0)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("#a98b60")
			mat.roughness = 1.0
			hill.material_override = mat
			active_root.add_child(hill)
	else:
		_box("PublicSquare", Vector3(40,0.05,40), Vector3(24,0.12,24), Color("#7e8a59"), false)

func _box(label: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var body := StaticBody3D.new() if collision else Node3D.new()
	body.name = label
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	active_root.add_child(body)

func _cylinder(label: String, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	active_root.add_child(node)
