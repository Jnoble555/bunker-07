extends Node3D
## Original authored tactical operation. Geometry and nav share the same blockers.
const ConsoleScene = preload("res://scenes/industrial_console.tscn")
const CLEARANCE: float = 0.43
var cover_points: Array[Vector3] = []
var access_granted := false
var _built := false
var _graph := AStar3D.new()
var _blocked: Array[Rect2] = []
var _gate_rect := Rect2(Vector2(33.8,13),Vector2(0.4,4))
var _gate: StaticBody3D
var _gate_label: Label3D
var _materials: Dictionary = {}
var _screens: Dictionary = {}

func _ready() -> void:
	build()

func build() -> void:
	if _built: return
	_built = true
	_materials = {"wall":_material(Color("505b50"),0.94),"floor":_material(Color("39483e"),0.86),"steel":_material(Color("34473e"),0.62,0.65),"dark":_material(Color("17251e"),0.8),"trim":_material(Color("74816b"),0.6,0.55),"amber":_material(Color("b49a59"),0.7),"blue":_material(Color("4b6970"),0.74),"green":_material(Color("78af88"),0.65)}
	_solid("Floor",Vector3(32,-0.15,26),Vector3(64,0.3,52),"floor",false)
	_solid("Ceiling",Vector3(32,4.1,26),Vector3(64,0.2,52),"dark",false)
	_wall_x(1,1,51)
	_wall_x(63,1,51)
	_wall_z(1,1,63)
	_wall_z(51,1,63)
	# Entry/security division and the maintenance bypass.
	for span in [[1,9],[13,35],[39,51]]: _wall_x(20,span[0],span[1])
	for span in [[1,9],[13,20]]: _wall_z(20,span[0],span[1])
	for span in [[1,13],[17,28]]: _wall_x(34,span[0],span[1])
	for span in [[20,39],[43,63]]: _wall_z(28,span[0],span[1])
	for span in [[28,39],[43,51]]: _wall_x(52,span[0],span[1])
	# Optional armory has a single exposed side door and a defending rifle unit.
	for span in [[32,41],[44,51]]: _wall_x(8,span[0],span[1])
	_wall_z(32,1,8)
	_gate = _solid("AccessGate",Vector3(34,2,15),Vector3(0.4,4,4),"steel",false)
	_gate_label = _label("ACCESS LOCKED",Vector3(33.72,2.5,15),-PI/2,Color("d4b870"))
	# Large furniture deliberately leaves >0.86 m of navigable actor clearance.
	_solid("EntryDesk",Vector3(8,0.55,13),Vector3(3,1.1,1),"steel")
	_solid("SecurityRack",Vector3(25,1.1,8),Vector3(1.4,2.2,3),"steel")
	_solid("SecurityCover",Vector3(26,0.55,18),Vector3(3,1.1,1),"amber")
	_solid("SecurityPillar",Vector3(31,1.5,22),Vector3(1.5,3,1.5),"wall")
	_solid("MaintenancePump",Vector3(17,0.8,28),Vector3(2.6,1.6,2),"blue")
	_solid("Generator",Vector3(4,1,26),Vector3(4,2,3),"steel")
	_solid("MaintenanceCover",Vector3(15,0.55,34),Vector3(2,1.1,1),"amber")
	_solid("ArmoryRack",Vector3(3,0.8,49),Vector3(3,1.6,0.8),"steel")
	_solid("OperationsCover",Vector3(28,0.55,34),Vector3(4,1.1,1),"blue")
	_solid("OperationsPillar",Vector3(31,1.5,41),Vector3(1.4,3,1.4),"wall")
	_solid("GalleryCover",Vector3(48,0.55,32),Vector3(3,1.1,1),"blue")
	_solid("RearCover",Vector3(49,0.9,46),Vector3(2,1.8,1.2),"steel")
	_solid("LiftCover",Vector3(57,0.55,37),Vector3(3,1.1,1),"amber")
	_solid("LiftRack",Vector3(61,1,47),Vector3(1,2,3),"steel")
	# Raised data platform; ramp and .2 m stair risers are physically climbable.
	_solid("DataPlatform",Vector3(41,0.6,41.5),Vector3(10,1.2,9),"steel",false)
	_ramp()
	for i in 6:
		var height: float = (i+1)*0.2
		_solid("Stair_%d"%i,Vector3(50-(i+0.5)*2.0/3.0,height*0.5,41.5),Vector3(2.0/3.0,height,3),"trim",false)
	_solid("PlatformConsoleBank",Vector3(43,1.95,44),Vector3(2,1.5,0.7),"blue")
	# Safety rails preserve the broad ramp and stair openings.
	_solid("WestRail",Vector3(36.05,1.7,41.5),Vector3(0.1,1,9),"trim")
	_solid("SouthRail",Vector3(41,1.7,45.95),Vector3(10,1,0.1),"trim")
	_terminal("access",Vector3(12,0,40),"SERVICE ACCESS / E")
	_terminal("data",Vector3(41,1.2,41),"OPERATION ARCHIVE / E")
	_mesh("LiftPad",Vector3(59,0.02,41),Vector3(2,0.04,2),"green")
	for x in [57.6,60.4]:
		_solid("LiftPost",Vector3(x,1.3,42.5),Vector3(0.15,2.6,0.15),"steel")
		_mesh("LiftGuide",Vector3(x,1.5,42.4),Vector3(0.09,1.8,0.04),"green")
	_label("EXTRACTION / E",Vector3(59,2.8,42.6),PI,Color("9fceaa"))
	_label("SECURITY 01",Vector3(19.72,2.6,6),-PI/2,Color("d4b870"))
	_label("MAINTENANCE 02",Vector3(6,2.5,19.72),PI,Color("8cc7bb"))
	_label("OPERATIONS 03",Vector3(36,2.6,28.3),0,Color("99c3cc"))
	_label("ARMORY / LIVE LINE",Vector3(8.3,2.5,45),PI/2,Color("d4b870"))
	_environment()
	for entry in [[Vector3(8,3.8,7),Color("e3d4af")],[Vector3(27,3.8,12),Color("d9b281")],[Vector3(12,3.8,25),Color("c9b88c")],[Vector3(12,3.8,39),Color("b6d1bb")],[Vector3(4,3.8,44),Color("c79573")],[Vector3(42,3.8,16),Color("a8c2c8")],[Vector3(28,3.8,39),Color("a9c5c8")],[Vector3(40,3.8,32),Color("b3d0ca")],[Vector3(42,3.8,44),Color("b7cfca")],[Vector3(49,3.8,47),Color("bed0b1")],[Vector3(59,3.8,41),Color("a2d4b1")]]:
		_fixture(entry[0],entry[1])
	# Floor seams guide scale and make the three room arrangements legible.
	for x in range(4,64,4): _mesh("FloorJoint",Vector3(x,0.003,26),Vector3(0.018,0.004,49),"dark")
	for z in range(4,52,4): _mesh("FloorJoint",Vector3(32,0.003,z),Vector3(61,0.004,0.018),"dark")
	cover_points = [Vector3(26.4,0,8),Vector3(25,0,10.3),Vector3(29,0,18),Vector3(32.3,0,22),Vector3(18.9,0,28),Vector3(6.7,0,26),Vector3(16.7,0,34),Vector3(6,0,46),Vector3(32.3,0,41),Vector3(49,0,47.3),Vector3(44.8,1.2,44),Vector3(43,1.2,45.2),Vector3(58,0,38.15)]
	_rebuild_navigation()

