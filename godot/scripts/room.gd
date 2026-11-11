extends Node3D
## Original primitive geometry for the partial Godot Control Room port.
## One reference tile is two meters. Only walls/floor/ceiling and the core gate collide.

const MAP: Array[String] = [
	"#############",
	"##########..#",
	"##########.##",
	"##########.##",
	"########...##",
	"#........####",
	"#.######.####",
	"#........####",
	"#.....#..####",
	"#############"
]

var _built: bool = false
var _gate_closed: bool = true
var _panel_disabled: bool = false
var _gate: Node3D
var _gate_shapes: Array[CollisionShape3D] = []
var _panel_screen: MeshInstance3D
var _panel_light: OmniLight3D
var _core_light: OmniLight3D
var _materials: Dictionary = {}

func build() -> void:
	if _built:
		return
	_built = true
	_make_materials()
	_make_environment()
	_solid_box("Floor", Vector3(13, -0.15, 10), Vector3(26, 0.3, 20), _materials["floor"])
	_solid_box("Ceiling", Vector3(13, 3.15, 10), Vector3(26, 0.3, 20), _materials["ceiling"])
	for z in MAP.size():
		for x in MAP[z].length():
			if MAP[z][x] == "#":
				_solid_box("Wall_%d_%d" % [x, z], Vector3(x * 2 + 1, 1.5, z * 2 + 1), Vector3(2, 3, 2), _materials["concrete"])
				_wall_details(x, z)
			else:
				_floor_details(x, z)
	_make_gate()
	_make_panel()
	_make_core()
	_make_extraction()
	_make_practicals()
	_label("DIRECT / SECURITY", Vector3(3.1, 2.25, 11), Vector3(0, 90, 0), Color("dfb265"))
	_label("MAINTENANCE / PANEL", Vector3(10.7, 2.23, 15), Vector3.ZERO, Color("8ed5c8"))
	_label("CONTROL / DATA CORE", Vector3(17.8, 2.32, 11), Vector3(0, -90, 0), Color("7eddd7"))
	_label("EXTRACT", Vector3(23, 2.28, 2.06), Vector3.ZERO, Color("9bddb3"))
	# Nonblocking set dressing is tucked against walls, away from the guard's firing lane.
	_mesh_box(self, "EquipmentRack", Vector3(13.4, 0.9, 11.68), Vector3(0.72, 1.8, 0.32), _materials["steel"])
	for i in 5:
		_mesh_box(self, "RackVent", Vector3(13.4, 0.36 + i * 0.27, 11.5), Vector3(0.55, 0.08, 0.015), _materials["dark"])
		_mesh_box(self, "RackIndicator", Vector3(13.61, 0.4 + i * 0.27, 11.485), Vector3(0.045, 0.045, 0.02), _materials["cyan"])
	set_panel_disabled(_panel_disabled)
	set_gate(_gate_closed)

func set_gate(closed: bool) -> void:
	_gate_closed = closed
	if not is_instance_valid(_gate):
		return
	_gate.visible = closed
	for shape in _gate_shapes:
		shape.set_deferred("disabled", not closed)

func set_panel_disabled(value: bool) -> void:
	_panel_disabled = value
	if is_instance_valid(_panel_screen):
		_panel_screen.material_override = _materials["off"] if value else _materials["cyan"]
	if is_instance_valid(_panel_light):
		_panel_light.light_energy = 0.12 if value else 0.75

func set_core_collected(value: bool) -> void:
	var core: Node3D = get_node_or_null("Core")
	if core:
		core.visible = not value
	if is_instance_valid(_core_light):
		_core_light.visible = not value

