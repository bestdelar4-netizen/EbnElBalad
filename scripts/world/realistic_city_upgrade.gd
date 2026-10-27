extends Node3D

# إضافات حي مصري أكثر تفصيلاً مع نماذج خفيفة مناسبة للموبايل.
var player: Node3D


func initialize(player_node: Node3D) -> void:
	player = player_node
	create_shop_street()
	create_street_life()
	create_vehicles()
	create_minimap()


func _process(delta: float) -> void:
	# حركة مرورية خفيفة على الشارع؛ تعود المركبات للبداية عند نهاية المسار.
	for item in get_children():
		if item is Node3D and item.has_meta("traffic_speed"):
			item.position.z += float(item.get_meta("traffic_speed")) * delta
			if item.position.z > 100.0:
				item.position.z = 22.0


func material(color: Color, roughness_value: float = 0.88) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness_value
	return result


func box(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	item.mesh = shape
	item.position = pos
	item.material_override = material(color)
	parent.add_child(item)
	return item


func cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, color: Color, horizontal: bool = false) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = node_name
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	item.mesh = shape
	item.position = pos
	if horizontal:
		item.rotation_degrees.z = 90.0
	item.material_override = material(color)
	parent.add_child(item)
	return item


func create_shop_street() -> void:
	var plaster_colors: Array[Color] = [
		Color("#c8b393"), Color("#d7c7aa"), Color("#b7a487"),
		Color("#d5c5a5"), Color("#b9b1a0"), Color("#c7b9a1")
	]
	var sign_colors: Array[Color] = [
		Color("#174d3a"), Color("#8b3027"), Color("#1e4c68"),
		Color("#b28a2d"), Color("#3d4934"), Color("#6b352d")
	]
	var shop_names: Array[String] = [
		"بقالة الحارة", "خضار وفاكهة", "كشري أم سيف", "صيدلية",
		"مخبز بلدي", "حلاقة رجالي", "مفروشات", "قطع غيار"
	]

	# صف محلات وعمارات على جانبي شارع البداية.
	for side in [-1.0, 1.0]:
		for index in range(8):
			var z := 34.0 + float(index) * 10.5
			var x := side * 25.5
			var height := 10.0 + float((index * 3) % 5) * 1.7
			var building := Node3D.new()
			building.name = "EgyptianShopBuilding_%d_%d" % [int(side), index]
			building.position = Vector3(x, 0.0, z)
			add_child(building)
			box(building, "PlasteredBuilding", Vector3(0.0, height * 0.5, 0.0), Vector3(8.6, height, 8.8), plaster_colors[index % plaster_colors.size()])

			var front_x := -side * 4.36
			# محل أرضي بزجاج وباب ولافتة ومظلة قماش.
			box(building, "ShopGlass", Vector3(front_x, 1.45, 0.0), Vector3(0.10, 2.15, 5.6), Color("#426a75"))
			box(building, "ShopDoor", Vector3(front_x - side * 0.07, 1.15, -2.55), Vector3(0.14, 2.3, 1.15), Color("#4a3426"))
			box(building, "ShopSignBoard", Vector3(front_x - side * 0.10, 3.0, 0.0), Vector3(0.22, 0.72, 6.8), sign_colors[index % sign_colors.size()])
			box(building, "StripedAwning", Vector3(front_x - side * 0.45, 2.45, 0.0), Vector3(0.85, 0.18, 7.1), [Color("#b64b36"), Color("#d9c26a"), Color("#28714c")][index % 3])
			# شاشات وأرفف خلف الواجهة.
			for shelf in range(3):
				box(building, "ShopShelf", Vector3(front_x + side * 0.08, 0.65 + float(shelf) * 0.48, -1.45), Vector3(0.08, 0.07, 2.2), Color("#c9b38a"))
			for phone_or_item in range(4):
				box(building, "WindowDisplayItem", Vector3(front_x - side * 0.08, 1.0 + float(phone_or_item % 2) * 0.48, 0.5 + float(phone_or_item) * 0.52), Vector3(0.08, 0.35, 0.28), [Color("#d6b55d"), Color("#507d9b"), Color("#7c9d72"), Color("#d5d5ce")][phone_or_item])

			# شبابيك الأدوار العليا وبلكونات بسيطة ودرابزين.
			for floor_index in range(1, int(height / 3.0)):
				var floor_y := 2.8 + float(floor_index) * 2.65
				for window_z in [-2.35, 0.0, 2.35]:
					box(building, "ApartmentWindow", Vector3(front_x, floor_y, window_z), Vector3(0.12, 1.05, 1.12), Color("#456575"))
					box(building, "WindowFrame", Vector3(front_x - side * 0.08, floor_y, window_z), Vector3(0.10, 1.16, 1.22), Color("#ded2ba"))
				box(building, "BalconySlab", Vector3(front_x - side * 0.55, floor_y - 0.7, 0.0), Vector3(1.1, 0.12, 6.8), Color("#a99a81"))
				box(building, "BalconyRail", Vector3(front_x - side * 1.05, floor_y - 0.22, 0.0), Vector3(0.08, 0.75, 6.8), Color("#383a38"))
				for rail_z in [-2.7, -1.8, -0.9, 0.0, 0.9, 1.8, 2.7]:
					box(building, "BalconyRailBar", Vector3(front_x - side * 1.05, floor_y - 0.22, rail_z), Vector3(0.08, 0.75, 0.045), Color("#383a38"))
				# وحدات تكييف ظاهرة على واجهة بعض الشقق.
				if (floor_index + index) % 2 == 0:
					box(building, "AirConditioner", Vector3(front_x - side * 0.28, floor_y + 0.85, 2.95), Vector3(0.55, 0.38, 0.68), Color("#d4d0c4"))

			# خزان مياه على السطح.
			cylinder(building, "RooftopWaterTank", Vector3(1.8, height + 0.8, -2.2), 0.8, 1.5, Color("#527b8b"))
			# اسم المحل بالعربية على لوحة لافتة عبر Label ثلاثي الأبعاد.
			var label := Label3D.new()
			label.name = "ArabicShopName"
			label.text = shop_names[index]
			label.font_size = 32
			label.pixel_size = 0.009
			label.modulate = Color("#fff1d0")
			label.position = Vector3(front_x - side * 0.16, 3.0, 0.0)
			label.rotation_degrees.y = -90.0 if side < 0.0 else 90.0
			building.add_child(label)

	# مبانٍ سكنية أبعد لإغلاق المنظر وإعطاء عمق للشارع.
	for side in [-1.0, 1.0]:
		for index in range(5):
			var z := 42.0 + float(index) * 16.0
			var x := side * 41.0
			var height := 13.0 + float(index % 3) * 3.0
			box(self, "BackgroundApartment", Vector3(x, height * 0.5, z), Vector3(10.0, height, 11.0), plaster_colors[(index + 2) % plaster_colors.size()])
			for floor_index in range(1, int(height / 3.0)):
				for window_index in range(3):
					box(self, "DistantWindow", Vector3(x - side * 5.08, 2.0 + float(floor_index) * 2.8, z - 3.0 + float(window_index) * 3.0), Vector3(0.08, 1.0, 1.1), Color("#456575"))


