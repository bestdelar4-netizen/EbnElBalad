import bpy
from pathlib import Path

ROOT = Path.cwd()
OUTPUT = ROOT / "build" / "XBot_Animated.glb"

fbx_files = sorted(ROOT.rglob("*.fbx"))
characters = [p for p in fbx_files if p.name.lower() == "x bot.fbx"]
if not characters:
    raise RuntimeError("Could not find X Bot.fbx in the repository.")
character_file = characters[0]
animation_files = [p for p in fbx_files if p.resolve() != character_file.resolve()]
if not animation_files:
    raise RuntimeError("No animation FBX files found.")

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)

bpy.ops.import_scene.fbx(filepath=str(character_file))
character_objects = list(bpy.context.scene.objects)
rigs = [obj for obj in character_objects if obj.type == "ARMATURE"]
if not rigs:
    raise RuntimeError("X Bot import did not contain an armature.")
main_rig = rigs[0]
main_bones = set(main_rig.data.bones.keys())
if not main_bones:
    raise RuntimeError("X Bot armature has no bones.")

usable_actions = []
used_names = set()
for fbx in animation_files:
    objects_before = set(bpy.context.scene.objects)
    actions_before = set(bpy.data.actions)
    try:
        bpy.ops.import_scene.fbx(filepath=str(fbx))
    except Exception as exc:
        print(f"SKIP {fbx.name}: import error: {exc}")
        continue

    new_objects = [o for o in bpy.context.scene.objects if o not in objects_before]
    new_rigs = [o for o in new_objects if o.type == "ARMATURE"]
    new_actions = [a for a in bpy.data.actions if a not in actions_before]
    compatible = False
    for rig in new_rigs:
        common = main_bones.intersection(set(rig.data.bones.keys()))
        if len(common) >= max(1, int(len(main_bones) * 0.70)):
            compatible = True
            break

    if compatible:
        for action in new_actions:
            if len(action.fcurves) == 0:
                continue
            base = fbx.stem
            name = base
            suffix = 2
            while name in used_names:
                name = f"{base}_{suffix}"
                suffix += 1
            action.name = name
            used_names.add(name)
            usable_actions.append(action)
        print(f"IMPORTED {fbx.name}")
    else:
        print(f"SKIP {fbx.name}: no compatible armature")
        for action in new_actions:
            if action.users == 0:
                bpy.data.actions.remove(action)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in new_objects:
        if obj.name in bpy.data.objects:
            obj.select_set(True)
    bpy.ops.object.delete()

if not usable_actions:
    raise RuntimeError("No compatible animation clips found for X Bot.")

main_rig.animation_data_create()
main_rig.animation_data.action = usable_actions[0]
bpy.ops.object.select_all(action="DESELECT")
for obj in character_objects:
    if obj.name in bpy.data.objects:
        obj.select_set(True)
bpy.context.view_layer.objects.active = main_rig

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
result = bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT),
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_animation_mode="ACTIONS",
)
if "FINISHED" not in result or not OUTPUT.exists():
    raise RuntimeError("GLB export failed.")
print(f"SUCCESS: {OUTPUT}")
print(f"Compatible animation clips: {len(usable_actions)}")
print("Clips: " + ", ".join(a.name for a in usable_actions))
