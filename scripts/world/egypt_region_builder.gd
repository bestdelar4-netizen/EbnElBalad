extends Node3D
class_name EgyptRegionBuilder

# مولّد مناطق أولي: ينشئ مركز مدينة قابلًا للاستكشاف لكل محافظة عند اختيارها.
# الهدف إبقاء عدد المجسمات معقولًا على الهواتف، وليس الادعاء أن هذه خريطة جغرافية دقيقة.
var active_root: Node3D
var active_region_name: String = ""

func build_region(region: Dictionary, origin: Vector3, settlement_name: String = "") -> Node3D:
	if is_instance_valid(active_root):
		active_root.queue_free()
	active_root = Node3D.new()
	active_root.name = "Region_" + str(region.get("name", "مصر"))
	add_child(active_root)
	active_root.position = origin
	active_region_name = settlement_name if not settlement_name.is_empty() else str(region.get("name", "مصر"))
	var zone := str(region.get("zone", "وادي النيل"))
	var settlement_type := str(region.get("settlement_type", "مدينة"))
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(active_region_name.hash())
	var district_size := 210.0
	if settlement_type == "قرية":
		district_size = 135.0
	elif settlement_type == "مركز":
		district_size = 175.0
	var ground_color: Color = Color("#b8a27a")
	if zone == "دلتا النيل":
		ground_color = Color("#71834a")
	elif zone == "الساحل الشمالي" or zone == "الساحل الشمالي والصحراء الغربية" or zone == "البحر الأحمر والصحراء الشرقية":
		ground_color = Color("#d2c19a")
	elif zone == "سيناء" or zone == "الصحراء الغربية":
		ground_color = Color("#c6a06c")
	elif zone == "قناة السويس":
		ground_color = Color("#b9b19b")
	if settlement_type == "قرية":
		ground_color = Color("#71834a") if zone == "دلتا النيل" else Color("#b8a27a")
	elif settlement_type == "مركز":
		ground_color = ground_color.lerp(Color("#b7a48a"), 0.25)
	_box("RegionalGround", Vector3(0,-0.55,0), Vector3(district_size,1,district_size), ground_color, true)
	_box("RegionalMainRoad", Vector3(0,0.02,0), Vector3(10,0.12,district_size - 20.0), Color("#292929"), true)
	_box("RegionalCrossRoad", Vector3(0,0.03,0), Vector3(district_size - 20.0,0.12,9), Color("#292929"), true)
	# أرصفة خرسانية وخطوط طريق متقطعة لقراءة الشارع بشكل أوضح.
	for side in [-1.0, 1.0]:
		_box("MainRoadSidewalk", Vector3(side * 6.4, 0.12, 0.0), Vector3(2.2, 0.28, district_size - 20.0), Color("#bcb6a9"), true)
		_box("CrossRoadSidewalk", Vector3(0.0, 0.13, side * 5.8), Vector3(district_size - 20.0, 0.28, 1.7), Color("#bcb6a9"), true)
	for mark_index in range(8):
		var mark_z: float = -district_size * 0.38 + float(mark_index) * district_size * 0.105
		_box("RoadCenterMarking", Vector3(0.0, 0.095, mark_z), Vector3(0.18, 0.025, 3.0), Color("#e5d8a7"), false)
	# أعمدة إنارة بسيطة على الأرصفة.
	for side in [-1.0, 1.0]:
		for lamp_index in range(4):
			var lamp_z: float = -district_size * 0.34 + float(lamp_index) * district_size * 0.22
			_cylinder("StreetLampPole", Vector3(side * 7.1, 2.4, lamp_z), 0.09, 4.8, Color("#444744"))
			_box("StreetLampHead", Vector3(side * 7.1, 4.85, lamp_z - 0.18), Vector3(0.65, 0.18, 0.38), Color("#d9d2ad"), false)
	for side in [-1.0, 1.0]:
		for i in range(5 if settlement_type == "قرية" else 7):
			var z := -72.0 + float(i) * 23.0
			if absf(z) < 12.0:
				continue
			_build_house(Vector3(side * (12.0 if settlement_type == "قرية" else 18.0),0,z), rng, zone)
		for i in range(4 if settlement_type == "قرية" else 5):
			var x := -70.0 + float(i) * 35.0
			if absf(x) < 12.0:
				continue
			_build_house(Vector3(x,0,side * (13.0 if settlement_type == "قرية" else 19.0)), rng, zone)
	# لافتة دخول المحافظة
	_box("RegionSign", Vector3(0,4,-(district_size * 0.41)), Vector3(15,4,0.7), Color("#15583d"), false)
	_box("SignPostLeft", Vector3(-6,2,-86), Vector3(0.35,4,0.35), Color("#5e5a50"), false)
	_box("SignPostRight", Vector3(6,2,-86), Vector3(0.35,4,0.35), Color("#5e5a50"), false)
	var label := Label3D.new()
	label.name = "GovernorateName"
	label.text = active_region_name + " - " + settlement_type
	label.position = Vector3(0,4.2,-(district_size * 0.405))
	label.font_size = 64
	label.modulate = Color("#fff4d6")
	label.outline_size = 8
	active_root.add_child(label)
	_add_local_features(zone, rng)
	return active_root