func _make_materials() -> void:
	_materials["concrete"] = _surface(Color("64685d"), 0.96)
	_materials["concrete"].albedo_texture = _noise_texture(Color("424a41"), Color("777b6b"), 18.0)
	_materials["concrete"].uv1_scale = Vector3(2, 3, 1)
	_materials["steel"] = _surface(Color("39493f"), 0.7, 0.55)
	_materials["floor"] = _surface(Color("485044"), 0.92, 0.15)
	_materials["floor"].albedo_texture = _noise_texture(Color("333d34"), Color("656655"), 8.0)
	_materials["floor"].uv1_scale = Vector3(13, 10, 1)
	_materials["ceiling"] = _surface(Color("28372f"), 0.85, 0.35)
	_materials["dark"] = _surface(Color("15231d"), 0.88)
	_materials["trim"] = _surface(Color("6b7564"), 0.7, 0.6)
	_materials["hazard"] = _surface(Color("a99553"), 0.83)
	_materials["off"] = _surface(Color("263e36"), 0.82)
	_materials["cyan"] = _emissive(Color("70d6bf"), 1.6)
	_materials["amber"] = _emissive(Color("f0ca7b"), 1.8)
	_materials["green"] = _emissive(Color("85d5a2"), 1.3)

func _surface(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var material := _surface(color, 0.55)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _noise_texture(low: Color, high: Color, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = 707
	noise.frequency = 1.0 / frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var gradient := Gradient.new()
	gradient.set_color(0, low)
	gradient.set_color(1, high)
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = gradient
	return texture

func _make_environment() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "BunkerEnvironment"
	var resource := Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("101a17")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("9aa990")
	resource.ambient_light_energy = 0.42
	resource.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = resource
	add_child(environment)

func _mesh_box(parent: Node3D, node_name: String, center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = center
	parent.add_child(mesh)
	return mesh

func _solid_box(node_name: String, center: Vector3, size: Vector3, material: Material, parent: Node3D = self) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	_mesh_box(body, "Mesh", Vector3.ZERO, size, material)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	return body

func _open(x: int, z: int) -> bool:
	return z >= 0 and z < MAP.size() and x >= 0 and x < MAP[z].length() and MAP[z][x] != "#"

func _wall_details(x: int, z: int) -> void:
	var center := Vector3(x * 2 + 1, 1.5, z * 2 + 1)
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not _open(x + direction.x, z + direction.y):
			continue
		var along_x: bool = direction.x == 0
		var face := center + Vector3(direction.x * 1.008, 0, direction.y * 1.008)
		var width := Vector3(1.97, 0.13, 0.022) if along_x else Vector3(0.022, 0.13, 1.97)
		_mesh_box(self, "SafetyBand", Vector3(face.x, 0.83, face.z), width, _materials["hazard"])
		width.y = 0.22
		_mesh_box(self, "WallSkirt", Vector3(face.x, 0.2, face.z), width, _materials["steel"])
		var seam_size := Vector3(0.035, 2.95, 0.025) if along_x else Vector3(0.025, 2.95, 0.035)
		var seam_center := face + Vector3(-0.96 if along_x else 0, 0, 0 if along_x else -0.96)
		_mesh_box(self, "PanelSeam", seam_center, seam_size, _materials["dark"])
		var cap := Vector3(1.98, 0.1, 0.06) if along_x else Vector3(0.06, 0.1, 1.98)
		_mesh_box(self, "Conduit", Vector3(face.x, 2.72, face.z), cap, _materials["trim"])

func _floor_details(x: int, z: int) -> void:
	var center := Vector3(x * 2 + 1, 0.006, z * 2 + 1)
	_mesh_box(self, "FloorSeam", center + Vector3(-0.985, 0, 0), Vector3(0.025, 0.008, 1.97), _materials["dark"])
	_mesh_box(self, "FloorSeam", center + Vector3(0, 0, -0.985), Vector3(1.97, 0.008, 0.025), _materials["dark"])
	for offset in [-0.6, 0.6]:
		_mesh_box(self, "FloorFastener", center + Vector3(offset, 0.005, -0.6), Vector3(0.06, 0.012, 0.06), _materials["trim"])
	_mesh_box(self, "CeilingRib", Vector3(center.x, 2.95, center.z), Vector3(1.9, 0.06, 0.09), _materials["steel"])

func _make_gate() -> void:
	_gate = Node3D.new()
	_gate.name = "Gate"
	add_child(_gate)
	for x in range(8, 11):
		var body := _solid_box("Gate_%d" % x, Vector3(x * 2 + 1, 1.5, 9), Vector3(2, 3, 2), _materials["steel"], _gate)
		for child in body.get_children():
			if child is CollisionShape3D:
				_gate_shapes.append(child)
	_label("CORE REQUIRED", Vector3(17, 2.25, 10.03), Vector3(0, 180, 0), Color("dfb265"), _gate)

func _make_panel() -> void:
	var panel := Node3D.new()
	panel.name = "AlarmPanel"
	panel.position = Vector3(9, 0, 15)
	add_child(panel)
	_mesh_box(panel, "Stand", Vector3(0, 0.54, 0), Vector3(0.62, 1.08, 0.4), _materials["steel"])
	_mesh_box(panel, "Bezel", Vector3(0, 1.22, 0), Vector3(0.75, 0.52, 0.28), _materials["dark"])
	_panel_screen = _mesh_box(panel, "Screen", Vector3(-0.383, 1.23, 0), Vector3(0.014, 0.3, 0.2), _materials["cyan"])
	for i in 3:
		_mesh_box(panel, "Key", Vector3(-0.326, 0.87, -0.1 + i * 0.1), Vector3(0.022, 0.07, 0.055), _materials["hazard"])
	_panel_light = _light(Vector3(8.4, 1.85, 15), Color("62dac5"), 0.75, 4.5)
	_label("E / ALARM PANEL", Vector3(9, 1.9, 15), Vector3(0, 90, 0), Color("8ed5c8"))

func _make_core() -> void:
	var core := Node3D.new()
	core.name = "Core"
	core.position = Vector3(17, 0, 11)
	add_child(core)
	_mesh_box(core, "Base", Vector3(0, 0.18, 0), Vector3(0.7, 0.36, 0.7), _materials["steel"])
	_mesh_box(core, "DataCapsule", Vector3(0, 0.8, 0), Vector3(0.32, 0.86, 0.32), _materials["cyan"])
	_mesh_box(core, "Cap", Vector3(0, 1.3, 0), Vector3(0.5, 0.14, 0.5), _materials["trim"])
	_core_light = _light(Vector3(17, 1.6, 11), Color("65ceca"), 1.05, 5.0)

func _make_extraction() -> void:
	_mesh_box(self, "ExtractionPad", Vector3(23, 0.018, 3), Vector3(1.25, 0.03, 1.25), _materials["green"])
	for x in [22.3, 23.7]:
		_mesh_box(self, "ExitPost", Vector3(x, 1.2, 2.4), Vector3(0.14, 2.4, 0.14), _materials["steel"])
		_mesh_box(self, "ExitLight", Vector3(x, 1.6, 2.5), Vector3(0.1, 1.3, 0.06), _materials["green"])
	_light(Vector3(23, 2.4, 3), Color("92d6a7"), 1.2, 6.0)

func _make_practicals() -> void:
	for pos in [Vector3(3, 2.87, 17), Vector3(3, 2.87, 11), Vector3(9, 2.87, 11), Vector3(15, 2.87, 15), Vector3(21, 2.87, 7)]:
		_mesh_box(self, "LampHousing", pos, Vector3(0.85, 0.13, 0.3), _materials["dark"])
		_mesh_box(self, "LampLens", pos + Vector3(0, -0.075, 0), Vector3(0.68, 0.03, 0.22), _materials["amber"])
		_light(pos + Vector3(0, -0.3, 0), Color("efd098"), 1.4, 7.0)

func _light(pos: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.omni_attenuation = 1.5
	light.shadow_enabled = true
	add_child(light)
	return light

func _label(text: String, pos: Vector3, _degrees: Vector3, color: Color, parent: Node3D = self) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	# Camera-facing text avoids mirrored backs while still respecting 3D wall depth.
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 44
	label.pixel_size = 0.0032
	label.modulate = color
	label.outline_size = 8
	label.no_depth_test = false
	parent.add_child(label)
	return label
