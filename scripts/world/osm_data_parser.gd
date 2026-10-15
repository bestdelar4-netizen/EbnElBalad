
extends RefCounted

class_name OSMDataParser


const METERS_PER_DEGREE := 111320.0


static func parse_elements(json_data: Variant) -> Dictionary:
	var result := {
		"roads": [],
		"buildings": [],
		"error": ""
	}

	if not json_data is Dictionary:
		result["error"] = "بيانات الخريطة غير صالحة."
		return result

	var elements: Variant = json_data.get("elements", [])

	if not elements is Array:
		result["error"] = "قائمة عناصر الخريطة غير صالحة."
		return result

	for element in elements:
		if not element is Dictionary:
			continue

		var tags: Dictionary = element.get("tags", {})
		var points: Array = []

		# استخراج إحداثيات الطريق أو المبنى.
		var geometry: Variant = element.get("geometry", [])

		if geometry is Array:
			for node in geometry:
				if not node is Dictionary:
					continue

				if not node.has("lat") or not node.has("lon"):
					continue

				points.append({
					"lat": float(node["lat"]),
					"lon": float(node["lon"])
				})

		if tags.has("highway") and points.size() >= 2:
			result["roads"].append({
				"id": element.get("id", 0),
				"type": str(tags.get("highway", "road")),
				"name": str(tags.get("name", "شارع بدون اسم")),
				"points": points
			})

		elif tags.has("building") and points.size() >= 3:
			result["buildings"].append({
				"id": element.get("id", 0),
				"type": str(tags.get("building", "yes")),
				"name": str(tags.get("name", "مبنى")),
				"points": points
			})

	return result


static func to_local(
		latitude: float,
		longitude: float,
		origin_latitude: float,
		origin_longitude: float
) -> Vector3:
	var x := (
		longitude - origin_longitude
	) * METERS_PER_DEGREE * cos(deg_to_rad(origin_latitude))

	var z := (
		origin_latitude - latitude
	) * METERS_PER_DEGREE

	return Vector3(x, 0.0, z)
