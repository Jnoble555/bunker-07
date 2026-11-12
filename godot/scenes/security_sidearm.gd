extends Node3D
const Model = preload("res://assets/weapons/security_sidearm.glb")
var model: Node3D
var slide: Node3D
var magazine: Node3D
var base: Node3D
var slide_home := Vector3.ZERO
var magazine_home := Vector3.ZERO
var base_home := Vector3.ZERO

func _ready() -> void:
	equip("pistol")

var cached_models: Dictionary = {}
func equip(id: String) -> void:
	if is_instance_valid(model):
		pose(0,0)
		model.hide()
	var fresh := not cached_models.has(id)
	if fresh:
		cached_models[id] = (load("res://assets/weapons/security_"+id+".glb") if id in ["smg","shotgun"] else Model).instantiate()
		add_child(cached_models[id])
	model = cached_models[id]
	model.scale = Vector3.ONE * (0.7 if id == "shotgun" else 0.8 if id == "smg" else 1.0)
	model.show()
	slide = model.find_child("Slide", true, false)
	magazine = model.find_child("Magazine", true, false)
	base = model.find_child("MagazineBase", true, false)
	slide_home = slide.position
	magazine_home = magazine.position
	base_home = base.position
	if fresh: _prepare(model)

func _prepare(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in node.mesh.get_surface_count():
			var material = node.get_active_material(i)
			if material is StandardMaterial3D:
				var copy := material.duplicate() as StandardMaterial3D
				copy.no_depth_test = false
				copy.render_priority = 0
				node.set_surface_override_material(i, copy)
	for child in node.get_children():
		_prepare(child)

func pose(flash: float, reload_left: float, reload_duration: float = 0.8, recoil: float = 1.0) -> void:
	var kick := clampf(flash / 0.1, 0, 1)
	slide.position = slide_home + Vector3(0, 0, kick * 0.035)
	var drop := 0.0
	if reload_left > 0:
		var progress := 1.0 - reload_left / reload_duration
		drop = sin(clampf((progress - 0.12) / 0.76, 0, 1) * PI) * 0.075
	magazine.position = magazine_home + Vector3(-drop * 0.8, -drop, 0)
	base.position = base_home + Vector3(-drop * 0.8, -drop, 0)
	var reload_pose := sin((1.0 - reload_left / reload_duration) * PI) if reload_left > 0 else 0.0
	rotation = Vector3(kick * 0.12 * recoil, 0.5 + reload_pose * 0.3, -reload_pose * 0.4)
