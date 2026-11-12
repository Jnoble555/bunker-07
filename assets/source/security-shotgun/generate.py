import bpy, os, math
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
def material(name,color,metal):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1)
 m.use_nodes=True; p=m.node_tree.nodes.get("Principled BSDF")
 p.inputs['Base Color'].default_value=(*color,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=.6
 return m
steel=material('Shotgun dark steel',(.055,.075,.065),.7)
grip=material('Shotgun polymer',(.012,.018,.014),.05)
amber=material('Shotgun amber band',(.5,.27,.06),.25)
trim=material('Shotgun machined',(.14,.18,.16),.7)
def box(name,at,size,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at); o=bpy.context.object; o.name=name; o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(mat)
 b=o.modifiers.new('Bevel','BEVEL'); b.width=.005; b.segments=3
 o.modifiers.new('Normals','WEIGHTED_NORMAL')
box('Frame',(0,-.035,.025),(.095,.32,.10),steel)
box('Slide',(0,.22,.02),(.08,.20,.075),grip)
box('Barrel',(0,.34,.065),(.04,.48,.04),trim)
box('Magazine',(0,.29,.005),(.045,.42,.045),steel)
box('MagazineBase',(0,.49,.005),(.06,.035,.055),amber)
box('Grip',(0,-.16,-.055),(.065,.085,.15),grip)
box('Stock',(0,-.34,.015),(.07,.28,.055),steel)
box('StockPad',(0,-.48,-.015),(.10,.035,.14),grip)
box('Sight',(0,.49,.10),(.035,.025,.025),amber)
box('Rail',(0,-.05,.095),(.055,.18,.02),trim)
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'../../..'))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root,'assets/source/security-shotgun/security_shotgun.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(root,'godot/assets/weapons/security_shotgun.glb'),export_format='GLB',export_apply=True)
