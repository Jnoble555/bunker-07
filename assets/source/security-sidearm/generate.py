import bpy, math, os
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
def mat(name, rgb, metal):
 m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
 p=m.node_tree.nodes.get("Principled BSDF"); p.inputs['Base Color'].default_value=(*rgb,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=.57
 return m
steel=mat('Bunker graphite steel',(.055,.075,.065),.7)
grip=mat('Dark polymer',(.012,.018,.014),.05)
trim=mat('Machined edges',(.16,.19,.17),.7)
amber=mat('Muted amber identification',(.55,.32,.09),.25)
def box(name,loc,size,material):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=name; o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(material)
 b=o.modifiers.new('Machined bevel','BEVEL'); b.width=.006; b.segments=3
 o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return o
# Blender Y points down the bore; GLB converts this to Godot -Z.
box('Frame',(0,0,0),(.085,.25,.055),steel)
box('Slide',(0,.015,.057),(.08,.29,.065),steel)
box('Barrel',(0,.17,.055),(.046,.055,.042),trim)
box('Bore',(0,.199,.055),(.026,.004,.023),grip)
box('Grip',(0,-.085,-.09),(.068,.09,.15),grip)
box('Magazine',(0,-.085,-.15),(.055,.073,.065),trim)
box('MagazineBase',(0,-.085,-.185),(.075,.095,.018),grip)
box('RearSight',(0,-.105,.098),(.065,.025,.018),grip)
box('FrontSight',(0,.13,.098),(.012,.02,.018),amber)
box('Safety',(.045,-.065,.025),(.008,.034,.015),amber)
for i in range(6):
 box('SlideSerration_%d'%i,(.043,-.10+i*.014,.06),(.006,.005,.045),trim)
for i in range(5):
 box('GripRib_%d'%i,(.036,-.085,-.04-i*.025),(.005,.075,.006),steel)
box('TriggerGuardLower',(0,.005,-.065),(.025,.105,.014),steel)
box('TriggerGuardFront',(0,.055,-.03),(.025,.014,.07),steel)
box('Trigger',(0,.01,-.025),(.012,.015,.035),grip)
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'../../..'))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root,'assets/source/security-sidearm/security_sidearm.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(root,'godot/assets/weapons/security_sidearm.glb'),export_format='GLB',export_apply=True)
