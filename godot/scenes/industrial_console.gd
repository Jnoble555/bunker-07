extends Node3D
## Original visual-only control console. Gameplay targets stay in room.gd/systems.

const PALETTE := {
	"armor": Color("45534b"),
	"edge": Color("788477"),
	"shadow": Color("18241f"),
	"display": Color("173b37"),
	"phosphor": Color("79d8c1"),
	"amber": Color("c99b55"),
}

func _ready() -> void:
	var armor := _material(PALETTE.armor, 0.48, 0.72)
	var edge := _material(PALETTE.edge, 0.52, 0.65)
	var shadow := _material(PALETTE.shadow, 0.76, 0.3)
	var glass := _material(PALETTE.display, 0.3, 0.18, PALETTE.phosphor, 0.48)
	var key_amber := _material(PALETTE.amber, 0.45, 0.22, PALETTE.amber, 0.28)
	var key_green := _material(PALETTE.phosphor, 0.38, 0.16, PALETTE.phosphor, 0.4)
	# Heavy pedestal and overhanging console body form a clear, waist-high silhouette.
	_box("Foot", Vector3(0, 0.08, 0), Vector3(0.76, 0.16, 0.62), shadow)
	_box("Plinth", Vector3(0.02, 0.48, 0), Vector3(0.48, 0.76, 0.46), armor)
	_box("PlinthSkirt", Vector3(0, 0.18, 0), Vector3(0.62, 0.16, 0.56), edge)
	_box("ConsoleHousing", Vector3(0, 0.94, 0), Vector3(0.82, 0.38, 0.72), armor)
	_box("LowerLip", Vector3(-0.425, 1.02, 0), Vector3(0.045, 0.13, 0.68), edge)
	# Angled, recessed screen faces toward -X, the approach side of the existing station.
	var bezel := _box("DisplayBezel", Vector3(-0.43, 1.34, 0), Vector3(0.06, 0.50, 0.68), shadow)
	bezel.rotation.z = 0.12
	var inset := _box("RecessedDisplay", Vector3(-0.49, 1.35, 0), Vector3(0.025, 0.34, 0.50), glass)
	inset.rotation.z = 0.12
	for side in [-1, 1]:
		var rail := _box("BezelSide_%d" % side, Vector3(-0.52, 1.34, side * 0.29), Vector3(0.045, 0.46, 0.08), edge)
		rail.rotation.z = 0.12
	for level in [-1, 1]:
		var rail := _box("BezelRail_%d" % level, Vector3(-0.52, 1.34 + level * 0.23, 0), Vector3(0.045, 0.08, 0.66), edge)
		rail.rotation.z = 0.12
	# Two status bars and a restrained readout pattern are geometry, not external textures.
	_box("ReadoutMain", Vector3(-0.509, 1.39, 0), Vector3(0.009, 0.025, 0.30), key_green)
	_box("ReadoutSub", Vector3(-0.509, 1.32, -0.06), Vector3(0.009, 0.016, 0.18), key_amber)
	_box("ReadoutSub2", Vector3(-0.509, 1.32, 0.16), Vector3(0.009, 0.016, 0.08), key_green)
	# Guarded physical keys and rotary controls on the front lip.
	for i in 4:
		var key := _cylinder("Key_%d" % i, Vector3(-0.455, 1.02, -0.24 + i * 0.16), 0.045, 0.035, key_amber if i == 0 else key_green)
		key.rotation.z = PI / 2.0
	for i in 2:
		var dial := _cylinder("Dial_%d" % i, Vector3(-0.455, 0.88, -0.15 + i * 0.3), 0.075, 0.04, edge)
		dial.rotation.z = PI / 2.0
		_box("DialMark_%d" % i, Vector3(-0.482, 0.94, -0.15 + i * 0.3), Vector3(0.015, 0.04, 0.012), key_amber)
	# Vent slots and fasteners give the lower casing a manufactured, serviceable finish.
	for i in 5:
		_box("Vent_%d" % i, Vector3(-0.425, 0.66, -0.18 + i * 0.09), Vector3(0.018, 0.035, 0.052), shadow)
	for x in [-0.29, 0.29]:
		_box("Fastener_%s" % str(x), Vector3(-0.425, 0.81, x), Vector3(0.018, 0.035, 0.035), edge)
	_box("ServiceBand", Vector3(0.253, 0.5, 0), Vector3(0.012, 0.34, 0.4), shadow)

func _material(color: Color, roughness: float, metallic: float, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

func _box(node_name: String, center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = center
	add_child(mesh)
	return mesh

func _cylinder(node_name: String, center: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	mesh.mesh = shape
	mesh.material_override = material
	mesh.position = center
	add_child(mesh)
	return mesh
