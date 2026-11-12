extends SceneTree
const Ballistics = preload("res://scripts/shotgun_ballistics.gd")
const Definition = preload("res://scripts/shotgun_definition.gd")
var arena: Node3D
var checks := 0
var failures := 0
var no_exclusions: Array[RID] = []

func _initialize() -> void:
	call_deferred("run")

func frames(count: int = 3) -> void:
	for index in count:
		await physics_frame

func check(label: String, passed: bool) -> void:
	checks += 1
	print(("PASS " if passed else "FAIL ") + label)
	if not passed:
		failures += 1

func body(label: String, center: Vector3, size: Vector3, layer: int) -> StaticBody3D:
	var result := StaticBody3D.new()
	result.name = label
	result.position = center
	result.collision_layer = layer
	result.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	result.add_child(collision)
	arena.add_child(result)
	return result

func damage_sum(results: Array[Dictionary]) -> int:
	var total := 0
	for hit in results:
		total += int(hit.damage)
	return total

func fire(definition: Dictionary = Definition.DATA, excluded: Array[RID] = no_exclusions) -> Array[Dictionary]:
	seed(704)
	return Ballistics.cast(arena.get_world_3d(), Vector3(0,1.4,0), Basis.IDENTITY, excluded, definition)

func run() -> void:
	arena = Node3D.new()
	root.add_child(arena)
	var target := body("Target", Vector3(0,1.4,-4), Vector3(12,12,0.4), 4)
	await frames()
	var close_hits := fire()
	check("one physics result is returned per shotgun pellet",close_hits.size() == Definition.DATA.pellets)
	var all_close := true
	for hit in close_hits:
		all_close = all_close and hit.get("collider") == target and hit.distance < 5 and hit.damage == 1
	check("close blast resolves all pellets against reachable target",all_close)
	var close_damage := damage_sum(close_hits)
	target.position.z = -12
	await frames()
	var medium_damage := damage_sum(fire())
	check("damaging pellet count decreases at medium range",medium_damage > 0 and medium_damage < close_damage)
	target.position.z = -20
	await frames()
	check("damage is zero beyond effective falloff range",damage_sum(fire()) == 0)
	target.position.z = -29
	await frames()
	var misses := fire()
	var all_miss := true
	for hit in misses:
		all_miss = all_miss and not hit.has("collider") and not hit.hit and hit.damage == 0
	check("pellets cannot hit beyond ray range and misses remain explicit",all_miss)
	target.position.z = -4
	var wall := body("Occluder",Vector3(0,1.4,-2),Vector3(12,12,0.3),1)
	await frames()
	var all_wall := true
	for hit in fire():
		all_wall = all_wall and hit.get("collider") == wall
	check("every pellet is occluded by its nearest full cover",all_wall)
	wall.position.x = -1
	var wall_shape: BoxShape3D = wall.get_child(0).shape
	wall_shape.size.x = 2
	await frames()
	var wall_hits := 0
	var target_hits := 0
	for hit in fire():
		if hit.get("collider") == wall: wall_hits += 1
		if hit.get("collider") == target: target_hits += 1
	check("partial cover blocks individual pellets without hiding exposed target",wall_hits > 0 and target_hits > 0 and wall_hits + target_hits == Definition.DATA.pellets)
	var excluded: Array[RID] = [wall.get_rid()]
	var excluded_ok := true
	for hit in fire(Definition.DATA, excluded):
		excluded_ok = excluded_ok and hit.get("collider") == target
	check("explicit exclusions are respected for all pellets",excluded_ok)
	wall.queue_free()
	await frames()
	var single := fire({"range":50.0,"damage":1,"spread":0.0})
	check("single precise weapon retains exact camera direction",single.size() == 1 and single[0].direction.is_equal_approx(Vector3.FORWARD) and single[0].get("collider") == target)
	var proxy := body("ShooterProxy",Vector3(0,1.4,0),Vector3(1,3,1),4)
	await frames()
	var inside := fire({"range":50.0,"damage":1,"spread":0.0})
	check("inside-origin hits remain available for integration's behind-camera guard",inside[0].get("collider") == proxy and inside[0].distance < 0.001)
	excluded = [proxy.get_rid()]
	var excluded_shooter := fire({"range":50.0,"damage":1,"spread":0.0}, excluded)
	check("shooter RID exclusion prevents self hits",excluded_shooter[0].get("collider") == target)
	proxy.queue_free()
	var device := Area3D.new()
	device.position = Vector3(0,1.4,-2)
	device.collision_layer = 8
	device.collision_mask = 0
	device.monitoring = false
	device.monitorable = false
	var device_shape := CollisionShape3D.new()
	var device_box := BoxShape3D.new()
	device_box.size = Vector3(6,6,0.2)
	device_shape.shape = device_box
	device.add_child(device_shape)
	arena.add_child(device)
	await frames()
	var devices_ok := true
	for hit in fire():
		devices_ok = devices_ok and hit.get("collider") == device
	check("device areas participate in each nearest-surface ray",devices_ok)
	check("pellet damage helper rejects invalid distances",Ballistics.pellet_damage(-1, Definition.DATA) == 0 and Ballistics.pellet_damage(INF,Definition.DATA) == 0)
	var packed := load("res://assets/weapons/security_shotgun.glb") as PackedScene
	var model := packed.instantiate()
	check("GLB exposes shared animation part names",model.find_child("Slide",true,false) != null and model.find_child("Magazine",true,false) != null and model.find_child("MagazineBase",true,false) != null)
	if DisplayServer.get_name() != "headless":
		await preview_asset(model)
	else:
		model.free()
	print("SHOTGUN ",checks-failures,"/",checks," failures=",failures)
	arena.queue_free()
	await process_frame
	quit(1 if failures else 0)

func preview_asset(model: Node3D) -> void:
	# Asset-only inspection; gameplay framing is validated by the integration owner.
	arena.add_child(model)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("26332e")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c0c7c2")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	arena.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-35,0)
	light.light_energy = 0.85
	arena.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0.65,0.30,0.70)
	camera.fov = 40
	arena.add_child(camera)
	camera.look_at(Vector3(0,0,-0.05))
	camera.current = true
	await frames(4)
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/campaign-screenshots/shotgun-asset.png"
	var saved := root.get_texture().get_image().save_png(path)
	check("isolated graphical asset preview saves successfully",saved == OK)
