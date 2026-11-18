extends Node3D
## Original procedural security-operator presentation. Gameplay collision and AI stay in deep_signal_enemy.gd.
static var _uniform_grain: Texture2D
var flash: MeshInstance3D
var status: StandardMaterial3D
var weapon_mount: Node3D
var radio_indicator: MeshInstance3D
var radio_label: Label3D
var search_label: Label3D
var torso: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var _search_status := ""
var _anim_clock := 0.0

func _ready() -> void:
	var undersuit := material(Color("253036"), 0.05, 0.84)
	var armor := material(Color("485a62"), 0.28, 0.62)
	var armor_edge := material(Color("80918f"), 0.34, 0.5)
	var webbing := material(Color("293235"), 0.02, 0.94)
	var rubber := material(Color("1b2124"), 0.0, 0.92)
	var amber := material(Color("bd8740"), 0.12, 0.58)
	var visor := material(Color("12262b"), 0.42, 0.25)
	var lens := material(Color("73c7c5"), 0.2, 0.26, true)
	status = material(Color("bd8740"), 0.12, 0.6, true)

	# A rounded body and layered plate silhouette fit the existing 1.8 m actor capsule.
	torso = Node3D.new()
	torso.position.y = 0.98
	add_child(torso)
	capsule(0.22, 0.68, Vector3(0, 0.22, 0), undersuit, torso)
	box(Vector3(0.48, 0.36, 0.31), Vector3(0, 0.27, -0.015), armor, torso)
	# Raised plate lips, split chest panels, attachment rails and four readable kit pouches.
	box(Vector3(0.5, 0.28, 0.07), Vector3(0, 0.31, -0.19), armor_edge, torso)
	box(Vector3(0.42, 0.22, 0.065), Vector3(0, 0.31, -0.235), armor, torso)
	box(Vector3(0.022, 0.19, 0.014), Vector3(0, 0.31, -0.273), webbing, torso)
	for x in [-0.145, 0.145]:
		box(Vector3(0.12, 0.105, 0.105), Vector3(x, 0.07, -0.22), webbing, torso)
		box(Vector3(0.105, 0.075, 0.025), Vector3(x, 0.07, -0.278), armor_edge, torso)
		box(Vector3(0.16, 0.036, 0.035), Vector3(x, 0.49, -0.17), amber, torso)
	box(Vector3(0.46, 0.13, 0.32), Vector3(0, -0.12, 0), webbing, torso)
	box(Vector3(0.49, 0.035, 0.34), Vector3(0, -0.19, 0), armor_edge, torso)
	for x in [-0.2, 0.2]:
		box(Vector3(0.1, 0.13, 0.1), Vector3(x, -0.1, -0.19), amber if x < 0 else armor, torso)
	# Neck, helmet shell, brow, sealed faceplate and compact communications gear.
	capsule(0.09, 0.17, Vector3(0, 0.62, 0), webbing, torso)
	sphere(Vector3(0.18, 0.22, 0.17), Vector3(0, 0.77, 0), undersuit, torso)
	sphere(Vector3(0.195, 0.15, 0.19), Vector3(0, 0.82, 0.005), armor, torso)
	box(Vector3(0.33, 0.055, 0.19), Vector3(0, 0.82, -0.095), armor_edge, torso)
	box(Vector3(0.275, 0.105, 0.035), Vector3(0, 0.72, -0.163), visor, torso)
	box(Vector3(0.17, 0.016, 0.013), Vector3(0, 0.725, -0.185), lens, torso)
	for x in [-0.185, 0.185]:
		cylinder(0.054, 0.035, Vector3(x, 0.74, 0), armor_edge, torso)
		cylinder(0.024, 0.04, Vector3(x, 0.74, -0.025), amber if x < 0 else webbing, torso)
	box(Vector3(0.18, 0.065, 0.12), Vector3(0, 0.38, 0.18), webbing, torso)
	box(Vector3(0.13, 0.11, 0.045), Vector3(0, 0.4, 0.245), armor_edge, torso)
	for y in [0.37, 0.41, 0.45]:
		box(Vector3(0.085, 0.012, 0.012), Vector3(0, y, 0.271), amber, torso)
	merge_parts(torso)
	var status_lamp := sphere(Vector3(0.045, 0.045, 0.018), Vector3(0, 0.43, -0.286), status, torso)
	status_lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Paired shoulder shells, articulated upper arms, elbow joints and forearm armor.
	for side in [-1, 1]:
		var shoulder := Vector3(side * 0.29, 0.48, -0.015)
		sphere(Vector3(0.15, 0.16, 0.16), shoulder, armor_edge, torso)
		box(Vector3(0.16, 0.07, 0.12), shoulder + Vector3(0, 0.015, -0.112), armor, torso)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.3, 1.42, -0.02)
		add_child(arm)
		capsule(0.105, 0.34, Vector3(side * 0.015, -0.11, 0.01), undersuit, arm, Vector3(1, 1, 0.92))
		cylinder(0.118, 0.2, Vector3(side * 0.02, -0.13, -0.005), armor, arm)
		sphere(Vector3(0.09, 0.09, 0.09), Vector3(side * 0.035, -0.3, -0.04), webbing, arm)
		capsule(0.09, 0.34, Vector3(side * 0.045, -0.4, -0.11), undersuit, arm, Vector3(1, 1, 0.9))
		box(Vector3(0.17, 0.22, 0.14), Vector3(side * 0.045, -0.39, -0.16), armor, arm)
		box(Vector3(0.17, 0.055, 0.15), Vector3(side * 0.045, -0.49, -0.17), armor_edge, arm)
		box(Vector3(0.13, 0.12, 0.13), Vector3(side * 0.055, -0.57, -0.25), rubber, arm)
		merge_parts(arm)
		arms.append(arm)
	# Segmented trousers, articulated knees, protective pads and shaped boots.
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.145, 0.83, 0.015)
		add_child(leg)
		capsule(0.115, 0.38, Vector3(0, -0.13, 0), undersuit, leg, Vector3(1.08, 1, 0.92))
		box(Vector3(0.22, 0.15, 0.13), Vector3(0, -0.32, -0.075), armor, leg)
		sphere(Vector3(0.125, 0.11, 0.085), Vector3(0, -0.34, -0.14), armor_edge, leg)
		capsule(0.09, 0.39, Vector3(0, -0.53, 0), undersuit, leg, Vector3(1, 1, 0.92))
		box(Vector3(0.17, 0.2, 0.1), Vector3(0, -0.55, -0.08), armor, leg)
		box(Vector3(0.21, 0.1, 0.32), Vector3(0, -0.75, -0.105), rubber, leg)
		box(Vector3(0.19, 0.025, 0.28), Vector3(0, -0.8, -0.105), armor_edge, leg)
		merge_parts(leg)
		legs.append(leg)

	# Compact service rifle with receiver, rail, barrel shroud, muzzle and magazine.
	weapon_mount = Node3D.new()
	weapon_mount.position = Vector3(0.12, 1.19, -0.37)
	add_child(weapon_mount)
	box(Vector3(0.18, 0.16, 0.38), Vector3(0, 0, -0.16), webbing, weapon_mount)
	box(Vector3(0.17, 0.095, 0.25), Vector3(0, 0.095, -0.17), armor_edge, weapon_mount)
	box(Vector3(0.12, 0.045, 0.1), Vector3(0, 0.15, -0.12), amber, weapon_mount)
	box(Vector3(0.11, 0.1, 0.17), Vector3(0, -0.12, -0.05), rubber, weapon_mount)
	box(Vector3(0.1, 0.115, 0.29), Vector3(0, 0.01, -0.4), armor, weapon_mount)
	cylinder(0.032, 0.28, Vector3(0, 0.025, -0.65), armor_edge, weapon_mount, Vector3(-PI / 2, 0, 0))
	box(Vector3(0.1, 0.11, 0.07), Vector3(0, 0.025, -0.81), webbing, weapon_mount)
	box(Vector3(0.09, 0.18, 0.12), Vector3(0, -0.14, -0.27), amber, weapon_mount)
	for x in [-0.12, 0.12]:
		box(Vector3(0.035, 0.055, 0.1), Vector3(x, 0.1, -0.31), webbing, weapon_mount)
	merge_parts(weapon_mount)
	flash = sphere(Vector3(0.12, 0.12, 0.13), Vector3(0, 0.025, -0.89), material(Color("ffc66d"), 0.0, 0.3, true), weapon_mount)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.hide()

	radio_indicator = sphere(Vector3(0.1, 0.1, 0.06), Vector3(-0.31, 1.3, -0.2), lens, self)
	radio_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	radio_label = make_label("RADIO", Vector3(0.5, 2.1, 0), Color("65d9e2"), 22)
	search_label = make_label("", Vector3(0.5, 2.1, 0), Color("d7d3ad"), 20)
	set_radio_transmitting(false)

