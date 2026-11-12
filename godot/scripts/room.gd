extends Node3D
## Original primitive geometry for all three campaign missions.
## One reference tile is two meters. World surfaces, gates and substantial props share solid collision layer 1.

const IndustrialConsoleScene = preload("res://scenes/industrial_console.tscn")

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

var map_rows: Array[String] = []
var mission_id: String = "control-room"
var _config: Dictionary = {}
var _panel_position := Vector3(9, 0, 15)
var _core_position := Vector3(17, 0, 11)
var _exit_position := Vector3(23, 0, 3)
var _bulkhead: Node3D
var _bulkhead_shapes: Array[CollisionShape3D] = []
var _service_enabled: bool = true
var _lamp_enabled: bool = true
var _practical_lights: Array[OmniLight3D] = []
var _camera_screen: MeshInstance3D
var _service_lamp: MeshInstance3D
var _service_lamp_light: OmniLight3D
var _exit_pad: MeshInstance3D
var _exit_light_meshes: Array[MeshInstance3D] = []
var _exit_light: OmniLight3D
var _built: bool = false
var _gate_closed: bool = true
var _panel_disabled: bool = false
var _gate: Node3D
var _gate_shapes: Array[CollisionShape3D] = []
var _panel_screen: MeshInstance3D
var _panel_on_material: StandardMaterial3D
var _panel_light: OmniLight3D
var _core_light: OmniLight3D
var _materials: Dictionary = {}

func build(config: Dictionary = {}) -> void:
	if _built:
		return
	_built = true
	_config = config
	mission_id = str(config.get("id", "control-room"))
	for row in config.get("map", MAP):
		map_rows.append(str(row))
	var panel_value: Variant = config.get("panel")
	var core_value: Variant = config.get("core")
	var exit_value: Variant = config.get("exit")
	_panel_position = panel_value if panel_value is Vector3 else Vector3(9, 0, 15)
	_core_position = core_value if core_value is Vector3 else Vector3(17, 0, 11)
	_exit_position = exit_value if exit_value is Vector3 else Vector3(23, 0, 3)
	_make_materials()
	_panel_on_material = _materials["cyan"]
	_make_environment()
	var width: float = map_rows[0].length() * 2.0
	var depth: float = map_rows.size() * 2.0
	_solid_box("Floor", Vector3(width / 2, -0.15, depth / 2), Vector3(width, 0.3, depth), _materials["floor"])
	_solid_box("Ceiling", Vector3(width / 2, 3.15, depth / 2), Vector3(width, 0.3, depth), _materials["ceiling"])
	for z in map_rows.size():
		for x in map_rows[z].length():
			if map_rows[z][x] == "#":
				_solid_box("Wall_%d_%d" % [x, z], Vector3(x * 2 + 1, 1.5, z * 2 + 1), Vector3(2, 3, 2), _materials["concrete"])
				_wall_details(x, z)
			else:
				_floor_details(x, z)
	if mission_id == "control-room":
		_make_gate()
		_make_core()
		_make_control_devices()
		_label("DIRECT / SECURITY", Vector3(3.1, 2.25, 11), Vector3.ZERO, Color("dfb265"))
		_label("MAINTENANCE", Vector3(9, 1.62, 15.8), Vector3.ZERO, Color("8ed5c8"), self, 28, 0.0015, 3)
		_prop_collision(self, Vector3(13.4, 0.9, 11.68), Vector3(0.72, 1.8, 0.32))
		_mesh_box(self, "EquipmentRack", Vector3(13.4, 0.9, 11.68), Vector3(0.72, 1.8, 0.32), _materials["steel"])
		for i in 5:
			_mesh_box(self, "RackVent", Vector3(13.4, 0.36 + i * 0.27, 11.5), Vector3(0.55, 0.08, 0.015), _materials["dark"])
			_mesh_box(self, "RackIndicator", Vector3(13.61, 0.4 + i * 0.27, 11.485), Vector3(0.045, 0.045, 0.02), _materials["cyan"])
	if mission_id != "breach":
		_make_panel()
	_make_extraction()
	_make_practicals()
	set_panel_disabled(false)
	set_gate(mission_id == "control-room")
	if mission_id == "blackout":
		set_power_restored(false)


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
		_panel_screen.material_override = _materials["off"] if value else _panel_on_material
	if is_instance_valid(_panel_light):
		_panel_light.light_energy = (0.04 if mission_id == "control-room" else 0.12) if value else (0.22 if mission_id == "control-room" else 0.75)

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
	return z >= 0 and z < map_rows.size() and x >= 0 and x < map_rows[z].length() and map_rows[z][x] != "#"

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
	panel.position = _panel_position
	add_child(panel)
	if mission_id == "control-room":
		var console := IndustrialConsoleScene.instantiate()
		console.name = "ConsoleVisual"
		console.position.z = 0.45
		_prop_collision(panel, Vector3(-0.04, 0.8, 0.45), Vector3(1.0, 1.6, 0.72), _panel_position)
		panel.add_child(console)
		_panel_screen = console.get_node("RecessedDisplay") as MeshInstance3D
		_panel_on_material = _emissive(Color("5c978a"), 0.14)
		_panel_screen.material_override = _panel_on_material
	else:
		_prop_collision(panel, Vector3(0, 0.75, 0), Vector3(0.75, 1.5, 0.4), _panel_position)
		_mesh_box(panel, "Stand", Vector3(0, 0.54, 0), Vector3(0.62, 1.08, 0.4), _materials["steel"])
		_mesh_box(panel, "Bezel", Vector3(0, 1.22, 0), Vector3(0.75, 0.52, 0.28), _materials["dark"])
		_panel_screen = _mesh_box(panel, "Screen", Vector3(-0.383, 1.23, 0), Vector3(0.014, 0.3, 0.2), _materials["cyan"])
		for i in 3:
			_mesh_box(panel, "Key", Vector3(-0.326, 0.87, -0.1 + i * 0.1), Vector3(0.022, 0.07, 0.055), _materials["hazard"])
	var control_console: bool = mission_id == "control-room"
	_panel_light = _light(_panel_position + Vector3(-0.6, 1.85, 0), Color("7fa99b") if control_console else Color("62dac5"), 0.22 if control_console else 0.75, 3.0 if control_console else 4.5)
	if control_console:
		# E remains in the HUD's close-range prompt; this small world label is only a locator.
		_label("ALARM PANEL", _panel_position + Vector3(0, 1.62, -0.8), Vector3.ZERO, Color("8ed5c8"), self, 30, 0.0018, 3)
	else:
		_label("E / BACKUP POWER", _panel_position + Vector3(0, 1.9, 0), Vector3.ZERO, Color("8ed5c8"))

