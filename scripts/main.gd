var player_reference: CharacterBody3D

func _ready() -> void:
    create_environment()
    create_street()
    create_player()
    create_mobile_controls()
    print("ابن البلد المصرية جاهزة!")

func create_player() -> void:
    player_reference = PLAYER_SCENE.instantiate() as CharacterBody3D

    if player_reference == null:
        push_error("تعذر إنشاء اللاعب")
        return

    player_reference.name = "Player"
    player_reference.position = Vector3(0, 0.1, 5)
    add_child(player_reference)

func create_mobile_controls() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "TouchControls"
    add_child(canvas)

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    canvas.add_child(root)

    # عصا التحكم المتحركة أسفل اليسار
    var joystick := Control.new()
    joystick.name = "VirtualJoystick"
    joystick.set_script(
        preload("res://scripts/virtual_joystick.gd")
    )
    joystick.add_to_group("virtual_joystick")
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.offset_left = 25
    joystick.offset_top = -210
    joystick.offset_right = 205
    joystick.offset_bottom = -30
    root.add_child(joystick)

    # أزرار الجهة اليمنى
    make_action_button(
        root, "قفز", -125, -115, "jump"
    )
    make_action_button(
        root, "جري", -230, -115, "run"
    )
    make_action_button(
        root, "تفاعل", -125, -220, "interact"
    )

func make_action_button(
    root: Control,
    label: String,
    left_offset: float,
    top_offset: float,
    action_type: String
) -> void:
    var button := Button.new()
    button.text = label
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)

    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    button.offset_left = left_offset
    button.offset_top = top_offset
    button.offset_right = left_offset + 90
    button.offset_bottom = top_offset + 75
    root.add_child(button)

    if action_type == "jump":
        button.button_down.connect(
            _jump_pressed
        )
    elif action_type == "run":
        button.button_down.connect(
            _run_pressed
        )
        button.button_up.connect(
            _run_released
        )
    elif action_type == "interact":
        button.pressed.connect(
            _interact_pressed
        )

func _jump_pressed() -> void:
    if player_reference != null:
        Input.action_press("ui_accept")
        Input.action_release("ui_accept")

func _run_pressed() -> void:
    if player_reference != null:
        player_reference.set_running(true)

func _run_released() -> void:
    if player_reference != null:
        player_reference.set_running(false)

func _interact_pressed() -> void:
    if player_reference != null:
        player_reference.interact()