func _process(delta: float) -> void:
	_anim_clock += delta
	var actor := get_parent() as CharacterBody3D
	var travel := 0.0
	if actor:
		travel = Vector2(actor.velocity.x, actor.velocity.z).length()
	var gait := minf(travel / 2.5, 1.0)
	var swing := sin(_anim_clock * 8.0) * gait * 0.36
	if legs.size() == 2:
		legs[0].rotation.x = swing
		legs[1].rotation.x = -swing
	if arms.size() == 2:
		arms[0].rotation.x = -swing * 0.42
		arms[1].rotation.x = swing * 0.42
	if is_instance_valid(torso):
		torso.position.y = 0.98 + sin(_anim_clock * (8.0 if gait > 0.05 else 2.3)) * (0.022 * gait + 0.004)

func set_radio_transmitting(transmitting: bool) -> void:
	if is_instance_valid(radio_indicator): radio_indicator.visible = transmitting
	if is_instance_valid(radio_label): radio_label.visible = transmitting
	if is_instance_valid(search_label): search_label.visible = not transmitting and not _search_status.is_empty()

func set_search_status(value: String) -> void:
	_search_status = value
	search_label.text = {"investigator": "SEARCH", "holder": "HOLD", "clear": "CLEAR"}.get(value, "")
	search_label.modulate = Color("d7d3ad") if value == "holder" else Color("ffc064") if value == "investigator" else Color("a0bab7")
	search_label.visible = not radio_label.visible and not value.is_empty()

