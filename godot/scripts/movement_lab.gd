extends "res://scripts/campaign_main.gd"
## Standalone sandbox; objective coordinates remain far away and no extraction is possible.
func _ready() -> void:
	super._ready()
	start_run()

func start_run() -> void:
	mission_index = 1
	super.start_run()
	for enemy in enemies: enemy.queue_free()
	enemies.clear()
	if guard: guard = null
	remove_child(room)
	room.queue_free()
	room = Node3D.new()
	add_child(room)
	box("Floor", Vector3(100,-0.2,100), Vector3(20,0.4,20))
	box("LowCover",Vector3(100,0.5,100),Vector3(3,1,0.5))
	box("Headroom",Vector3(96,1.5,100),Vector3(3,0.4,3))
	box("HeadroomPost",Vector3(94.6,0.65,100),Vector3(0.2,1.3,3))
	var ramp := box("Ramp",Vector3(103,0.5,99),Vector3(2,0.2,5))
	ramp.rotation.x = 0.2
	for i in 6:
		box("Stair%d"%i,Vector3(106,(i+1)*0.1,101-i*0.5),Vector3(2,(i+1)*0.2,0.5))
	box("Platform",Vector3(104.5,0.5,96),Vector3(5,1,2))
	box("Boundary",Vector3(100,1.5,90),Vector3(20,3,0.4))
	box("BoundarySouth",Vector3(100,1.5,110),Vector3(20,3,0.4))
	box("BoundaryWest",Vector3(90,1.5,100),Vector3(0.4,3,20))
	box("BoundaryEast",Vector3(110,1.5,100),Vector3(0.4,3,20))
	var environment := WorldEnvironment.new()
	var lighting := Environment.new()
	lighting.background_mode = Environment.BG_COLOR
	lighting.background_color = Color("26332e")
	lighting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.ambient_light_energy = 0.8
	environment.environment = lighting
	room.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50,-30,0)
	room.add_child(light)
	player.global_position = Vector3(100,0,105)
	player.rotation.y = 0
	for entry in [["LOW COVER",Vector3(100,1.7,100)],["CROUCH BAY",Vector3(96,2.0,100)],["RAMP",Vector3(103,2.0,98)],["STAIRS",Vector3(106,2.0,99)]]:
		var label := Label3D.new()
		label.text = entry[0]
		label.position = entry[1]
		label.font_size = 32
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		room.add_child(label)
	announce("MOVEMENT LAB / cover ahead; crouch bay left; ramp and stairs right. F5 resets. No campaign progress.")

func box(id: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	room.add_child(body)
	var shape := CollisionShape3D.new()
	var resource := BoxShape3D.new()
	resource.size = size
	shape.shape = resource
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("88744f") if id == "LowCover" else Color("536878") if id.begins_with("Headroom") else Color("6f8668") if id == "Ramp" else Color("667d77")
	mesh.material_override = material
	body.add_child(mesh)
	return body

func _update_hud() -> void:
	super._update_hud()
	if not hud: return
	hud.text = "MOVEMENT LAB / NO CAMPAIGN PROGRESS"
	status.text = "WASD / Ctrl crouch / Shift sprint / Q,C lean / RMB aim / E interact / F5 reset"
