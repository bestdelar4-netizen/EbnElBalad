
extends Node3D
class_name WorldManager

## مدير المناطق في لعبة ابن البلد المصرية.
## كل منطقة عبارة عن مشهد ثلاثي الأبعاد مستقل.

@export var world_root: Node3D
@export var load_radius: float = 180.0

var loaded_regions: Dictionary = {}


func _ready() -> void:
    if world_root == null:
        world_root = self


func load_region(region_id: String, scene: PackedScene,
        region_position: Vector3) -> Node3D:
    if loaded_regions.has(region_id):
        return loaded_regions[region_id]

    if scene == null:
        push_warning("مشهد المنطقة غير متوفر: " + region_id)
        return null

    var region := scene.instantiate() as Node3D
    if region == null:
        push_warning("مشهد المنطقة لازم يكون من نوع Node3D")
        return null

    region.name = region_id
    region.position = region_position
    world_root.add_child(region)
    loaded_regions[region_id] = region

    print("تم تحميل المنطقة: ", region_id)
    return region


func unload_region(region_id: String) -> void:
    if not loaded_regions.has(region_id):
        return

    var region: Node3D = loaded_regions[region_id]
    loaded_regions.erase(region_id)
    region.queue_free()
    print("تم إلغاء تحميل المنطقة: ", region_id)


func unload_regions_far_from(player_position: Vector3) -> void:
    for region_id in loaded_regions.keys():
        var region: Node3D = loaded_regions[region_id]
        if region.global_position.distance_to(player_position) > load_radius:
            unload_region(region_id)
