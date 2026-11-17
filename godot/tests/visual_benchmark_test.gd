extends SceneTree
## Controlled camera benchmark + actual encounter contracts. Not a human combat playthrough.
var game: Node
var failures := 0
var checks := 0
var folder := "res://../docs/godot/visual-benchmark"
var baseline := false

func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for index in n: await physics_frame
func check(id: String, ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failures += 1
func geometry(world: Node3D) -> Array[String]:
	var result: Array[String] = []
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		for shape in body.get_children():
			if shape is CollisionShape3D:
				result.append(str(shape.global_transform)+str(shape.shape.size if shape.shape is BoxShape3D else shape.shape.get_class())+str(body.collision_layer))
	result.sort()
	return result
func capture(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var code := root.get_texture().get_image().save_png(folder+"/"+id+".png")
	check("capture "+id,code==OK)
func place(at: Vector3, target: Vector3) -> void:
	game.player.global_position = at
	game.player.velocity = Vector3.ZERO
	game.player.rotation.y = atan2(at.x-target.x,at.z-target.z)
	game.player.pitch = 0
	await frames(4)
	game._update_hud()

func run() -> void:
	create_timer(90,true).timeout.connect(func():
		push_error("Visual benchmark timed out")
		quit(1))
	baseline = "--benchmark-baseline" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var original = load("res://scenes/control_room.tscn").instantiate()
	root.add_child(original)
	original.new_operation()
	original.deploy_current()
	await frames(3)
	var expected_geometry := geometry(original.room)
	var expected_cover: Array = original.room.cover_points.duplicate()
	var expected_path: Array = original.room.tactical_path(original.mission.spawn,original.mission.panel)
	original.queue_free()
	await frames(3)
	game = load("res://scenes/deep_signal_visual_benchmark.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	for enemy in game.enemies: enemy.set_physics_process(false)
	check("showcase starts actual Deep Signal",game.operation_mode and game.mission.title=="DEEP SIGNAL" and game.active)
	check("all eight mission actors retained",game.enemies.size()==8)
	check("world collision shapes and transforms unchanged",geometry(game.room)==expected_geometry)
	check("cover and navigation path unchanged",game.room.cover_points==expected_cover and game.room.tactical_path(game.mission.spawn,game.mission.panel)==expected_path)
	check("visual layer opt-in and batched",game.art==null if baseline else game.art.module_count>30 and game.art.find_children("*","MultiMeshInstance3D",true,false).size()>0)
	var renderer := RenderingServer.get_current_rendering_method()
	var prefix := ("before" if baseline else "after")+"-"+renderer
	var views := [
		["entry",Vector3(5,0,44),Vector3(22,1.5,38)],
		["security",Vector3(20,0,42),Vector3(23,1.4,39)],
		["maintenance",Vector3(8,0,29),Vector3(7,1.4,17)],
		["operations",Vector3(38,1.2,13),Vector3(43,2.6,7)],
		["guard-detail",Vector3(40,1.2,11),Vector3(37,2.0,9)]
	]
	for view in views:
		await place(view[1],view[2])
		if view[0] == "guard-detail":
			for enemy in game.enemies:
				if enemy.global_position.distance_to(Vector3(37,1.2,9)) < 0.5:
					enemy.look_at(game.player.camera.global_position,Vector3.UP)
		await frames(8)
		await capture(prefix+"-"+view[0])
	# Warm static security view, uncap vsync, then record actual wall-clock frame times.
	if DisplayServer.get_name() != "headless":
		await place(Vector3(20,0,42),Vector3(23,1.4,39))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await frames(90)
		var times: Array[float] = []
		var previous := Time.get_ticks_usec()
		for index in 180:
			await process_frame
			var now := Time.get_ticks_usec()
			times.append((now-previous)/1000.0)
			previous = now
		times.sort()
		var total := 0.0
		for value in times: total += value
		var data := {"renderer":renderer,"baseline":baseline,"resolution":"1280x720","samples":times.size(),"mean_ms":total/times.size(),"p50_ms":times[90],"p95_ms":times[171],"mean_fps":1000.0/(total/times.size()),"ai":"frozen for controlled comparison","vsync":"disabled","engine":Engine.get_version_info().string,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		var file := FileAccess.open(folder+"/"+prefix+".json",FileAccess.WRITE)
		file.store_string(JSON.stringify(data,"\t")+"\n")
		file.close()
		print("BENCHMARK ",JSON.stringify(data))
	# Actual objective interaction at normal reach, with and without intervening geometry.
	await place(Vector3(23,0,40.4),Vector3(23,1.35,39))
	var wall := StaticBody3D.new()
	wall.position = Vector3(23,1.5,39.7)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2,3,0.1)
	collider.shape = shape
	wall.add_child(collider)
	game.add_child(wall)
	await frames(3)
	game.interact()
	check("world obstacle blocks terminal interaction",game.operation_stage==0)
	wall.queue_free()
	await frames(3)
	game.interact()
	check("normal approach operates access terminal",game.operation_stage==1)
	await capture(prefix+"-access-used")
	game.shoot()
	game.begin_reload()
	game.set_paused(true)
	var timer: float = game.reload_remaining
	var clock: float = game.elapsed
	await create_timer(.15,true).timeout
	check("pause freezes actual reload and gameplay clock",timer>0 and game.reload_remaining==timer and game.elapsed==clock)
	game.set_paused(false)
	game.retry_run()
	await frames(3)
	for enemy in game.enemies: enemy.set_physics_process(false)
	check("retry rebuilds visuals once and resets encounter",game.operation_stage==0 and game.ammo==8 and game.enemies.size()==8 and (game.art==null if baseline else game.room.get_node_or_null("ControlRoomArt")==game.art))
	print("VISUAL BENCHMARK CHECKS ",checks-failures,"/",checks," failures=",failures)
	game.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
