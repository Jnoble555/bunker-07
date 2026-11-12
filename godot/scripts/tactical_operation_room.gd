extends "res://scripts/room.gd"
## Reusable industrial room kit and explicit capsule-clearance navigation graph.
## Navigation derives from the same authored solid rectangles as rendered geometry.
var cover_points: Array[Vector3] = []
var navigation := AStar3D.new()
var solids: Array[AABB] = []
var _nav_cells: Dictionary = {}
var _access_light: MeshInstance3D
var _archive: Node3D

func build(config: Dictionary = {}) -> void:
	_config = config
	mission_id = "tactical-operation"
	_make_materials()
	_make_environment()
	var environment: Environment = get_node("BunkerEnvironment").environment
	environment.ambient_light_color = Color("c3cec9")
	environment.ambient_light_energy = 0.85
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_solid_box("Foundation",Vector3(25,-0.2,25),Vector3(50,0.4,50),_materials.floor)
	_solid_box("Roof",Vector3(25,5.5,25),Vector3(50,0.3,50),_materials.ceiling)
	wall("West",Vector3(0,2.7,25),Vector3(1,5.4,50))
	wall("East",Vector3(50,2.7,25),Vector3(1,5.4,50))
	wall("North",Vector3(25,2.7,0),Vector3(50,5.4,1))
	wall("South",Vector3(25,2.7,50),Vector3(50,5.4,1))
	# Three north/south sectors; wide doors and separate approaches avoid single-file traps.
	for z: float in [16.0,32.0]:
		for span: Vector2 in [Vector2(0.5,6),Vector2(10,22),Vector2(28,35),Vector2(41,49.5)]:
			wall("SectorWall",Vector3((span.x+span.y)/2,2.7,z),Vector3(span.y-span.x,5.4,0.5))
	for x: float in [16.0,32.0]:
		for span: Vector2 in [Vector2(0.5,16),Vector2(18,23),Vector2(27,38),Vector2(43,49.5)]:
			wall("Partition",Vector3(x,2.7,(span.x+span.y)/2),Vector3(.5,5.4,span.y-span.x))
	# Northeast operations platform. Its only approach is the 6m striped ramp.
	_solid_box("OperationsDeck",Vector3(41.25,0.5,8),Vector3(17,1.4,15.5),_materials.steel)
	var ramp := _solid_box("AccessRamp",Vector3(38,0.6-0.1/cos(atan(.2)),19),Vector3(6,.2,sqrt(37.44)),_materials.steel)
	ramp.rotation.x = atan(.2)
	# Railings leave 5m clear travel width; stop falls off the elevated deck edge.
	wall("DeckWestRail",Vector3(33,1.7,8),Vector3(.2,1,15))
	wall("DeckSouthRailA",Vector3(33.8,1.7,15.7),Vector3(2.4,1,.2))
	wall("DeckSouthRailB",Vector3(45.4,1.7,15.7),Vector3(8.8,1,.2))
	for p: Vector3 in [Vector3(20,0,41),Vector3(27,0,35),Vector3(22,0,28),Vector3(11,0,27),Vector3(6,0,19),Vector3(24,0,23),Vector3(29,0,20),Vector3(42,0,29),Vector3(44,0,36),Vector3(40,0,44),Vector3(41,1.2,10),Vector3(46,1.2,13),Vector3(36,1.2,5)]:
		cover(p)
	terminal("ACCESS / E",config.panel,Color("e0ad55"))
	terminal("DEEP SIGNAL / E",config.core,Color("79d7d8"))
	_archive = get_child(get_child_count()-1)
	_mesh_box(self,"LiftPad",config.exit+Vector3(0,.04,0),Vector3(3,.08,3),_materials.cyan)
	for sign: Array in [["01 / SECURITY",Vector3(24,3,44)],["02 / MAINTENANCE",Vector3(7,3,28)],["03 / RELAY",Vector3(24,3,23)],["ARMORY / OPTIONAL",Vector3(42,3,44)],["04 / OPERATIONS",Vector3(43,3.6,8)],["EXTRACTION",Vector3(45,3.6,3)]]:
		_label(sign[0],sign[1],Vector3.ZERO,Color("d5e7dc"),self,48,.004,5)
	for z in [8,24,40]:
		for x in [8,24,42]:
			var color := Color("74bab0") if x==8 else Color("e9b77b") if z==40 else Color("9cbdd2")
			_light(Vector3(x,4.4,z),color,2.2,18)
			_mesh_box(self,"CeilingStrip",Vector3(x,5.2,z),Vector3(3,.07,.3),_materials.cyan)
	# Strong floor landmarks without collision clutter.
	for z in range(4,49,3):
		_mesh_box(self,"MaintenanceGuidance",Vector3(8,.012,z),Vector3(.12,.024,1.4),_materials.cyan)
	for z in range(16,23):
		_mesh_box(self,"RampStripe",Vector3(38,height_at(Vector3(38,0,z))+.03,z),Vector3(5,.025,.08),_materials.cyan)
	_build_navigation()

