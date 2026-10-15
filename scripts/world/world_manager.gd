
extends Node3D
class_name WorldManager

## مدير العالم المفتوح - ابن البلد المصرية
## متوافق مع Godot 4

@export var player_path: NodePath
@export var load_radius: float = 180.0
@export var unload_radius: float = 230.0
@export var region_size: float = 120.0
@export var max_regions_per_update: int = 2

var player: Node3D
var regions: Dictionary = {}
var region_scenes: Dictionary = {}
var region_root: Node3D
var update_in_progress: bool = false


func _ready() -> void:
    name = "WorldManager"

    region_root = Node3D.new()
    region_root.name = "LoadedRegions"
    add_child(region_root)

    if not player_path.is_empty():
        player = get_node_or_null(player_path) as Node3D

    print("تم تشغيل مدير العالم المفتوح")


func set_player(target: Node3D) -> void:
    player = target


func register_region(region_id: String, scene: PackedScene) -> void:
    if region_id.is_empty():
        push_warning("اسم المنطقة لا يمكن أن يكون فارغًا")
        return

    if scene == null:
        push_warning("مشهد المنطقة غير صالح: " + region_id)
        return

    region_scenes[region_id] = scene


func load_region(
    region_id: String,
    scene: PackedScene,
    world_position: Vector3
) -> Node3D:
    if regions.has(region_id):
        return regions[region_id] as Node3D

    if scene == null:
        push_warning("لا يوجد مشهد لتحميل المنطقة: " + region_id)
        return null

    var instance := scene.instantiate() as Node3D

    if instance == null:
        push_warning("جذر مشهد المنطقة يجب أن يكون Node3D")
        return null

    instance.name = region_id
    region_root.add_child(instance)
    instance.global_position = world_position

    regions[region_id] = instance

    print("تم تحميل المنطقة: ", region_id)
    return instance


func unload_region(region_id: String) -> void:
    if not regions.has(region_id):
        return

    var instance := regions[region_id] as Node3D
    regions.erase(region_id)

    if is_instance_valid(instance):
        instance.queue_free()

    print("تم تفريغ المنطقة: ", region_id)


func unload_distant_regions() -> void:
    if not is_instance_valid(player):
        return

    var player_position: Vector3 = player.global_position
    var ids: Array = regions.keys()

    for region_id in ids:
        if not regions.has(region_id):
            continue

        var instance := regions[region_id] as Node3D

        if not is_instance_valid(instance):
            regions.erase(region_id)
            continue

        var distance: float = instance.global_position.distance_to(
            player_position
        )

        if distance > unload_radius:
            unload_region(str(region_id))


func get_region_id_from_position(world_position: Vector3) -> String:
    var size: float = maxf(region_size, 1.0)

    var region_x: int = int(floor(world_position.x / size))
    var region_z: int = int(floor(world_position.z / size))

    return str(region_x) + "_" + str(region_z)


func get_region_origin(world_position: Vector3) -> Vector3:
    var size: float = maxf(region_size, 1.0)

    var region_x: int = int(floor(world_position.x / size))
    var region_z: int = int(floor(world_position.z / size))

    return Vector3(
        float(region_x) * size,
        0.0,
        float(region_z) * size
    )


func load_registered_region_at(world_position: Vector3) -> Node3D:
    var region_id: String = get_region_id_from_position(world_position)

    if not region_scenes.has(region_id):
        return null

    var scene: PackedScene = region_scenes[region_id] as PackedScene
    var origin: Vector3 = get_region_origin(world_position)

    return load_region(region_id, scene, origin)


func get_loaded_region_count() -> int:
    return regions.size()


func is_region_loaded(region_id: String) -> bool:
    return regions.has(region_id)


func clear_all_regions() -> void:
    for region_id in regions.keys():
        var instance := regions[region_id] as Node3D

        if is_instance_valid(instance):
            instance.queue_free()

    regions.clear()
    print("تم تفريغ جميع المناطق")