func _make_core() -> void:
	var core := Node3D.new()
	core.name = "Core"
	core.position = _core_position
	add_child(core)
	_mesh_box(core, "Base", Vector3(0, 0.18, 0), Vector3(0.7, 0.36, 0.7), _materials["steel"])
	_mesh_box(core, "DataCapsule", Vector3(0, 0.8, 0), Vector3(0.32, 0.86, 0.32), _materials["cyan"])
	_mesh_box(core, "Cap", Vector3(0, 1.3, 0), Vector3(0.5, 0.14, 0.5), _materials["trim"])
	_core_light = _light(_core_position + Vector3(0, 1.6, 0), Color("65ceca"), 1.05, 5.0)

func _make_extraction() -> void:
	_exit_pad = _mesh_box(self, "ExtractionPad", _exit_position + Vector3(0, 0.018, 0), Vector3(1.25, 0.03, 1.25), _materials["green"])
	for offset in [-0.7, 0.7]:
		_mesh_box(self, "ExitPost", _exit_position + Vector3(offset, 1.2, -0.6), Vector3(0.14, 2.4, 0.14), _materials["steel"])
		_exit_light_meshes.append(_mesh_box(self, "ExitLight", _exit_position + Vector3(offset, 1.6, -0.5), Vector3(0.1, 1.3, 0.06), _materials["green"]))
	_exit_light = _light(_exit_position + Vector3(0, 2.4, 0), Color("92d6a7"), 1.2, 6.0)
	_label("CONTROL SECTOR" if mission_id == "breach" else "EXTRACTION LIFT" if mission_id == "blackout" else "EXTRACT", _exit_position + Vector3(0, 2.28, 0), Vector3.ZERO, Color("9bddb3"))

