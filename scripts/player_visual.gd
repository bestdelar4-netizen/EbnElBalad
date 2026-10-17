
extends Node3D

# ابن البلد المصرية - نموذج ثلاثي الأبعاد
# السكربت يوضع على CharacterVisual داخل Player

const SKIN := Color("#B9794F")
const HAIR := Color("#211B19")
const SHIRT := Color("#D7D0BD")
const PANTS := Color("#303944")
const SHOES := Color("#EEE9DF")
const DARK := Color("#30241F")
const POCKET_COLOR := Color("#B9AF9A")
const BELT_COLOR := Color("#252525")

var body_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var player: CharacterBody3D

var walk_time: float = 0.0


func _ready() -> void:
	player = get_parent() as CharacterBody3D

	if player == null:
		push_warning("CharacterVisual لازم يكون ابن CharacterBody3D")
		return

	build_character()


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if body_root == null:
		return

	var speed := Vector2(
		player.velocity.x,
		player.velocity.z
	).length()

	var moving := speed > 0.15

	if moving:
		var animation_speed := 8.0
		if speed > 6.0:
			animation_speed = 12.0

		walk_time += delta * animation_speed

	var swing := 0.0
	if moving:
		swing = sin(walk_time) * 0.55

	left_leg.rotation.x = swing
	right_leg.rotation.x = -swing

	left_arm.rotation.x = -swing * 0.8
	right_arm.rotation.x = swing * 0.8

	if moving:
		body_root.position.y = (
			0.025 + absf(sin(walk_time * 2.0)) * 0.025
		)
	else:
		body_root.position.y = 0.0


func build_character() -> void:
	if body_root != null:
		body_root.queue_free()

	body_root = Node3D.new()
	body_root.name = "IbnElBaladModel"
	add_child(body_root)

	# الجذع والقميص
	make_capsule(
		body_root, "Torso",
		Vector3(0.0, 1.12, 0.0),
		0.24, 0.72, SHIRT,
		Vector3(1.15, 1.0, 0.85)
	)

	# حزام البنطلون
	make_box(
		body_root, "Belt",
		Vector3(0.0, 0.79, 0.0),
		Vector3(0.40, 0.075, 0.29),
		BELT_COLOR
	)

	# الرقبة
	make_capsule(
		body_root, "Neck",
		Vector3(0.0, 1.59, 0.0),
		0.09, 0.18, SKIN
	)

	# الرأس
	make_sphere(
		body_root, "Head",
		Vector3(0.0, 1.84, 0.0),
		Vector3(0.23, 0.28, 0.21),
		SKIN
	)

	# الشعر
	make_sphere(
		body_root, "Hair",
		Vector3(0.0, 2.025, 0.015),
		Vector3(0.235, 0.115, 0.215),
		HAIR
	)

	# الحاجبان
	make_box(
		body_root, "LeftEyebrow",
		Vector3(-0.08, 1.905, -0.198),
		Vector3(0.065, 0.018, 0.018),
		HAIR
	)

	make_box(
		body_root, "RightEyebrow",
		Vector3(0.08, 1.905, -0.198),
		Vector3(0.065, 0.018, 0.018),
		HAIR
	)

	# العينان
	make_sphere(
		body_root, "LeftEye",
		Vector3(-0.08, 1.86, -0.195),
		Vector3(0.025, 0.025, 0.018),
		DARK
	)

	make_sphere(
		body_root, "RightEye",
		Vector3(0.08, 1.86, -0.195),
		Vector3(0.025, 0.025, 0.018),
		DARK
	)

	# الأنف
	make_sphere(
		body_root, "Nose",
		Vector3(0.0, 1.815, -0.205),
		Vector3(0.04, 0.055, 0.035),
		SKIN.darkened(0.08)
	)

	# الشارب
	make_sphere(
		body_root, "Mustache",
		Vector3(0.0, 1.765, -0.205),
		Vector3(0.085, 0.025, 0.025),
		HAIR
	)

	# الذراعان
	left_arm = make_limb(
		body_root, "LeftArm",
		Vector3(-0.34, 1.43, 0.0),
		0.085, 0.48, SHIRT
	)

	right_arm = make_limb(
		body_root, "RightArm",
		Vector3(0.34, 1.43, 0.0),
		0.085, 0.48, SHIRT
	)

	# اليدان
	make_sphere(
		left_arm, "Hand",
		Vector3(0.0, -0.28, 0.0),
		Vector3(0.075, 0.085, 0.075),
		SKIN
	)

	make_sphere(
		right_arm, "Hand",
		Vector3(0.0, -0.28, 0.0),
		Vector3(0.075, 0.085, 0.075),
		SKIN
	)

	# الرجلان
	left_leg = make_limb(
		body_root, "LeftLeg",
		Vector3(-0.145, 0.78, 0.0),
		0.105, 0.48, PANTS
	)

	right_leg = make_limb(
		body_root, "RightLeg",
		Vector3(0.145, 0.78, 0.0),
		0.105, 0.48, PANTS
	)

	# الحذاء
	make_box(
		left_leg, "LeftShoe",
		Vector3(0.0, -0.255, -0.055),
		Vector3(0.17, 0.09, 0.26),
		SHOES
	)

	make_box(
		right_leg, "RightShoe",
		Vector3(0.0, -0.255, -0.055),
		Vector3(0.17, 0.09, 0.26),
		SHOES
	)

	# جيب القميص
	make_box(
		body_root, "ShirtPocket",
		Vector3(0.18, 1.28, -0.202),
		Vector3(0.07, 0.09, 0.018),
		POCKET_COLOR
	)


func make_limb(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	radius: float,
	height: float,
	color: Color
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = at
	parent.add_child(pivot)

	make_capsule(
		pivot, "Limb",
		Vector3(0.0, -height * 0.5, 0.0),
		radius, height, color
	)

	return pivot


func make_capsule(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	radius: float,
	height: float,
	color: Color,
	stretch: Vector3 = Vector3.ONE
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)

	instance.mesh = mesh
	instance.position = at
	instance.scale = stretch
	instance.material_override = make_material(color)

	parent.add_child(instance)
	return instance


func make_sphere(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	dimensions: Vector3,
	color: Color
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0

	instance.mesh = mesh
	instance.position = at
	instance.scale = dimensions
	instance.material_override = make_material(color)

	parent.add_child(instance)
	return instance


func make_box(
	parent: Node3D,
	node_name: String,
	at: Vector3,
	dimensions: Vector3,
	color: Color
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name

	var mesh := BoxMesh.new()
	mesh.size = dimensions

	instance.mesh = mesh
	instance.position = at
	instance.material_override = make_material(color)

	parent.add_child(instance)
	return instance


func make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
