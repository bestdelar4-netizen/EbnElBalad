
extends Control

const DEADZONE: float = 0.12
const STICK_RADIUS_RATIO: float = 0.43

var output: Vector2 = Vector2.ZERO
var knob_position: Vector2 = Vector2.ZERO

var active_touch: bool = false
var touch_index: int = -1
var mouse_active: bool = false


func _ready() -> void:
	name = "VirtualJoystick"
	add_to_group("virtual_joystick")

	custom_minimum_size = Vector2(150.0, 150.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) * STICK_RADIUS_RATIO

	draw_circle(
		center,
		radius,
		Color(0.06, 0.08, 0.11, 0.72)
	)

	draw_arc(
		center,
		radius,
		0.0,
		TAU,
		64,
		Color(0.85, 0.88, 0.95, 0.9),
		3.0,
		true
	)

	var knob_radius: float = radius * 0.43
	var knob_center: Vector2 = center + knob_position * radius

	draw_circle(
		knob_center,
		knob_radius,
		Color(0.12, 0.48, 0.85, 0.95)
	)

	draw_arc(
		knob_center,
		knob_radius,
		0.0,
		TAU,
		48,
		Color.WHITE,
		2.0,
		true
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active_touch:
			active_touch = true
			touch_index = event.index
			update_stick(event.position)
			accept_event()

		elif not event.pressed and event.index == touch_index:
			release_stick()
			accept_event()

	elif event is InputEventScreenDrag:
		if active_touch and event.index == touch_index:
			update_stick(event.position)
			accept_event()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_active = event.pressed

			if mouse_active:
				update_stick(event.position)
			else:
				release_stick()

			accept_event()

	elif event is InputEventMouseMotion and mouse_active:
		update_stick(event.position)
		accept_event()


func update_stick(position: Vector2) -> void:
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) * STICK_RADIUS_RATIO

	if radius <= 0.0:
		return

	var delta_position: Vector2 = position - center
	knob_position = delta_position / radius

	if knob_position.length() > 1.0:
		knob_position = knob_position.normalized()

	output = knob_position

	if output.length() < DEADZONE:
		output = Vector2.ZERO

	queue_redraw()


func release_stick() -> void:
	active_touch = false
	touch_index = -1
	mouse_active = false
	output = Vector2.ZERO
	knob_position = Vector2.ZERO
	queue_redraw()
