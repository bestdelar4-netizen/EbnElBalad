
import bpy
import os
from pathlib import Path

ROOT = Path.cwd()
OUTPUT = ROOT / "build" / "XBot_Animated.glb"

# Search the repository for the character and animation files.
fbx_files = list(ROOT.rglob("*.fbx"))

character_files = [
    f for f in fbx_files
    if f.name.lower() == "x bot.fbx"
]

if not character_files:
    raise RuntimeError("Could not find X Bot.fbx in the repository")

character_file = character_files[0]

animation_files = [
    f for f in fbx_files
    if f.resolve() != character_file.resolve()
]

if not animation_files:
    raise RuntimeError("No animation FBX files were found")

# Start with an empty Blender scene.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)

# Import the character.
bpy.ops.import_scene.fbx(filepath=str(character_file))

armatures = [
    obj for obj in bpy.context.scene.objects
    if obj.type == "ARMATURE"
]

if not armatures:
    raise RuntimeError("X Bot has no imported armature")

main_rig = armatures[0]
main_bones = set(main_rig.data.bones.keys())

# Keep the original character objects.
character_objects = list(bpy.context.scene.objects)

merged_actions = []

for fbx in sorted(animation_files):
    bpy.ops.object.select_all(action="DESELECT")

    try:
        bpy.ops.import_scene.fbx(filepath=str(fbx))
    except Exception as exc:
        print(f"SKIPPED {fbx.name}: {exc}")
        continue

    imported_objects = [
        obj for obj in bpy.context.scene.objects
        if obj not in character_objects
    ]

    imported_rigs = [
        obj for obj in imported_objects
        if obj.type == "ARMATURE"
    ]

    imported_actions = [
        action for action in bpy.data.actions
        if action.users == 1
        and action.name not in merged_actions
    ]

    for rig in imported_rigs:
        rig_bones = set(rig.data.bones.keys())

        if not (main_bones & rig_bones):
            print(f"SKIPPED incompatible skeleton: {fbx.name}")
            continue

        if len(main_bones & rig_bones) < len(main_bones) * 0.7:
            print(f"SKIPPED mismatched bones: {fbx.name}")
            continue

        for action in imported_actions:
            if not action.name in merged_actions:
                merged_actions.append(action.name)

    # Remove temporary imported objects, not their actions.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in imported_objects:
        if obj.name in bpy.data.objects:
            obj.select_set(True)

    bpy.ops.object.delete()

# Keep only actions that contain animation curves.
valid_actions = [
    action for action in bpy.data.actions
    if len(action.fcurves) > 0
]

if not valid_actions:
    raise RuntimeError("No usable animation actions were imported")

# Assign animation actions to the original rig.
main_rig.animation_data_create()

for action in valid_actions:
    main_rig.animation_data.action = action
    if hasattr(main_rig.animation_data, "action_slot"):
        slots = getattr(action, "slots", None)
        if slots and len(slots) > 0:
            main_rig.animation_data.action_slot = slots[0]

# Select the character and export all actions.
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
    raise RuntimeError("GLB export failed")

print(f"Exported character: {OUTPUT}")
print(f"Imported actions: {len(valid_actions)}")
