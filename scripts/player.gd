
extends CharacterBody3D

signal interact_requested

const WALK_SPEED: float = 5.0
const RUN_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5
const LOOK_SENSITIVITY: float = 0.005
const CAMERA_MIN_ANGLE: float = -45.0
const CAMERA_MAX_ANGLE: float = 25.0
const INPUT_DEADZONE: float = 0.12

@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot")

var joystick: Control = null
var running: bool = false
var jump_requested: bool = false
var move_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	if camera_pivot == null:
		push_error("CameraPivot غير موجود داخل Player.")
	else:
		var camera := camera_pivot.get_node_or_null("Camera3D") as Camera3D
		if camera == null:
			push_error("Camera3D غير موجود داخل CameraPivot.")
		else:
			camera.current = true

	_find_joystick()


func _find_joystick() -> void:
	joystick = get_tree().get_first_node_in_group(
		"virtual_joystick"
	) as Control

	if not is_instance_valid(joystick):
		push_warning("لم يتم العثور على عصا التحكم الافتراضية.")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if not is_instance_valid(joystick):
		_find_joystick()

	if is_instance_valid(joystick):
		var joystick_output: Variant = joystick.get("output")
		if joystick_output is Vector2:
			var stick_value: Vector2 = joystick_output
			if stick_value.length() > INPUT_DEADZONE:
				input_dir = stick_value

	if camera_pivot != null:
		var forward: Vector3 = -camera_pivot.global_basis.z
		forward.y = 0.0
		forward = forward.normalized()

		var right: Vector3 = camera_pivot.global_basis.x
		right.y = 0.0
		right = right.normalized()

		var direction: Vector3 = (
			right * input_dir.x - forward * input_dir.y
		)

		if direction.length_squared() > 0.001:
			move_direction = direction.normalized()
			var speed: float = RUN_SPEED if running else WALK_SPEED
			velocity.x = move_toward(velocity.x, move_direction.x * speed, 24.0 * delta)
			velocity.z = move_toward(velocity.z, move_direction.z * speed, 24.0 * delta)
			var target_angle: float = atan2(move_direction.x, -move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, minf(1.0, 10.0 * delta))
		else:
			move_direction = Vector3.ZERO
			velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
	else:
		move_direction = Vector3.ZERO
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)

	var wants_to_jump: bool = (
		jump_requested or Input.is_action_just_pressed("ui_accept")
	)

	if wants_to_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY

	jump_requested = false
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var screen_width: float = get_viewport().get_visible_rect().size.x
		if event.position.x > screen_width * 0.4:
			rotate_camera(event.relative)

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			rotate_camera(event.relative)


func rotate_camera(motion: Vector2) -> void:
	if camera_pivot == null:
		return

	camera_pivot.rotate_y(-motion.x * LOOK_SENSITIVITY)

	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - motion.y * LOOK_SENSITIVITY,
		deg_to_rad(CAMERA_MIN_ANGLE),
		deg_to_rad(CAMERA_MAX_ANGLE)
	)


func request_jump() -> void:
	jump_requested = true


func set_running(value: bool) -> void:
	running = value


func interact() -> void:
	interact_requested.emit()