func create_street_life() -> void:
	# عربات خضار صغيرة ومقاعد وأكياس وصناديق أمام المحلات.
	for index in range(5):
		var side := -1.0 if index % 2 == 0 else 1.0
		var z := 40.0 + float(index) * 17.0
		var cart := Node3D.new()
		cart.name = "EgyptianStreetVendorCart_%d" % index
		cart.position = Vector3(side * 8.2, 0.0, z)
		add_child(cart)
		box(cart, "CartBase", Vector3(0.0, 0.75, 0.0), Vector3(1.4, 0.7, 1.8), Color("#7a4e2b"))
		box(cart, "CartCanopy", Vector3(0.0, 1.55, 0.0), Vector3(1.8, 0.12, 2.0), [Color("#c64932"), Color("#e0c35a"), Color("#34754b")][index % 3])
		for item_index in range(6):
			var fruit_color: Color = [Color("#b83c2f"), Color("#d8a52d"), Color("#619447"), Color("#e1bd58")][item_index % 4]
			cylinder(cart, "FruitOrVegetable", Vector3(-0.45 + float(item_index % 3) * 0.45, 1.12, -0.5 + float(item_index / 3) * 0.65), 0.16, 0.22, fruit_color)
		for wheel_z in [-0.62, 0.62]:
			cylinder(cart, "CartWheel", Vector3(0.0, 0.3, wheel_z), 0.22, 0.12, Color("#242424"), true)

	# أعمدة إنارة وأسلاك علوية.
	for side in [-1.0, 1.0]:
		for index in range(3):
			var z := 37.0 + float(index) * 28.0
			box(self, "StreetLampPole", Vector3(side * 9.0, 3.1, z), Vector3(0.12, 6.2, 0.12), Color("#42413b"))
			box(self, "StreetLampArm", Vector3(side * 8.4, 6.0, z), Vector3(1.2, 0.12, 0.12), Color("#42413b"))
			box(self, "StreetLamp", Vector3(side * 7.9, 5.9, z), Vector3(0.5, 0.16, 0.28), Color("#e9d7a2"))