func wall(id: String, center: Vector3, size: Vector3) -> void:
	_solid_box(id,center,size,_materials.concrete)
	solids.append(AABB(center-size/2,size))

func cover(at: Vector3) -> void:
	var size := Vector3(2.4,1.25,1.2)
	_solid_box("SolidCover",at+Vector3(0,.625,0),size,_materials.steel)
	solids.append(AABB(at+Vector3(0,.625,0)-size/2,size))
	_mesh_box(self,"CoverStripe",at+Vector3(0,1.15,-.61),Vector3(2.2,.12,.025),_materials.cyan)
	for offset: Vector3 in [Vector3(0,0,1.5),Vector3(0,0,-1.5),Vector3(2,0,0),Vector3(-2,0,0)]:
		cover_points.append(at+offset)

func terminal(text: String, at: Vector3, color: Color) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	_solid_box("TerminalHousing",Vector3(0,.65,.35),Vector3(.8,1.3,.5),_materials.steel,node)
	solids.append(AABB(at+Vector3(-.4,0,.1),Vector3(.8,1.3,.5)))
	_mesh_box(node,"Screen",Vector3(0,1.35,.09),Vector3(.65,.4,.08),_emissive(color,1.2))
	_label(text,Vector3(0,2.1,0),Vector3.ZERO,color,node,30,.002,4)

func height_at(at: Vector3) -> float:
	if at.x>=32.75 and at.z<=15.75: return 1.2
	if at.x>=35 and at.x<=41 and at.z>=16 and at.z<=22: return (22-at.z)*.2
	return 0.0

func navigable(at: Vector3) -> bool:
	if at.x<1.2 or at.x>48.8 or at.z<1.2 or at.z>48.8: return false
	for solid in solids:
		# Ground-plane clearance includes cover, walls and railings at this height.
		if at.y+1.6<solid.position.y or at.y>solid.end.y: continue
		if at.x>solid.position.x-.48 and at.x<solid.end.x+.48 and at.z>solid.position.z-.48 and at.z<solid.end.z+.48: return false
	return true

func _build_navigation() -> void:
	for z in range(1,49):
		for x in range(1,49):
			var at := Vector3(x+.5,0,z+.5)
			at.y = height_at(at)
			if not navigable(at): continue
			var id := z*50+x
			navigation.add_point(id,at)
			_nav_cells[Vector2i(x,z)] = id
	for cell: Vector2i in _nav_cells:
		for offset: Vector2i in [Vector2i(1,0),Vector2i(0,1)]:
			if not _nav_cells.has(cell+offset): continue
			var a: int = _nav_cells[cell]
			var b: int = _nav_cells[cell+offset]
			if absf(navigation.get_point_position(a).y-navigation.get_point_position(b).y)>.3: continue
			navigation.connect_points(a,b)
	var valid: Array[Vector3] = []
	for at in cover_points:
		if navigable(at): valid.append(at)
	cover_points = valid

func tactical_path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var path: Array[Vector3] = []
	if navigation.get_point_count()==0: return path
	# Refuse destinations embedded in cover or off the deck; never snap through walls.
	var destination := to
	destination.y = height_at(to)
	if not navigable(destination): return path
	var start := navigation.get_closest_point(from)
	var end := navigation.get_closest_point(destination)
	if navigation.get_point_position(end).distance_to(destination)>1.6: return path
	for point in navigation.get_point_path(start,end): path.append(point)
	if not path.is_empty(): path.append(destination)
	return path