func _make_practicals() -> void:
	var positions: Array[Vector3] = [Vector3(3, 2.87, 17), Vector3(3, 2.87, 11), Vector3(9, 2.87, 11), Vector3(15, 2.87, 15), Vector3(21, 2.87, 7)]
	if mission_id == "breach":
		positions = [Vector3(4, 2.87, 4), Vector3(12, 2.87, 4), Vector3(18, 2.87, 10), Vector3(22, 2.87, 16)]
	elif mission_id == "blackout":
		positions = [Vector3(3, 2.87, 3), Vector3(14, 2.87, 9), Vector3(7, 2.87, 15), Vector3(23, 2.87, 3)]
	for pos in positions:
		_mesh_box(self, "LampHousing", pos, Vector3(0.85, 0.13, 0.3), _materials["dark"])
		_mesh_box(self, "LampLens", pos + Vector3(0, -0.075, 0), Vector3(0.68, 0.03, 0.22), _materials["amber"])
		var fixture := _light(pos + Vector3(0, -0.3, 0), Color("efd098"), 1.4, 7.0)
		fixture.set_meta("base_energy", 1.4)
		_practical_lights.append(fixture)

func _make_control_devices() -> void:
	# Shootable hit areas are owned
	# by the encounter module; terminal housings have separate world collision.
	var bulkhead_body := _solid_box("Bulkhead", Vector3(17, 1.5, 13), Vector3(2, 3, 2), _materials["steel"])
	_bulkhead = bulkhead_body
	for child in bulkhead_body.get_children():
		if child is CollisionShape3D:
			_bulkhead_shapes.append(child)
	set_bulkhead(false)
	for entry in [["SERVICE POWER", Vector3(13, 0, 15)], ["OVERLOAD GRID", Vector3(17, 0, 15)]]:
		var at: Vector3 = entry[1]
		_prop_collision(self, at + Vector3(0, 0.7, 0), Vector3(0.6, 1.4, 0.35), at)
		_mesh_box(self, "DeviceStand", at + Vector3(0, 0.48, 0), Vector3(0.6, 0.96, 0.35), _materials["steel"])
		_mesh_box(self, "DeviceBezel", at + Vector3(0, 1.15, 0), Vector3(0.65, 0.5, 0.25), _materials["dark"])
		_mesh_box(self, "DeviceScreen", at + Vector3(-0.331, 1.15, 0), Vector3(0.015, 0.32, 0.18), _materials["cyan"])
		_label(str(entry[0]), at + Vector3(0, 1.95, 0), Vector3.ZERO, Color("8ed5c8"))
	_label("E / BULKHEAD SWITCH", Vector3(15, 1.9, 15), Vector3.ZERO, Color("d8ca90"))
	var camera := Node3D.new()
	camera.name = "SecurityCamera"
	camera.position = Vector3(14.6, 0, 11)
	add_child(camera)
	_mesh_box(camera, "CameraBody", Vector3(0, 1.55, 0), Vector3(0.55, 0.4, 0.45), _materials["steel"])
	_camera_screen = _mesh_box(camera, "CameraLens", Vector3(-0.285, 1.55, 0), Vector3(0.025, 0.2, 0.2), _materials["amber"])
	_label("SECURITY CAMERA", Vector3(14.6, 2.1, 11), Vector3.ZERO, Color("dfb265"))
	_mesh_box(self, "ServiceLampMount", Vector3(7, 1, 11.72), Vector3(0.18, 2, 0.18), _materials["steel"])
	_service_lamp = _mesh_box(self, "ServiceLamp", Vector3(7, 1.5, 11.6), Vector3(0.2, 0.4, 0.2), _materials["amber"])
	_service_lamp_light = _light(Vector3(7, 1.5, 11.5), Color("edcc95"), 0.8, 5.0)
	var intel := Node3D.new()
	intel.name = "OptionalIntel"
	intel.position = Vector3(17.55, 0, 11.55)
	add_child(intel)
	_mesh_box(intel, "Manifest", Vector3(0, 0.7, 0), Vector3(0.24, 0.5, 0.24), _materials["cyan"])
	_label("OPTIONAL INTEL", Vector3(17, 1.9, 11), Vector3.ZERO, Color("8ed5c8"), intel)
	# Label uses a local position because its parent is the manifest group.
	intel.get_child(intel.get_child_count() - 1).position = Vector3(0, 1.9, 0)
	var cache := Node3D.new()
	cache.name = "HiddenCache"
	cache.position = Vector3(15, 0, 17.3)
	add_child(cache)
	_prop_collision(cache, Vector3(0, 0.35, 0), Vector3(0.75, 0.7, 0.65), Vector3(15, 0, 17))
	_mesh_box(cache, "SupplyBox", Vector3(0, 0.35, 0), Vector3(0.75, 0.7, 0.65), _materials["steel"])
	_mesh_box(cache, "MedicalStripe", Vector3(-0.38, 0.4, 0), Vector3(0.02, 0.16, 0.45), _materials["green"])

