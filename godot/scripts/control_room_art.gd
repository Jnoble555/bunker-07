extends Node3D
## Optional visual layer. Never creates physics bodies or changes mission geometry.
const Kit = preload("res://assets/control-room/control_room_kit.glb")
var _materials: Dictionary = {}
var _replacements: Dictionary = {}
var _prototype: Node3D
var module_count := 0
var _placements: Dictionary = {}

func apply(world: Node3D) -> void:
	var old: Dictionary = world._materials.duplicate()
	_materials = {
		"concrete": _textured("concrete", 0.0, 0.5, 0.75),
		"steel": _textured("enamel", 0.12, 0.7, 0.32),
		"floor": _textured("floor", 0.32, 1.0, 0.3),
		"ceiling": _plain(Color("202a30"), 0.2, 0.75),
		"dark": _plain(Color("111a20"), 0.0, 0.85),
		"trim": _plain(Color("77828a"), 0.8, 0.38),
		"hazard": _plain(Color("ae7e39"), 0.1, 0.65),
		"off": _plain(Color("1d3639"), 0.05, 0.7),
		"cyan": _emitter(Color("83c6cf"), 0.45),
		"amber": _emitter(Color("dfbb81"), 0.65),
		"green": _emitter(Color("83c7ac"), 0.4)
	}
	for id in _materials:
		_replacements[old[id]] = _materials[id]
		world._materials[id] = _materials[id]
	_replace_surfaces(world)
	_prototype = Kit.instantiate()
	if world.mission_id == "tactical-operation":
		_decorate_operation(world)
	else:
		_decorate_control_room(world)
	_flush_modules()
	_prototype.free()
	_prototype = null
	world._apply_service_lighting()
	var environment: Environment = world.get_node("BunkerEnvironment").environment
	environment.ambient_light_color = Color("9eafc0")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var advanced := RenderingServer.get_current_rendering_method() == "forward_plus"
	environment.ssao_enabled = advanced
	environment.ssao_radius = 0.6
	environment.ssao_intensity = 1.4
	# Runtime-generated geometry has no baked GI. No unbaked GI result is claimed.
	# Neutral specular fill; background stays solid. Runtime probes produced a D3D12
	# texture cleanup warning on this GPU, so this milestone uses a reflection sky.
	var sky := Sky.new()
	var fill := ProceduralSkyMaterial.new()
	fill.sky_top_color = Color("536675")
	fill.sky_horizon_color = Color("9daab1")
	fill.ground_bottom_color = Color("10171c")
	fill.ground_horizon_color = Color("67727b")
	fill.sky_energy_multiplier = 0.45
	fill.ground_energy_multiplier = 0.25
	sky.sky_material = fill
	environment.sky = sky
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	if world.mission_id == "control-room":
		_sign("CONTROL  /  07",Vector3(5,2.35,10.06))
		_sign("SERVICE ACCESS",Vector3(7,2.35,14.06))
	for node in world.find_children("*","Label3D",true,false):
		if node.text in ["DIRECT / SECURITY","MAINTENANCE"]: node.hide()
		elif world.mission_id == "tactical-operation":
			node.font_size = mini(node.font_size,34)
			node.pixel_size = minf(node.pixel_size,0.0022)
			node.outline_size = 2

func _decorate_control_room(world: Node3D) -> void:
	for z in world.map_rows.size():
		for x in world.map_rows[z].length():
			if world.map_rows[z][x] != "#": continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not world._open(x+d.x,z+d.y): continue
				var normal := Vector3(d.x,0,d.y)
				var at := Vector3(x*2+1,0,z*2+1)+normal*1.002
				var yaw := atan2(normal.x,normal.z)
				_module("WallPanel",at,yaw)
				if (x+z)%4 == 0: _module("VentPanel",at,yaw)
	for z in range(5,9):
		for x in range(1,9):
			if world._open(x,z):
				_module("CeilingTray",Vector3(x*2+1,0,z*2+1),PI/2 if world._open(x+1,z) else 0.0)
	for light: OmniLight3D in world._practical_lights:
		_module("PracticalLamp",Vector3(light.position.x,0,light.position.z),0.0)
		light.light_color = Color("c5dfe6") if light.position.z < 13 else Color("e2c59e")
		light.set_meta("base_energy",1.8)
		light.shadow_enabled = true
		light.omni_range = 5.5

