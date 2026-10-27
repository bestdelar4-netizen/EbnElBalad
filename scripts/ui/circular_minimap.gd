extends Control

signal destination_selected(world_position: Vector3)

var player: Node3D
var expanded: bool = false
var has_destination: bool = false
var destination: Vector2 = Vector2.ZERO
var map_range: float = 90.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.46
	draw_circle(center, radius + 4.0, Color(0.05, 0.06, 0.06, 0.9))
	draw_circle(center, radius, Color("#25302f"))
	# شبكة شوارع مبسطة داخل الدائرة، كل خطوطها محصورة داخل حدود الخريطة.
	for road_index in range(-3, 4):
		var offset: float = float(road_index) * radius * 0.25
		var half_chord: float = sqrt(maxf(0.0, radius * radius - offset * offset))
		draw_line(center + Vector2(-half_chord, offset), center + Vector2(half_chord, offset), Color("#9a9483"), maxf(2.0, radius * 0.035), true)
		draw_line(center + Vector2(offset, -half_chord), center + Vector2(offset, half_chord), Color("#9a9483"), maxf(2.0, radius * 0.035), true)
	# طريق رئيسي أعرض مع شوارع جانبية.
	draw_line(center + Vector2(-radius * 0.82, radius * 0.18), center + Vector2(radius * 0.82, -radius * 0.18), Color("#d0b88b"), maxf(3.0, radius * 0.055), true)
	draw_arc(center, radius, 0.0, TAU, 64, Color("#d7c9a9"), 3.0, true)
	# منزل أخضر كعلامة لنقطة البداية.
	var home := center + Vector2(-radius * 0.35, -radius * 0.42)
	draw_colored_polygon(PackedVector2Array([home + Vector2(-7, 0), home, home + Vector2(7, 0), home + Vector2(7, 9), home + Vector2(-7, 9)]), Color("#62d15d"))
	draw_colored_polygon(PackedVector2Array([home + Vector2(-9, 1), home + Vector2(0, -8), home + Vector2(9, 1)]), Color("#3ca94a"))
	# سهم اللاعب.
	draw_circle(center, maxf(4.0, radius * 0.065), Color("#53c8f4"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius * 0.16), center + Vector2(-radius * 0.08, radius * 0.08), center + Vector2(radius * 0.08, radius * 0.08)]), Color("#f8f1dc"))
	if has_destination:
		var marker := center + destination
		draw_circle(marker, maxf(5.0, radius * 0.06), Color("#ffbd4a"))
		draw_arc(marker, maxf(8.0, radius * 0.11), 0.0, TAU, 32, Color("#ffbd4a"), 2.0, true)
	if expanded:
		draw_string(ThemeDB.fallback_font, Vector2(12.0, 22.0), "خريطة المدينة", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color("#ffffff"))
		draw_string(ThemeDB.fallback_font, Vector2(12.0, size.y - 12.0), "اضغط لتحديد وجهتك", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("#f3e4c6"))


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var pointer := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		pointer = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
		pointer = event.position
	if not pressed:
		return

	if not expanded:
		expanded = true
		size = Vector2(320.0, 320.0)
		position = Vector2(20.0, 20.0)
		map_range = 180.0
	else:
		var center := size * 0.5
		var radius: float = minf(size.x, size.y) * 0.46
		var relative := pointer - center
		if relative.length() <= radius:
			destination = relative
			has_destination = true
			if is_instance_valid(player):
				var target := player.global_position + Vector3(relative.x / radius * map_range, 0.0, relative.y / radius * map_range)
				destination_selected.emit(target)
		else:
			expanded = false
			size = Vector2(178.0, 178.0)
			position = Vector2(18.0, 18.0)
	queue_redraw()
	accept_event()
