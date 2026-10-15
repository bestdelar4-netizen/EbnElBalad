
extends CharacterBody3D

signal interact_requested

const WALK_SPEED: float = 5.0
const RUN_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.5
const LOOK_SENSITIVITY: float = 0.005

@onready var camera_pivot: Node3D = $CameraPivot

var joystick: Control = null
var running: bool = false
var jump_requested: bool = false


func _ready() -> void:
	joystick = get_tree().get_first_node_in_group(
		"virtual_joystick"
	) as Control


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir: Vector2 = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if is_instance_valid(joystick):
		var output_value: Variant = joystick.get("output")

		if output_value is Vector2:
			var stick_value: Vector2 = output_value

			if stick_value.length() > 0.12:
				input_dir = stick_value

	var forward: Vector3 = -camera_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right: Vector3 = camera_pivot.global_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction: Vector3 = right * input_dir.x - forward * input_dir.y

	if direction.length_squared() > 0.001:
		direction = direction.normalized()

		var speed: float = RUN_SPEED if running else WALK_SPEED

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			WALK_SPEED * 2.0 * delta
		)

		velocity.z = move_toward(
			velocity.z,
			0.0,
			WALK_SPEED * 2.0 * delta
		)

	if (
		(jump_requested or Input.is_action_just_pressed("ui_accept"))
		and is_on_floor()
	):
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
	camera_pivot.rotate_y(-motion.x * LOOK_SENSITIVITY)

	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - motion.y * LOOK_SENSITIVITY,
		deg_to_rad(-45.0),
		deg_to_rad(25.0)
	)


func request_jump() -> void:
	jump_requested = true


func set_running(value: bool) -> void:
	running = value


func interact() -> void:
	interact_requested.emit()