func create_vehicles() -> void:
	# سيارات ثابتة على جانب الطريق، بتفاصيل زجاج ومصابيح ومرايا وعجلات.
	create_car(Vector3(-5.4, 0.0, 29.0), Color("#8d3028"), 0.0)
	create_car(Vector3(5.5, 0.0, 51.0), Color("#d4d0c4"), 180.0)
	create_car(Vector3(-5.3, 0.0, 75.0), Color("#315c72"), 0.0)
	create_tuk_tuk_model(Vector3(4.0, 0.0, 37.0), Color("#d7b72c"), Color("#1c5a37"))
	create_tuk_tuk_model(Vector3(-4.1, 0.0, 62.0), Color("#2f5f3b"), Color("#242424"))
	create_motorcycle(Vector3(1.9, 0.0, 24.0), Color("#a72f28"))
	create_motorcycle(Vector3(-2.1, 0.0, 46.0), Color("#222b31"))
	create_motorcycle(Vector3(2.2, 0.0, 68.0), Color("#c3a64b"))


func create_car(pos: Vector3, body_color: Color, heading: float) -> void:
	var car := Node3D.new()
	car.name = "EgyptianStreetCar"
	car.position = pos
	car.rotation_degrees.y = heading
	if pos.z < 35.0:
		car.set_meta("traffic_speed", 1.8)
	add_child(car)
	box(car, "CarLowerBody", Vector3(0.0, 0.68, 0.0), Vector3(1.9, 0.65, 4.0), body_color)
	box(car, "CarHood", Vector3(0.0, 0.95, -1.25), Vector3(1.8, 0.28, 1.3), body_color)
	box(car, "CarCabin", Vector3(0.0, 1.25, 0.35), Vector3(1.55, 0.75, 1.9), Color("#aab9bc"))
	box(car, "FrontWindshield", Vector3(0.0, 1.47, -0.62), Vector3(1.42, 0.48, 0.06), Color("#304b59"))
	box(car, "RearWindshield", Vector3(0.0, 1.47, 1.28), Vector3(1.38, 0.45, 0.06), Color("#304b59"))
	for side in [-1.0, 1.0]:
		for z in [-1.3, 1.3]:
			cylinder(car, "CarTire", Vector3(side * 0.97, 0.43, z), 0.39, 0.22, Color("#171717"), true)
			cylinder(car, "WheelHub", Vector3(side * 1.10, 0.43, z), 0.17, 0.025, Color("#a8a8a0"), true)
		box(car, "Headlight", Vector3(side * 0.58, 0.78, -2.02), Vector3(0.34, 0.2, 0.06), Color("#f5e8bd"))
		box(car, "TailLight", Vector3(side * 0.62, 0.78, 2.02), Vector3(0.3, 0.22, 0.06), Color("#b9322a"))
		box(car, "SideMirror", Vector3(side * 0.92, 1.2, -0.55), Vector3(0.2, 0.14, 0.24), body_color)