func _decorate_operation(world: Node3D) -> void:
	for bounds: AABB in world.solids:
		if bounds.size.y < 4.0: continue # Only walls; leave cover and rails untouched.
		var along_x := bounds.size.x > bounds.size.z
		var length: float = bounds.size.x if along_x else bounds.size.z
		for side in [-1,1]:
			for index in int(length/2.0):
				var at := bounds.position+Vector3(1.0+index*2 if along_x else bounds.size.x*0.5,0,bounds.size.z*0.5 if along_x else 1.0+index*2)
				var normal := Vector3(0,0,side) if along_x else Vector3(side,0,0)
				at += normal*((bounds.size.z if along_x else bounds.size.x)*0.5+0.002)
				if at.x < 0.5 or at.x > 49.5 or at.z < 0.5 or at.z > 49.5: continue
				var yaw := atan2(normal.x,normal.z)
				_module("WallPanel",at,yaw)
				if index%4 == 1: _module("VentPanel",at,yaw)
	for node in world.get_children():
		if node is OmniLight3D:
			_module("PracticalLamp",Vector3(node.position.x,2.3,node.position.z),0.0)
			node.light_energy = 4.2
			node.omni_range = 13
			node.shadow_enabled = (is_equal_approx(node.position.x,24) or (node.position.x > 40 and node.position.z < 10))
	for z in range(34,47,2):
		_module("CeilingTray",Vector3(24,2.3,z),0.0)
	# Terminal displays get readable dark surrounds without changing their colliders.
	for node in world.find_children("*","MeshInstance3D",true,false):
		var m := node.material_override as StandardMaterial3D
		if m and m.emission_enabled and m.emission_energy_multiplier > 1.0:
			var toned := m.duplicate() as StandardMaterial3D
			toned.emission_energy_multiplier = 0.25
			node.material_override = toned

func _replace_surfaces(node: Node) -> void:
	if node is MeshInstance3D:
		if _replacements.has(node.material_override): node.material_override = _replacements[node.material_override]
	for child in node.get_children(): _replace_surfaces(child)

func _module(id: String, at: Vector3, yaw: float) -> void:
	if not _placements.has(id): _placements[id] = []
	_placements[id].append(Transform3D(Basis(Vector3.UP,yaw),at))
	module_count += 1

func _flush_modules() -> void:
	# One instanced batch per kit part, instead of thousands of individual draws.
	for id in _placements:
		var source := _prototype.find_child(id,true,false) as Node3D
		assert(source != null,"Missing kit module: "+str(id))
		_skin(source)
		for part: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
			var mesh := part.mesh.duplicate() as Mesh
			for surface in mesh.get_surface_count(): mesh.surface_set_material(surface,part.get_active_material(surface))
			var local := part.transform
			var ancestor := part.get_parent() as Node3D
			while ancestor != source:
				local = ancestor.transform*local
				ancestor = ancestor.get_parent() as Node3D
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.mesh = mesh
			batch.instance_count = _placements[id].size()
			for index in batch.instance_count: batch.set_instance_transform(index,_placements[id][index]*local)
			var instance := MultiMeshInstance3D.new()
			instance.multimesh = batch
			add_child(instance)

func _skin(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(surface)
			if not material: continue
			var replacement: Material
			match material.resource_name:
				"BENCH_ENAMEL": replacement = _materials.steel
				"BENCH_METAL": replacement = _materials.trim
				"BENCH_RUBBER": replacement = _materials.dark
				"BENCH_AMBER": replacement = _materials.hazard
				"BENCH_LENS": replacement = _materials.cyan
				_: replacement = _materials.concrete
			node.set_surface_override_material(surface,replacement)
	for child in node.get_children(): _skin(child)

func _textured(id: String, metallic: float, scale: float, strength: float) -> StandardMaterial3D:
	var m := _plain(Color.WHITE,metallic,1.0)
	m.albedo_texture = load("res://assets/control-room/"+id+"_albedo.png")
	m.normal_enabled = true
	m.normal_texture = load("res://assets/control-room/"+id+"_normal.png")
	m.normal_scale = strength
	m.roughness_texture = load("res://assets/control-room/"+id+"_roughness.png")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE*scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _plain(color: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	return m

func _emitter(color: Color, energy: float) -> StandardMaterial3D:
	var m := _plain(color,0.0,0.45)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func _sign(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 42
	label.pixel_size = 0.0016
	label.outline_size = 0
	label.modulate = Color("d4dbd7")
	add_child(label)