func mission_contract() -> Dictionary:
	return {
		"id":"tactical-operation","title":"OPERATION: IRON RELAY","objective":"tactical_sequence",
		"briefing":"Restore service access in Maintenance, recover the raised Operations archive, then use the extraction lift. Security's locked east route opens with service access; Maintenance also offers a west approach. The live-line armory is optional. Use cover, lean and elevation against armed patrols.",
		"spawn":Vector3(8,0,7),"panel":Vector3(12,0,40),"core":Vector3(41,1.2,41),"exit":Vector3(59,0,41),
		"bots":[
			{"id":"security_smg_a","role":"tactical_smg","hp":3,"position":Vector3(26,0,11),"patrol":[Vector3(26,0,11),Vector3(29,0,13)]},
			{"id":"security_smg_b","role":"tactical_smg","hp":3,"position":Vector3(29,0,20),"patrol":[Vector3(29,0,20),Vector3(23,0,23)]},
			{"id":"security_rifle","role":"tactical_rifle","hp":4,"position":Vector3(30,0,6),"patrol":[Vector3(30,0,6),Vector3(31,0,12)]},
			{"id":"security_rear","role":"tactical_smg","hp":3,"position":Vector3(22,0,25),"patrol":[Vector3(22,0,25),Vector3(29,0,25)]},
			{"id":"maintenance_smg","role":"tactical_smg","hp":3,"position":Vector3(14,0,30),"patrol":[Vector3(14,0,30),Vector3(17,0,34)]},
			{"id":"armory_rifle","role":"tactical_rifle","hp":4,"position":Vector3(4,0,43),"patrol":[Vector3(4,0,40),Vector3(4,0,47)]},
			{"id":"operations_smg","role":"tactical_smg","hp":3,"position":Vector3(27,0,39),"patrol":[Vector3(27,0,39),Vector3(25,0,46)]},
			{"id":"gallery_smg","role":"tactical_smg","hp":3,"position":Vector3(48,0,33),"patrol":[Vector3(48,0,33),Vector3(50,0,36)]},
			{"id":"archive_rifle","role":"tactical_rifle","hp":4,"position":Vector3(40,1.2,44),"patrol":[Vector3(39,1.2,44),Vector3(44.8,1.2,45.2)]},
			{"id":"operations_rifle","role":"tactical_rifle","hp":4,"position":Vector3(48,0,48),"patrol":[Vector3(47,0,48),Vector3(50,0,48)]},
			{"id":"extraction_smg","role":"tactical_smg","hp":3,"position":Vector3(58,0,45),"patrol":[Vector3(58,0,45),Vector3(60,0,39)]}
		],
		"objectives":[{"id":"access","label":"RESTORE SERVICE ACCESS","position":Vector3(12,0,40)},{"id":"data","label":"RECOVER OPERATIONS ARCHIVE","position":Vector3(41,1.2,41)},{"id":"extract","label":"USE EXTRACTION LIFT","position":Vector3(59,0,41)}],
		"pickups":[{"id":"smg","label":"PICK UP SMG / 2 TO EQUIP","position":Vector3(11,0,7)},{"id":"supply","label":"ENTRY AMMUNITION","position":Vector3(10,0,7),"grants":{"pistol":24,"smg":48,"shotgun":8}},{"id":"supply","label":"MAINTENANCE SUPPLIES","position":Vector3(11,0,37),"grants":{"pistol":24,"smg":48,"shotgun":8},"health":25},{"id":"shotgun","label":"PICK UP SHOTGUN / 3 TO EQUIP","position":Vector3(4,0,45)},{"id":"supply","label":"ARMORY RESERVE","position":Vector3(4,0,47),"grants":{"pistol":24,"smg":48,"shotgun":8}},{"id":"supply","label":"OPERATIONS RESERVE","position":Vector3(29,0,45),"grants":{"pistol":24,"smg":48,"shotgun":8},"health":25},{"id":"supply","label":"LIFT EMERGENCY SUPPLIES","position":Vector3(59,0,47),"grants":{"pistol":24,"smg":48,"shotgun":8},"health":25}],
		"route_waypoints":{
			"to_access":[Vector3(8,0,7),Vector3(12,0,11),Vector3(12,0,23),Vector3(12,0,38.5)],
			"main_to_data":[Vector3(12,0,23),Vector3(12,0,11),Vector3(23,0,11),Vector3(28,0,15),Vector3(37,0,15),Vector3(41,0,15),Vector3(41,0,26),Vector3(41,0,30),Vector3(40,0.8,35),Vector3(40,1.2,38),Vector3(39.8,1.2,41)],
			"alternate_to_data":[Vector3(17,0,37),Vector3(23,0,37),Vector3(23,0,31),Vector3(33,0,31),Vector3(40,0,30),Vector3(40,0.8,35),Vector3(40,1.2,38),Vector3(39.8,1.2,41)],
			"to_extract":[Vector3(40,1.2,42.5),Vector3(44,1.2,42.5),Vector3(46,1.2,41.5),Vector3(49.8,0.2,41.5),Vector3(51,0,41.5),Vector3(54,0,41.5),Vector3(59,0,41)],
			"armory":[Vector3(10,0,38.5),Vector3(10,0,42.5),Vector3(6,0,42.5),Vector3(4,0,45)]
		}
	}