func configure(role: String) -> void:
	if role == "rifle":
		weapon_mount.scale.z = 1.18
		weapon_mount.scale.x = 1.08
		status.albedo_color = Color("db9850")
		status.emission = status.albedo_color

func pose(state: String, firing: bool, windup: float, alive: bool) -> void:
	visible = alive
	flash.visible = firing
	status.albedo_color = Color("ff634b") if windup > 0 else Color("ffc064") if state in ["suspicious", "search", "reload"] else Color("bd8740")
	status.emission = status.albedo_color
	weapon_mount.rotation.x = -0.16 if state == "reload" else -0.06 if firing else 0.0
	weapon_mount.position.y = 1.19 + (0.035 if firing else 0.0)
	if arms.size() == 2:
		arms[0].rotation.z = -0.1 if state == "reload" else 0.0
		arms[1].rotation.z = 0.08 if state == "reload" else 0.0

func make_label(value: String, at: Vector3, tint: Color, size: int) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = size
	label.pixel_size = 0.0035
	label.modulate = tint
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	add_child(label)
	return label

func material(color: Color, metal: float, rough: float, emission: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metal
	result.roughness = rough
	result.emission_enabled = emission
	if emission: result.emission = color
	return result

func box(size: Vector3, at: Vector3, mat: Material, parent: Node = self) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = _rounded_box_mesh(size)
	instance.position = at
	instance.material_override = mat
	parent.add_child(instance)
	return instance

func _rounded_box_mesh(size: Vector3) -> ArrayMesh:
	var half := size * 0.5
	var bevel := minf(minf(size.x, minf(size.y, size.z)) * 0.2, 0.055)
	var faces: Array = [
		[Vector3.RIGHT, Vector3.FORWARD, Vector3.UP],
		[Vector3.LEFT, Vector3.BACK, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP],
		[Vector3.FORWARD, Vector3.LEFT, Vector3.UP]
	]
	const CELLS := 4
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face_index := 0
	for face: Array in faces:
		var normal: Vector3 = face[0]
		var axis_u: Vector3 = face[1]
		var axis_v: Vector3 = face[2]
		var start: int = face_index * (CELLS + 1) * (CELLS + 1)
		for row in CELLS + 1:
			for column in CELLS + 1:
				var u := float(column) / CELLS * 2.0 - 1.0
				var v := float(row) / CELLS * 2.0 - 1.0
				var point := normal * half.dot(normal.abs()) + axis_u * u * half.dot(axis_u.abs()) + axis_v * v * half.dot(axis_v.abs())
				var inner := Vector3(
					clampf(point.x, -half.x + bevel, half.x - bevel),
					clampf(point.y, -half.y + bevel, half.y - bevel),
					clampf(point.z, -half.z + bevel, half.z - bevel))
				var delta := point - inner
				var rounded_normal := delta.normalized() if delta.length_squared() > 0.000001 else normal
				surface.set_normal(rounded_normal)
				surface.set_uv(Vector2(float(column) / CELLS, float(row) / CELLS))
				surface.add_vertex(inner + rounded_normal * bevel)
		for row in CELLS:
			for column in CELLS:
				var a: int = start + row * (CELLS + 1) + column
				var b: int = a + 1
				var d: int = a + CELLS + 1
				var c: int = d + 1
				surface.add_index(a)
				surface.add_index(b)
				surface.add_index(c)
				surface.add_index(a)
				surface.add_index(c)
				surface.add_index(d)
		face_index += 1
	return surface.commit()

func capsule(radius: float, height: float, at: Vector3, mat: Material, parent: Node, size_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	instance.mesh = mesh
	instance.position = at
	instance.scale = size_scale
	instance.material_override = mat
	parent.add_child(instance)
	return instance

func sphere(size: Vector3, at: Vector3, mat: Material, parent: Node = self) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	instance.mesh = mesh
	instance.position = at
	instance.scale = size
	instance.material_override = mat
	parent.add_child(instance)
	return instance

func cylinder(radius: float, height: float, at: Vector3, mat: Material, parent: Node, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	instance.mesh = mesh
	instance.position = at
	instance.rotation = rotation
	instance.material_override = mat
	parent.add_child(instance)
	return instance

func merge_parts(parent: Node3D) -> void:
	# Merge a moving body section into one vertex-colored surface to keep the actor inexpensive.
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var source: Array[MeshInstance3D] = []
	var vertex_base := 0
	for child in parent.get_children():
		if child is not MeshInstance3D or child.mesh == null or child.material_override == null: continue
		var part := child as MeshInstance3D
		var arrays := part.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var source_material := part.material_override as StandardMaterial3D
		var tint := source_material.albedo_color if source_material else Color.WHITE
		var normal_transform := part.transform.basis.inverse().transposed()
		for index in vertices.size():
			builder.set_color(tint)
			if index < normals.size(): builder.set_normal((normal_transform * normals[index]).normalized())
			if index < uvs.size(): builder.set_uv(uvs[index])
			builder.add_vertex(part.transform * vertices[index])
		if indices.is_empty():
			for index in vertices.size(): builder.add_index(vertex_base + index)
		else:
			for index in indices: builder.add_index(vertex_base + index)
		vertex_base += vertices.size()
		source.append(part)
	for part in source:
		parent.remove_child(part)
		part.queue_free()
	if source.is_empty(): return
	var mesh := builder.commit()
	if mesh == null: return
	var combined_material := StandardMaterial3D.new()
	combined_material.albedo_color = Color.WHITE
	combined_material.albedo_texture = _get_uniform_grain()
	combined_material.vertex_color_use_as_albedo = true
	combined_material.metallic = 0.18
	combined_material.roughness = 0.7
	combined_material.roughness_texture = _get_uniform_grain()
	combined_material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	combined_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.surface_set_material(0, combined_material)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

static func _get_uniform_grain() -> Texture2D:
	if _uniform_grain:
		return _uniform_grain
	const RESOLUTION := 128
	var image := Image.create(RESOLUTION, RESOLUTION, false, Image.FORMAT_RGBA8)
	for y in RESOLUTION:
		for x in RESOLUTION:
			var u := float(x) / RESOLUTION
			var v := float(y) / RESOLUTION
			var broad := _tile_noise(u, v, 12, 13) - 0.5
			var weave := _tile_noise(u, v, 44, 37) - 0.5
			var grain := _tile_noise(u, v, 92, 91) - 0.5
			var value := clampf(0.92 + broad * 0.22 + weave * 0.12 + grain * 0.08, 0.72, 1.04)
			image.set_pixel(x, y, Color(value, value, value, 1.0))
	_uniform_grain = ImageTexture.create_from_image(image)
	_uniform_grain.resource_name = "Original procedural uniform grain"
	return _uniform_grain

static func _tile_noise(u: float, v: float, cells: int, salt: int) -> float:
	var x := u * cells
	var y := v * cells
	var ix := floori(x)
	var iy := floori(y)
	var tx := x - floorf(x)
	var ty := y - floorf(y)
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var a := _grain_hash(posmod(ix, cells), posmod(iy, cells), salt)
	var b := _grain_hash(posmod(ix + 1, cells), posmod(iy, cells), salt)
	var c := _grain_hash(posmod(ix, cells), posmod(iy + 1, cells), salt)
	var d := _grain_hash(posmod(ix + 1, cells), posmod(iy + 1, cells), salt)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)

static func _grain_hash(x: int, y: int, salt: int) -> float:
	var raw := sin(float(x * 127 + y * 311 + salt * 1973)) * 43758.5453
	return raw - floorf(raw)
