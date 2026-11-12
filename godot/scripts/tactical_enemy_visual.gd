extends Node3D
## Presentation only: behavior and weapon timing live in tactical_enemy.gd.
var flash: MeshInstance3D
var status: StandardMaterial3D
var gun: Node3D
func _ready() -> void:
	status = material(Color("407d85"))
	box(Vector3(.55,.75,.35),Vector3(0,1,0),material(Color("303c43")))
	box(Vector3(.34,.3,.3),Vector3(0,1.57,0),material(Color("607279")))
	box(Vector3(.28,.08,.025),Vector3(0,1.6,-.16),status)
	for x in [-.17,.17]:
		box(Vector3(.19,.65,.22),Vector3(x,.37,0),material(Color("252e35")))
		box(Vector3(.16,.45,.16),Vector3(x*1.9,1,-.1),material(Color("52616a")))
	gun = Node3D.new()
	gun.position = Vector3(.18,1.13,-.25)
	add_child(gun)
	box(Vector3(.13,.15,.5),Vector3.ZERO,material(Color("161d23")),gun)
	box(Vector3(.065,.065,.25),Vector3(0,0,-.36),material(Color("535d65")),gun)
	box(Vector3(.09,.2,.12),Vector3(0,-.13,.05),material(Color("242a30")),gun)
	flash=box(Vector3(.15,.15,.11),Vector3(0,0,-.51),material(Color("ffc469"),true),gun)
	flash.hide()
func configure(role:String) -> void:
	if role=="rifle": gun.scale.z=1.35
func pose(state:String, firing:bool, windup:float, alive:bool) -> void:
	visible=alive
	flash.visible=firing
	status.albedo_color=Color("ff634b") if windup>0 else Color("ffc064") if state in ["suspicious","search","reload"] else Color("407d85")
	gun.rotation.x=-.5 if state=="reload" else -.08 if firing else 0.0
func material(color:Color,emission:bool=false)->StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=.65
	m.emission_enabled=emission
	m.emission=color
	return m
func box(size:Vector3,at:Vector3,m:Material,parent:Node=self)->MeshInstance3D:
	var n:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	n.mesh=mesh
	n.position=at
	n.material_override=m
	parent.add_child(n)
	return n