func set_access_granted(value: bool) -> void:
	if access_granted == value: return
	access_granted = value
	_gate.visible = not value
	_gate.collision_layer = 0 if value else 1
	_gate.get_node("Shape").set_deferred("disabled",value)
	_gate_label.text = "ACCESS OPEN" if value else "ACCESS LOCKED"
	set_objective_state("access",value)
	_rebuild_navigation()

func set_objective_state(id: String, complete: bool) -> void:
	if _screens.has(id):
		_screens[id].material_override = _material(Color("233e31") if complete else Color("4b8a78"),0.6)

func floor_height(at: Vector3) -> float:
	if at.x >= 36 and at.x <= 46 and at.z >= 37 and at.z <= 46: return 1.2
	if at.x >= 38 and at.x <= 42 and at.z >= 31 and at.z < 37: return (at.z-31)*0.2
	if at.x > 46 and at.x <= 50 and at.z >= 40 and at.z <= 43: return clampf(ceilf((50-at.x)/(2.0/3.0))*0.2,0.2,1.2)
	return 0.0

func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not _walkable(to) or absf(to.y-floor_height(to)) > 0.6: return PackedVector3Array()
	var start := _nearest_reachable_node(from)
	var end := _nearest_reachable_node(to)
	if start < 0 or end < 0: return PackedVector3Array()
	var points := _graph.get_point_path(start,end)
	if points.is_empty(): return points
	var result := PackedVector3Array()
	for point in points:
		if result.is_empty() or point.distance_to(from)>0.2: result.append(point)
	result.append(Vector3(to.x,floor_height(to),to.z))
	return result

