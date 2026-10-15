extends Control

var output: Vector2 = Vector2.ZERO
var knob_position: Vector2 = Vector2.ZERO
var active_touch: bool = false
var touch_index: int = -1
var mouse_active: bool = false

const DEADZONE: float = 0.12

func _ready() -> void:
    custom_minimum_size = Vector2(180, 180)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _draw() -> void:
    var center := size / 2.0
    var radius := minf(size.x, size.y) * 0.43

    draw_circle(
        center,
        radius,
        Color(0.08, 0.10, 0.13, 0.55)
    )

    draw_arc(
        center,
        radius,
        0.0,
        TAU,
        64,
        Color(0.85, 0.88, 0.95, 0.85),
        3.0,
        true
    )

    var knob_radius := radius * 0.43
    var knob_center := center + knob_position * radius

    draw_circle(
        knob_center,
        knob_radius,
        Color(0.12, 0.48, 0.85, 0.9)
    )

    draw_arc(
        knob_center,
        knob_radius,
        0.0,
        TAU,
        48,
        Color(1, 1, 1, 0.95),
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
    var center := size / 2.0
    var radius := minf(size.x, size.y) * 0.43
    var delta_position := position - center

    if radius <= 0.0:
        return

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