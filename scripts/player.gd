extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const LOOK_SENSITIVITY: float = 0.005

@onready var camera_pivot: Node3D = $CameraPivot

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta

    var input_dir: Vector2 = Input.get_vector(
        "ui_left",
        "ui_right",
        "ui_up",
        "ui_down"
    )

    var forward := -camera_pivot.global_basis.z
    forward.y = 0.0
    forward = forward.normalized()

    var right := camera_pivot.global_basis.x
    right.y = 0.0
    right = right.normalized()

    var direction := (
        right * input_dir.x
        - forward * input_dir.y
    )

    if direction.length_squared() > 0.001:
        direction = direction.normalized()
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(
            velocity.x, 0.0, SPEED * 2.0 * delta
        )
        velocity.z = move_toward(
            velocity.z, 0.0, SPEED * 2.0 * delta
        )

    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        var screen_width := get_viewport().get_visible_rect().size.x

        if event.position.x > screen_width * 0.4:
            rotate_camera(event.relative)

    elif event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
            rotate_camera(event.relative)

func rotate_camera(relative_motion: Vector2) -> void:
    camera_pivot.rotate_y(
        -relative_motion.x * LOOK_SENSITIVITY
    )

    camera_pivot.rotation.x = clampf(
        camera_pivot.rotation.x
        - relative_motion.y * LOOK_SENSITIVITY,
        deg_to_rad(-45.0),
        deg_to_rad(25.0)
    )