func _nearest_reachable_node(at: Vector3) -> int:
	var closest := -1
	var best := INF
	for x in range(maxi(2,int(round(at.x))-2),mini(62,int(round(at.x))+2)+1):
		for z in range(maxi(2,int(round(at.z))-2),mini(50,int(round(at.z))+2)+1):
			var id := _id(x,z)
			if not _graph.has_point(id): continue
			var point := _graph.get_point_position(id)
			var distance := point.distance_squared_to(at)
			# A .36 m actor nudged into the conservative .43 m nav margin may escape.
			# This connection still keeps .38 m physical clearance and never crosses solids.
			if distance < best and _edge_clear(at,point,true): closest=id; best=distance
	return closest

func _rebuild_navigation() -> void:
	_graph.clear()
	for x in range(2,63):
		for z in range(2,51):
			var at := Vector3(x,0,z)
			at.y = floor_height(at)
			if _walkable(at): _graph.add_point(_id(x,z),at)
	for x in range(2,63):
		for z in range(2,51):
			var id := _id(x,z)
			if not _graph.has_point(id): continue
			for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,-1)]:
				var other := _id(x+offset.x,z+offset.y)
				if x+offset.x > 62 or z+offset.y < 2 or z+offset.y > 50 or not _graph.has_point(other): continue
				if _edge_clear(_graph.get_point_position(id),_graph.get_point_position(other)): _graph.connect_points(id,other,true)

func _id(x: int,z: int) -> int:
	return (x-2)*49+(z-2)

func _walkable(at: Vector3,relax_margin: bool=false) -> bool:
	if at.x < 1.6 or at.x > 62.4 or at.z < 1.6 or at.z > 50.4: return false
	# Keep graph waypoints inside the stair tread width, not on its side edges.
	# Escape connections may recover an actor nudged into that conservative ring.
	if not relax_margin and at.x >= 46 and at.x <= 50 and at.z >= 40 and at.z <= 43 and (at.z < 40.4 or at.z > 42.6): return false
	for rect: Rect2 in _blocked:
		var obstacle := rect.grow(-0.05) if relax_margin else rect
		if obstacle.has_point(Vector2(at.x,at.z)): return false
	return access_granted or not _gate_rect.grow(CLEARANCE-0.05 if relax_margin else CLEARANCE).has_point(Vector2(at.x,at.z))