func _build_house(pos: Vector3, rng: RandomNumberGenerator, zone: String) -> void:
	# واجهات متنوعة مستوحاة من العمارة السكنية المصرية؛ تفاصيل مجسمة بدل صندوق واحد.
	var floors: int = rng.randi_range(1, 5 if zone == "القاهرة الكبرى" else 4)
	var width: float = rng.randf_range(7.5, 11.0)
	var depth: float = rng.randf_range(7.0, 10.0)
	var floor_height: float = rng.randf_range(2.8, 3.2)
	var h: float = float(floors) * floor_height
	var wall: Color = Color("#d6c5a5")
	if zone == "دلتا النيل":
		var delta_walls: Array[Color] = [Color("#d7c6a6"), Color("#b9c49a"), Color("#c9b18c"), Color("#c9c3b5")]
		wall = delta_walls[rng.randi_range(0, delta_walls.size() - 1)]
	elif zone == "الساحل الشمالي" or zone == "الساحل الشمالي والصحراء الغربية" or zone == "البحر الأحمر والصحراء الشرقية":
		wall = [Color("#e0d5bd"), Color("#f0e7d5"), Color("#cfc4ae")][rng.randi_range(0, 2)]
	elif zone == "جنوب الصعيد":
		wall = [Color("#d2b18b"), Color("#c69d70"), Color("#e0c39a")][rng.randi_range(0, 2)]
	# جسم المبنى وحافة السطح.
	_box("EgyptianBuilding", pos + Vector3(0.0, h * 0.5, 0.0), Vector3(width, h, depth), wall, true)
	_box("RoofParapet", pos + Vector3(0.0, h + 0.18, 0.0), Vector3(width + 0.25, 0.36, depth + 0.25), wall.darkened(0.08), false)
	# واجهة أمامية: باب، إطار حجري، وشبابيك بإطارات واضحة.
	var front_z: float = -depth * 0.5 - 0.08
	var door_x: float = -width * 0.22
	_box("FrontDoor", pos + Vector3(door_x, 1.05, front_z), Vector3(1.25, 2.1, 0.16), Color("#503326"), false)
	_box("DoorLintel", pos + Vector3(door_x, 2.16, front_z - 0.02), Vector3(1.55, 0.16, 0.22), Color("#e8d9bd"), false)
	var window_columns: int = 2 if width < 9.5 else 3
	for floor_no in range(floors):
		var y: float = 1.15 + float(floor_no) * floor_height
		for window_no in range(window_columns):
			var x: float = -width * 0.5 + width * float(window_no + 1) / float(window_columns + 1)
			if absf(x - door_x) < 1.0 and floor_no == 0:
				continue
			var window_w: float = rng.randf_range(0.95, 1.25)
			_box("WindowRecess", pos + Vector3(x, y, front_z - 0.025), Vector3(window_w + 0.24, 1.28, 0.12), Color("#e9dfcc"), false)
			_box("WindowGlass", pos + Vector3(x, y, front_z - 0.105), Vector3(window_w, 1.02, 0.08), Color("#426579"), false)
			_box("WindowSill", pos + Vector3(x, y - 0.61, front_z - 0.16), Vector3(window_w + 0.28, 0.12, 0.28), Color("#a79a83"), false)
			# فاصل رأسي يوحي بمصراعين زجاجيين.
			_box("WindowMullion", pos + Vector3(x, y, front_z - 0.155), Vector3(0.055, 1.02, 0.045), Color("#c5c0b5"), false)
		# بلكونة متقطعة على بعض الطوابق مع أرضية ودرابزين وأعمدة.
		if floor_no > 0 and rng.randf() > 0.38:
			var balcony_y: float = float(floor_no) * floor_height + 0.28
			var balcony_w: float = rng.randf_range(2.2, 3.6)
			var balcony_x: float = rng.randf_range(-width * 0.2, width * 0.2)
			_box("BalconySlab", pos + Vector3(balcony_x, balcony_y, front_z - 0.65), Vector3(balcony_w, 0.18, 1.15), Color("#a99b84"), false)
			_box("BalconyRailTop", pos + Vector3(balcony_x, balcony_y + 0.92, front_z - 1.15), Vector3(balcony_w, 0.10, 0.10), Color("#4a4c4b"), false)
			_box("BalconyRailBottom", pos + Vector3(balcony_x, balcony_y + 0.18, front_z - 1.15), Vector3(balcony_w, 0.08, 0.10), Color("#4a4c4b"), false)
			for rail_i in range(5):
				var rail_x: float = balcony_x - balcony_w * 0.5 + balcony_w * float(rail_i) / 4.0
				_box("BalconyRail", pos + Vector3(rail_x, balcony_y + 0.53, front_z - 1.15), Vector3(0.055, 0.7, 0.07), Color("#4a4c4b"), false)
	# وحدة تكييف خارجية عشوائية، من التفاصيل الشائعة في الشوارع المصرية.
	if rng.randf() > 0.25:
		var ac_x: float = width * 0.32
		var ac_y: float = rng.randf_range(2.2, maxf(2.3, h - 0.8))
		_box("AirConditioner", pos + Vector3(ac_x, ac_y, front_z - 0.18), Vector3(0.85, 0.48, 0.42), Color("#deded7"), false)
		_box("ACVent", pos + Vector3(ac_x, ac_y, front_z - 0.405), Vector3(0.52, 0.24, 0.04), Color("#777b7b"), false)
	# خزانات مياه ومواسير على السطح.
	_box("RoofWaterTank", pos + Vector3(width * 0.25, h + 0.95, depth * 0.18), Vector3(1.25, 1.6, 1.25), Color("#777d7b"), false)
	_cylinder("RoofPipe", pos + Vector3(-width * 0.3, h + 0.55, depth * 0.2), 0.08, 1.1, Color("#77746b"))
	# بعض المباني بها محل أرضي ومظلة ملونة على الشارع.
	if rng.randf() > 0.58:
		var shop_color: Color = [Color("#d8b66a"), Color("#b84e35"), Color("#347b76"), Color("#d9d0b9")][rng.randi_range(0, 3)]
		_box("ShopFront", pos + Vector3(width * 0.22, 1.25, front_z - 0.12), Vector3(width * 0.42, 1.75, 0.16), Color("#354c53"), false)
		_box("ShopAwning", pos + Vector3(width * 0.22, 2.25, front_z - 0.55), Vector3(width * 0.52, 0.18, 1.0), shop_color, false)
		_box("ShopSignboard", pos + Vector3(width * 0.22, 2.8, front_z - 0.14), Vector3(width * 0.55, 0.48, 0.14), Color("#15583d"), false)
	# شرفة السطح والهوائي.
	if rng.randf() > 0.45:
		_cylinder("RoofAntenna", pos + Vector3(-width * 0.32, h + 1.5, -depth * 0.2), 0.035, 2.4, Color("#5a5b58"))

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
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# سطح خشن للطرق ودهان محارة مصري متآكل للواجهات؛ ألوان المجسمات تظل مؤثرة في النتيجة.
	if label == "EgyptianBuilding":
		var plaster_texture: Texture2D = load("res://assets/textures/egypt_plaster.svg")
		if plaster_texture != null:
			material.albedo_texture = plaster_texture
			material.uv1_scale = Vector3(2.0, 2.0, 1.0)
	elif label == "RegionalMainRoad" or label == "RegionalCrossRoad":
		var asphalt_texture: Texture2D = load("res://assets/textures/asphalt.svg")
		if asphalt_texture != null:
			material.albedo_texture = asphalt_texture
			material.uv1_scale = Vector3(3.0, 3.0, 1.0)
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
