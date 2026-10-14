
extends Node3D

func _ready() -> void:
    create_world()
    print("أهلاً بك في لعبة ابن البلد المصرية!")

func create_world() -> void:
    var world := Node3D.new()
    world.name = "EgyptianWorld"
    add_child(world)

    var ground := MeshInstance3D.new()
    ground.name = "Ground"

    var mesh := BoxMesh.new()
    mesh.size = Vector3(40, 0.5, 40)
    ground.mesh = mesh
    ground.position = Vector3(0, -0.25, 0)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.55, 0.48, 0.36)
    ground.material_override = material

    world.add_child(ground)

    var camera := Camera3D.new()
    camera.position = Vector3(10, 10, 14)
    camera.look_at(Vector3.ZERO, Vector3.UP)
    world.add_child(camera)
    camera.current = true

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    world.add_child(light)
