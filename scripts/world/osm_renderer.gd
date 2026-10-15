
extends Node3D

const ROAD_HEIGHT := 0.06
const ROAD_WIDTH := 5.0
const METERS_PER_DEGREE_LAT := 111320.0

var map_origin_lat: float = 30.045
var map_origin_lon: float = 31.225


func set_map_origin(latitude: float, longitude: float) -> void:
	map_origin_lat = latitude
	map_origin_lon = longitude


func create_road(
		points: PackedVector3Array,
		width: float = ROAD_WIDTH
) -> MeshInstance3D:
	if points.size() < 2:
		return null

	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()

	for i in range(points.size()):
		var direction: Vector3

		if i == 0:
			direction = points[1] - points[0]
		elif i == points.size() - 1:
			direction = points[i] - points[i - 1]
		else:
			direction = points[i + 1] - points[i - 1]

		direction.y = 0.0

		if direction.length_squared() < 0.0001:
			continue

		direction = direction.normalized()
		var side := Vector3(-direction.z, 0.0, direction.x)
		var half_width := width * 0.5

		vertices.append(
			points[i] + side * half_width
		)
		vertices.append(
			points[i] - side * half_width
		)

	for i in range(vertices.size() / 2 - 1):
		var base := i * 2
		indices.append_array(
			PackedInt32Array([
				base, base + 2, base + 1,
				base + 1, base + 2, base + 3
			])
		)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		arrays
	)

	var road := MeshInstance3D.new()
	road.mesh = mesh
	road.position.y = ROAD_HEIGHT

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.16, 0.16)
	material.roughness = 0.95
	road.material_override = material

	add_child(road)
	return road


func geographic_to_local(
		latitude: float,
		longitude: float
) -> Vector3:
	var latitude_difference := latitude - map_origin_lat
	var longitude_difference := longitude - map_origin_lon

	var z := -latitude_difference * METERS_PER_DEGREE_LAT
	var x := (
		longitude_difference
		* METERS_PER_DEGREE_LAT
		* cos(deg_to_rad(map_origin_lat))
	)

	return Vector3(x, 0.0, z)
