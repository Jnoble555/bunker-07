"""Original modular bunker trim kit. Blender --background --python this_file."""
from pathlib import Path
import bpy

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'godot/assets/control-room'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color, metal, rough):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Metallic'].default_value = metal
    shader.inputs['Roughness'].default_value = rough
    return m

paint = material('BENCH_ENAMEL', (.13, .20, .24), .12, .48)
metal = material('BENCH_METAL', (.27, .31, .33), .8, .36)
dark = material('BENCH_RUBBER', (.025, .033, .038), 0, .8)
ivory = material('BENCH_IVORY', (.50, .53, .49), .08, .6)
amber = material('BENCH_AMBER', (.65, .36, .10), .1, .5)
lens = material('BENCH_LENS', (.67, .84, .88), 0, .3)

def module(name):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    return obj

def box(parent, name, at, size, mat, bevel=.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new('Manufactured edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 3
        obj.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')
    obj.parent = parent
    return obj

# Blender Z-up; local -Y faces into the room (Godot +Z after glTF export).
p = module('WallPanel')
box(p, 'Service panel', (0, -.012, 1.10), (1.88, .025, 1.40), paint)
box(p, 'Upper acoustic panel', (0, -.010, 2.29), (1.88, .022, .78), ivory)
for side in [-1, 1]:
    box(p, 'Vertical joint', (side*.966, -.013, 1.5), (.036, .028, 2.91), metal)
for z in [.20, 1.82, 2.78]:
    box(p, 'Horizontal extrusion', (0, -.020, z), (1.94, .04, .045), metal)
box(p, 'Kick plate', (0, -.014, .17), (1.91, .03, .20), dark)
box(p, 'Amber identification strip', (.60, -.028, 1.66), (.33, .008, .026), amber, .002)
for sx in [-.84, .84]:
    for z in [.49, 1.70, 1.97, 2.61]:
        box(p, 'Captive fastener', (sx, -.030, z), (.027, .01, .027), metal, .005)

p = module('VentPanel')
box(p, 'Vent recess', (0, -.035, 2.25), (1.10, .04, .38), dark)
for i in range(7):
    box(p, 'Louver', (0, -.062, 2.10+i*.047), (1.04, .023, .016), metal, .003)

p = module('CeilingTray')
for sx in [-.46, .46]:
    box(p, 'Tray rail', (sx, 0, 2.84), (.035, 1.92, .10), metal)
for z in [.0]:
    for sy in [-.85, -.42, 0, .42, .85]:
        box(p, 'Tray crossbar', (0, sy, 2.84), (.93, .035, .025), metal)
for sx in [-.28, -.12, .08, .25]:
    box(p, 'Cable run', (sx, 0, 2.85), (.055, 1.92, .04), dark)

p = module('PracticalLamp')
box(p, 'Luminaire housing', (0, 0, 2.86), (.94, .37, .12), paint)
box(p, 'Diffuser', (0, 0, 2.792), (.77, .25, .023), lens)
for sx in [-.43, .43]:
    box(p, 'Protective cap', (sx, 0, 2.81), (.06, .38, .08), metal)

bpy.ops.wm.save_as_mainfile(filepath=str(Path(__file__).with_name('control_room_kit.blend')))
bpy.ops.export_scene.gltf(filepath=str(OUT/'control_room_kit.glb'), export_format='GLB', export_apply=True)
print('Exported original editable Control Room kit')