func set_optional_collected(intel: bool, secret: bool) -> void:
	var manifest := get_node_or_null("OptionalIntel") as Node3D
	if manifest:
		manifest.visible = not intel
	var cache := get_node_or_null("HiddenCache") as Node3D
	if cache:
		cache.visible = not secret
		for child in cache.get_children():
			if child is StaticBody3D: child.collision_layer = 0 if secret else 1

func set_bulkhead(closed: bool) -> void:
	if not is_instance_valid(_bulkhead):
		return
	_bulkhead.visible = closed
	for shape in _bulkhead_shapes:
		shape.set_deferred("disabled", not closed)

func set_service_power(enabled: bool) -> void:
	_service_enabled = enabled
	_apply_service_lighting()

func set_service_lamp(enabled: bool) -> void:
	_lamp_enabled = enabled
	if is_instance_valid(_service_lamp):
		_service_lamp.material_override = _materials["amber"] if enabled else _materials["off"]
	_apply_service_lighting()

func _apply_service_lighting() -> void:
	for fixture in _practical_lights:
		var energy: float = float(fixture.get_meta("base_energy", 1.4)) * (1.0 if _service_enabled else 0.5)
		if not _lamp_enabled and fixture.position.x < 10 and absf(fixture.position.z - 11) < 3:
			energy *= 0.65
		fixture.light_energy = energy
	if is_instance_valid(_service_lamp_light):
		_service_lamp_light.light_energy = (0.8 if _lamp_enabled else 0.0) * (1.0 if _service_enabled else 0.5)

func set_camera_enabled(enabled: bool) -> void:
	if is_instance_valid(_camera_screen):
		_camera_screen.material_override = _materials["amber"] if enabled else _materials["off"]

func set_power_restored(enabled: bool) -> void:
	if mission_id != "blackout":
		return
	if is_instance_valid(_panel_screen):
		_panel_screen.material_override = _materials["green"] if enabled else _materials["cyan"]
	if is_instance_valid(_exit_pad):
		_exit_pad.material_override = _materials["green"] if enabled else _materials["amber"]
	for lens in _exit_light_meshes:
		lens.material_override = _materials["green"] if enabled else _materials["amber"]
	if is_instance_valid(_exit_light):
		_exit_light.light_color = Color("92d6a7") if enabled else Color("e5ad65")


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

func _label(text: String, pos: Vector3, _degrees: Vector3, color: Color, parent: Node3D = self, font_size: int = 44, pixel_size: float = 0.0032, outline_size: int = 8) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	# Camera-facing text avoids mirrored backs while still respecting 3D wall depth.
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = outline_size
	label.no_depth_test = false
	parent.add_child(label)
	return label

func _prop_collision(parent: Node3D, center: Vector3, size: Vector3, interaction_at: Vector3 = Vector3.INF) -> void:
	var body := StaticBody3D.new()
	body.name = "PropCollision"
	body.add_to_group("solid_props")
	body.set_meta("interaction_at", interaction_at)
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