func create_tuk_tuk_model(pos: Vector3, body_color: Color, roof_color: Color) -> void:
	var tuk := Node3D.new()
	tuk.name = "DetailedEgyptianTukTuk"
	tuk.position = pos
	if pos.z < 45.0:
		tuk.set_meta("traffic_speed", 1.25)
	add_child(tuk)
	box(tuk, "TukChassis", Vector3(0.0, 0.48, 0.0), Vector3(1.45, 0.24, 2.35), Color("#252525"))
	box(tuk, "TukFrontNose", Vector3(0.0, 0.83, -0.82), Vector3(1.3, 0.62, 0.72), body_color)
	box(tuk, "TukPassengerCabin", Vector3(0.0, 1.05, 0.42), Vector3(1.45, 0.95, 1.25), body_color)
	box(tuk, "TukRoof", Vector3(0.0, 1.82, 0.22), Vector3(1.62, 0.16, 2.05), roof_color)
	box(tuk, "TukWindshield", Vector3(0.0, 1.28, -1.0), Vector3(1.05, 0.58, 0.06), Color("#80aebb"))
	box(tuk, "TukFrontBumper", Vector3(0.0, 0.45, -1.23), Vector3(1.4, 0.13, 0.12), Color("#b8b6aa"))
	for side in [-1.0, 1.0]:
		box(tuk, "TukHeadlight", Vector3(side * 0.48, 0.87, -1.22), Vector3(0.22, 0.2, 0.08), Color("#f2e6bb"))
		for z in [-0.72, 0.8]:
			cylinder(tuk, "TukRearWheel", Vector3(side * 0.76, 0.34, z), 0.31, 0.18, Color("#161616"), true)
	cylinder(tuk, "TukFrontWheel", Vector3(0.0, 0.32, -1.08), 0.29, 0.18, Color("#161616"), true)
	box(tuk, "TukSeat", Vector3(0.0, 1.0, 0.7), Vector3(1.0, 0.24, 0.38), Color("#242424"))


func create_motorcycle(pos: Vector3, bike_color: Color) -> void:
	var bike := Node3D.new()
	bike.name = "EgyptianMotorcycle"
	bike.position = pos
	if pos.z < 30.0:
		bike.set_meta("traffic_speed", 2.2)
	add_child(bike)
	cylinder(bike, "RearWheel", Vector3(0.0, 0.42, 0.9), 0.42, 0.16, Color("#151515"), true)
	cylinder(bike, "FrontWheel", Vector3(0.0, 0.42, -0.9), 0.42, 0.16, Color("#151515"), true)
	box(bike, "MotorcycleFrame", Vector3(0.0, 0.73, 0.0), Vector3(0.18, 0.18, 1.35), Color("#3d3d3a"))
	box(bike, "FuelTank", Vector3(0.0, 0.98, -0.12), Vector3(0.58, 0.38, 0.65), bike_color)
	box(bike, "MotorcycleSeat", Vector3(0.0, 1.02, 0.55), Vector3(0.48, 0.16, 0.6), Color("#222222"))
	box(bike, "HandleBar", Vector3(0.0, 1.18, -0.7), Vector3(0.8, 0.09, 0.1), Color("#444440"))
	cylinder(bike, "HeadLamp", Vector3(0.0, 1.1, -0.83), 0.18, 0.13, Color("#f1e5b8"), true)
	box(bike, "RearMudguard", Vector3(0.0, 0.75, 0.92), Vector3(0.42, 0.12, 0.55), bike_color)


func create_minimap() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CircularCityMapLayer"
	canvas.layer = 8
	add_child(canvas)
	var map := Control.new()
	map.name = "CircularCityMap"
	map.set_script(load("res://scripts/ui/circular_minimap.gd"))
	map.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	map.position = Vector2(18.0, 18.0)
	map.size = Vector2(178.0, 178.0)
	map.set("player", player)
	canvas.add_child(map)
