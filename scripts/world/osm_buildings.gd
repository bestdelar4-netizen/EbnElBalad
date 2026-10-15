
extends Node3D

class_name OSMBuildings


const DEFAULT_HEIGHT := 9.0
const MIN_HEIGHT := 3.0
const MAX_HEIGHT := 60.0
const FLOOR_HEIGHT := 3.2


func create_building(
		points: Array,
		height: float = DEFAULT_HEIGHT,
		building_name: String = "مبنى"
) -> Node3D:
	if points.size() < 3:
		return null

	var polygon := PackedVector2Array()

	for point in points:
		if not point is Vector2:
			continue

		polygon.append(point)

	if polygon.size() < 3:
		return null

	var safe_height := clampf(
		height,
		MIN_HEIGHT,
		MAX_HEIGHT
	)

	var root := Node3D.new()
	root.name = building_name.validate_node_name()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "BuildingMesh"

	var prism := PrismMesh.new()
	prism.size = Vector3(1.0, safe_height, 1.0)
	mesh_instance.mesh = prism

	# شكل مبدئي للمبنى؛ سيتم استبداله بمضلع مطابق
	# لحدود المبنى الحقيقية في الخطوة التالية.
	var bounds := Rect2(polygon[0], Vector2.ZERO)

	for point in polygon:
		bounds = bounds.expand(point)

	mesh_instance.position = Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		safe_height * 0.5,
		bounds.position.y + bounds.size.y * 0.5
	)

	mesh_instance.scale = Vector3(
		maxf(bounds.size.x, 1.0),
		1.0,
		maxf(bounds.size.y, 1.0)
	)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(
		0.72, 0.62, 0.48
	)
	material.roughness = 0.95

	mesh_instance.material_override = material
	root.add_child(mesh_instance)

	var collision := StaticBody3D.new()
	collision.name = "Collision"

	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(
		maxf(bounds.size.x, 1.0),
		safe_height,
		maxf(bounds.size.y, 1.0)
	)

	shape_node.shape = shape
	shape_node.position.y = safe_height * 0.5

	collision.add_child(shape_node)
	root.add_child(collision)

	add_child(root)
	return root


func estimate_height(tags: Dictionary) -> float:
	if tags.has("height"):
		var raw_height := str(tags["height"]).replace("m", "").strip_edges()
		var parsed_height := float(raw_height)

		if parsed_height > 0.0:
			return clampf(
				parsed_height,
				MIN_HEIGHT,
				MAX_HEIGHT
			)

	if tags.has("building:levels"):
		var levels := int(tags["building:levels"])
		return clampf(
			float(levels) * FLOOR_HEIGHT,
			MIN_HEIGHT,
			MAX_HEIGHT
		)

	return DEFAULT_HEIGHT
