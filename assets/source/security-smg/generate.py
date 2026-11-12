import bpy, os, math
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
def material(name,color,metal):
 m=bpy.data.materials.new(name); m.diffuse_color=(*color,1)
 m.use_nodes=True; p=m.node_tree.nodes.get("Principled BSDF")
 p.inputs['Base Color'].default_value=(*color,1); p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=.6
 return m
steel=material('SMG dark steel',(.055,.075,.065),.7)
grip=material('SMG polymer',(.012,.018,.014),.05)
amber=material('SMG amber band',(.5,.27,.06),.25)
trim=material('SMG machined',(.14,.18,.16),.7)
def box(name,at,size,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at); o=bpy.context.object; o.name=name; o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(mat)
 b=o.modifiers.new('Bevel','BEVEL'); b.width=.005; b.segments=3
 o.modifiers.new('Normals','WEIGHTED_NORMAL')
box('Frame',(0,0,.015),(.10,.34,.085),steel)
box('Slide',(0,.025,.07),(.08,.30,.045),trim)
box('Barrel',(0,.245,.025),(.045,.15,.045),steel)
box('Muzzle',(0,.325,.025),(.06,.025,.06),grip)
box('Grip',(0,-.10,-.08),(.065,.08,.15),grip)
box('Magazine',(0,.035,-.11),(.055,.075,.19),trim)
box('MagazineBase',(0,.035,-.21),(.07,.09,.02),grip)
box('Stock',(0,-.245,.005),(.07,.18,.04),steel)
box('StockPad',(0,-.33,-.025),(.09,.025,.11),grip)
box('FrontGrip',(0,.13,-.065),(.075,.08,.09),grip)
box('AmberBand',(0,.10,.08),(.085,.018,.018),amber)
box('Sight',(0,-.08,.105),(.055,.04,.025),grip)
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'../../..'))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(root,'assets/source/security-smg/security_smg.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(root,'godot/assets/weapons/security_smg.glb'),export_format='GLB',export_apply=True)
