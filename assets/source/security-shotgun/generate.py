"""Original Bunker 07 detachable-magazine shotgun. Run with Blender --background --python."""
import bpy
import math
from pathlib import Path

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.preferences.filepaths.save_version = 0

def material(name, color, metallic, roughness=.58):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return result

steel = material("Shotgun graphite steel", (.055, .075, .065), .7)
polymer = material("Shotgun dark polymer", (.012, .018, .014), .05, .74)
trim = material("Shotgun machined edges", (.16, .19, .17), .7)
amber = material("Shotgun restrained amber", (.48, .28, .07), .25)
bore = material("Shotgun bore", (.004, .006, .005), .1, .9)

def finish(obj, name, mat, bevel=.004):
    obj.name = name
    obj.data.materials.append(mat)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("Manufactured bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj

def box(name, at, size, mat):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.dimensions = size
    return finish(obj, name, mat)

def cylinder(name, at, radius, depth, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=radius, depth=depth, location=at, rotation=(math.pi / 2, 0, 0))
    return finish(bpy.context.object, name, mat, .002)

# Blender +Y maps to Godot -Z; +Z is up before GLB export.
box("Receiver", (0, -.015, .025), (.10, .29, .095), steel)
cylinder("Barrel", (0, .235, .052), .026, .25, steel)
cylinder("Bore", (0, .362, .052), .019, .004, bore)
cylinder("LowerTube", (0, .235, -.012), .018, .22, trim)
pump = box("Slide", (0, .17, -.025), (.09, .16, .07), polymer)
box("Magazine", (0, .015, -.09), (.064, .095, .09), trim)
box("MagazineBase", (0, .015, -.145), (.078, .11, .02), polymer)
box("Grip", (0, -.105, -.095), (.07, .085, .155), polymer)
box("TriggerGuard", (0, -.025, -.066), (.025, .10, .015), steel)
box("TriggerGuardFront", (0, .025, -.037), (.025, .015, .06), steel)
box("Trigger", (0, -.015, -.025), (.012, .015, .03), polymer)
box("Stock", (0, -.245, -.025), (.072, .19, .055), steel)
box("StockPad", (0, -.345, -.062), (.10, .025, .13), polymer)
box("RearSight", (0, -.10, .091), (.06, .03, .018), polymer)
box("FrontSight", (0, .30, .085), (.012, .018, .02), amber)
box("IdentificationBand", (.054, -.045, .045), (.008, .055, .012), amber)
bpy.context.view_layer.update()
for side in (-1, 1):
    for index in range(6):
        rib = box("PumpRib_%d_%d" % (side, index), (side * .047, .108 + index * .024, -.025), (.006, .006, .055), trim)
        rib.parent = pump
        rib.matrix_parent_inverse = pump.matrix_world.inverted()
root = Path(__file__).resolve().parents[3]
bpy.ops.wm.save_as_mainfile(filepath=str(root / "assets/source/security-shotgun/security_shotgun.blend"))
bpy.ops.export_scene.gltf(filepath=str(root / "godot/assets/weapons/security_shotgun.glb"), export_format="GLB", export_apply=True)
