extends Node3D
## Original visual shell; AI owns all timing and damage decisions.

var muzzle: MeshInstance3D
var muzzle_light: OmniLight3D
var status_label: Label3D
var weapon: Node3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var _visor: StandardMaterial3D
var _phase := 0.0

func build(role: String) -> void:
	var armor := _material(Color("4f5d53") if role == "tactical_smg" else Color("657064"), 0.55)
	var dark := _material(Color("18231f"), 0.3)
	var trim := _material(Color("9a875b"), 0.5)
	_visor = _material(Color("7dbca3"), 0.1)
	_visor.emission_enabled = true
	_visor.emission = Color("6a9a82")
	_visor.emission_energy_multiplier = 0.25
	_box("Torso", Vector3(0,1.17,0), Vector3(0.55,0.65,0.32), armor)
	_box("Vest", Vector3(0,1.25,-0.18), Vector3(0.48,0.4,0.1), dark)
	_box("Helmet", Vector3(0,1.67,0), Vector3(0.34,0.34,0.33), armor)
	_box("Visor", Vector3(0,1.67,-0.176), Vector3(0.26,0.1,0.025), _visor)
	_box("RoleStripe", Vector3(-0.3,1.38,0), Vector3(0.06,0.13,0.33), trim)
	left_leg = _box("LeftLeg", Vector3(-0.15,0.44,0), Vector3(0.22,0.82,0.24), dark)
	right_leg = _box("RightLeg", Vector3(0.15,0.44,0), Vector3(0.22,0.82,0.24), dark)
	for side in [-1,1]:
		var arm := _box("Arm", Vector3(side*0.32,1.19,-0.13), Vector3(0.15,0.48,0.18), armor)
		arm.rotation.x = -0.55
	weapon = Node3D.new()
	weapon.position = Vector3(0.18,1.22,-0.26)
	add_child(weapon)
	var packed := load("res://assets/weapons/security_smg.glb") as PackedScene
	if packed:
		var model := packed.instantiate() as Node3D
		model.scale = Vector3(1.0,1.0,1.65) if role == "tactical_rifle" else Vector3.ONE
		weapon.add_child(model)
	var flash := _material(Color("f5c77e"), 0.0)
	flash.emission_enabled = true
	flash.emission = Color("ffc36b")
	flash.emission_energy_multiplier = 2.0
	muzzle = _box("MuzzleFlash", Vector3(0.18,1.245,-0.83 if role == "tactical_rifle" else -0.61), Vector3(0.12,0.10,0.13), flash)
	muzzle.visible = false
	muzzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = muzzle.position
	muzzle_light.light_color = Color("ffd08a")
	muzzle_light.omni_range = 3.5
	muzzle_light.light_energy = 0
	add_child(muzzle_light)
	status_label = Label3D.new()
	status_label.position.y = 2.03
	status_label.font_size = 26
	status_label.pixel_size = 0.003
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.modulate = Color("e5c284")
	status_label.no_depth_test = false
	add_child(status_label)

func animate(delta: float, moving: bool, state: String, preparing: bool, flash_left: float, reload_progress: float) -> void:
	_phase += delta * (8.0 if moving else 0.0)
	left_leg.rotation.x = sin(_phase) * 0.25 if moving else 0.0
	right_leg.rotation.x = -left_leg.rotation.x
	weapon.rotation.x = sin(reload_progress*PI)*0.65 if state == "reload" else flash_left*1.3
	muzzle.visible = flash_left > 0
	muzzle_light.light_energy = 1.2 if flash_left > 0 else 0.0
	status_label.text = "EMPTY" if state == "withdraw" else "RELOADING" if state == "reload" else "READYING" if preparing else "SEARCHING" if state == "search" else "?" if state == "suspicious" else ""
	_visor.emission = Color("e1a55e") if preparing else Color("6a9a82")

func _box(id: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = id
	mesh.position = at
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	add_child(mesh)
	return mesh

func _material(color: Color, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.7
	return material