func _edge_clear(from: Vector3,to: Vector3,relax_margin: bool=false) -> bool:
	var previous := floor_height(from)
	var samples := maxi(6,ceili(Vector2(from.x-to.x,from.z-to.z).length()*6))
	for i in range(samples+1):
		var at := from.lerp(to,float(i)/samples)
		if not _walkable(at,relax_margin): return false
		var height := floor_height(at)
		if absf(height-previous)>0.265: return false
		previous=height
	return true

func _material(color: Color,roughness: float,metallic: float=0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=roughness
	material.metallic=metallic
	return material

func _solid(id: String,at: Vector3,size: Vector3,kind: String,nav_block: bool=true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name=id
	body.position=at
	body.collision_layer=1
	body.collision_mask=0
	add_child(body)
	var shape := CollisionShape3D.new()
	shape.name="Shape"
	var box := BoxShape3D.new()
	box.size=size
	shape.shape=box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.mesh=BoxMesh.new()
	mesh.mesh.size=size
	mesh.material_override=_materials[kind]
	body.add_child(mesh)
	if nav_block: _blocked.append(Rect2(Vector2(at.x-size.x/2,at.z-size.z/2),Vector2(size.x,size.z)).grow(CLEARANCE))
	return body

func _mesh(id: String,at: Vector3,size: Vector3,kind: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name=id
	mesh.position=at
	mesh.mesh=BoxMesh.new()
	mesh.mesh.size=size
	mesh.material_override=_materials[kind]
	add_child(mesh)
	return mesh

func _wall_x(x: float,start: float,end: float) -> void:
	_solid("WallX",Vector3(x,2,(start+end)/2),Vector3(0.4,4,end-start),"wall")
	_mesh("SafetyBand",Vector3(x,0.9,(start+end)/2),Vector3(0.425,0.12,end-start),"amber")

func _wall_z(z: float,start: float,end: float) -> void:
	_solid("WallZ",Vector3((start+end)/2,2,z),Vector3(end-start,4,0.4),"wall")
	_mesh("SafetyBand",Vector3((start+end)/2,0.9,z),Vector3(end-start,0.12,0.425),"amber")

func _terminal(id: String,at: Vector3,text: String) -> void:
	var body := _solid(id.capitalize()+"Terminal",at+Vector3(0,0.8,0),Vector3(1.05,1.6,0.8),"steel")
	body.set_meta("interaction_at",at)
	var console := ConsoleScene.instantiate()
	console.position=at
	add_child(console)
	_screens[id]=console.get_node("RecessedDisplay")
	_label(text,at+Vector3(-0.1,2.0,0),-PI/2,Color("91c8b7"))

func _label(text: String,at: Vector3,yaw: float,color: Color) -> Label3D:
	var label := Label3D.new()
	label.text=text
	label.position=at
	label.rotation.y=yaw
	label.font_size=36
	label.pixel_size=0.0035
	label.modulate=color
	label.outline_size=4
	add_child(label)
	return label

func _fixture(at: Vector3,color: Color) -> void:
	_mesh("LampHousing",at,Vector3(1.5,0.12,0.6),"dark")
	_mesh("LampLens",at+Vector3(0,-0.08,0),Vector3(1.25,0.04,0.4),"trim")
	var light := OmniLight3D.new()
	light.position=at+Vector3(0,-0.35,0)
	light.light_color=color
	light.light_energy=1.5
	light.omni_range=15
	light.shadow_enabled=false
	add_child(light)

func _environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("101b16")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("9caea1")
	environment.ambient_light_energy=0.55
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=environment
	add_child(world)

func _ramp() -> void:
	var vertices := PackedVector3Array([Vector3(38,0,31),Vector3(42,0,31),Vector3(38,0,37),Vector3(42,0,37),Vector3(38,1.2,37),Vector3(42,1.2,37)])
	var body := StaticBody3D.new()
	body.name="ArchiveRamp"
	body.collision_layer=1
	body.collision_mask=0
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points=vertices
	collision.shape=shape
	body.add_child(collision)
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,4,1,1,4,5,0,2,4,1,5,3,2,3,4,3,5,4,0,1,2,1,3,2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var instance := MeshInstance3D.new()
	instance.mesh=mesh
	var material := _material(Color("74816b"),0.8,0.4)
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	instance.material_override=material
	body.add_child(instance)
