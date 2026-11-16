extends SceneTree
var checks := 0
var failures := 0
var game: Node

func _initialize() -> void: call_deferred("run")
func check(label: String, ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func frames(count: int) -> void:
	for i in count: await physics_frame
func stop_enemies() -> void:
	for enemy in game.enemies: enemy.set_physics_process(false)
func observation_count(kind: String) -> int:
	var count := 0
	for observation in game.security_director.get_active_observations():
		if observation.kind==kind: count += 1
	return count
func event_count(kind: String, run: int) -> int:
	var count := 0
	for event in game.events:
		if event.event==kind and event.run==run: count += 1
	return count
func run() -> void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	check("original title has no director",game.security_director==null)
	game.new_campaign()
	game.deploy_current()
	check("original campaign gameplay has no director",game.security_director==null and game.enemies[0].role=="scout")
	game.new_operation()
	check("Deep Signal briefing has no active director",game.security_director==null)
	game.deploy_current()
	stop_enemies()
	var director: RefCounted = game.security_director
	check("Deep Signal creates one mission-owned recorder before play",director!=null and director.get_mission_id()=="tactical-operation" and director.get_simulation_time()==0 and event_count("security_director_initialized",game.attempts)==1)
	check("director retains no scene ownership",director.get_class()=="RefCounted")
	game.player.set_physics_process(false)
	game.player.global_position=Vector3(18,0,19)
	var enemy: Node3D = game.enemies[0]
	enemy.global_position=Vector3(18,0,25)
	enemy.rotation.y=0
	enemy.patrol_points.assign([Vector3(18,0,25)])
	enemy.set_physics_process(true)
	await frames(5)
	check("real unoccluded sight produces passive contact",enemy.can_see_player() and observation_count("visual_contact")==1)
	check("existing sight memory and reaction remain active",enemy.last_known==game.player.camera.global_position and enemy.memory_remaining==8 and enemy.state=="suspicious")
	await frames(65)
	check("sustained vision refreshes once per second rather than per frame",observation_count("visual_contact")==2)
	check("director advances once per active controller tick",is_equal_approx(director.get_simulation_time(),game.elapsed))
	var last_seen: Vector3 = game.player.camera.global_position
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(12,4,.4)
	shape.shape=box
	wall.add_child(shape)
	wall.position=Vector3(18,1.5,22)
	game.add_child(wall)
	await frames(4)
	game.player.global_position=Vector3(21,0,19)
	await frames(4)
	var lost: Dictionary = director.get_observations_for(enemy.id)[-1]
	check("sight loss records last observed point once",observation_count("visual_lost")==1 and lost.kind=="visual_lost" and lost.position==last_seen)
	check("hidden movement does not update legacy sight memory",enemy.last_known==last_seen and enemy.memory_remaining<8)
	enemy.set_physics_process(false)
	var time_before: float = director.get_simulation_time()
	game.set_paused(true)
	await create_timer(.08,true).timeout
	enemy.hear_shot(Vector3(19,0,24))
	check("pause freezes clock and rejects observation hooks",director.get_simulation_time()==time_before and observation_count("sound_contact")==0)
	game.set_paused(false)
	await frames(3)
	check("resume advances recorder again",director.get_simulation_time()>time_before)
	game.open_journal()
	time_before=director.get_simulation_time()
	await create_timer(.05,true).timeout
	check("journal freezes recorder",director.get_simulation_time()==time_before)
	game.set_paused(false)
	game.open_settings()
	time_before=director.get_simulation_time()
	await create_timer(.05,true).timeout
	check("settings freezes recorder",director.get_simulation_time()==time_before)
	game.set_paused(false)
	enemy.state="patrol"
	var sound := Vector3(19,0,24)
	enemy.hear_shot(sound)
	check("audible event records snapshot without changing investigation",observation_count("sound_contact")==1 and enemy.last_known==sound and enemy.memory_remaining==7 and enemy.state=="suspicious")
	var count: int = director.get_active_observations().size()
	enemy.hear_shot(Vector3(48,0,48))
	check("inaudible event is not recorded",director.get_active_observations().size()==count)
	enemy.hear_shot(Vector3(20,0,24),true)
	check("legacy ally sharing still changes memory but is not sound evidence",enemy.last_known==Vector3(20,0,24) and director.get_active_observations().size()==count)
	enemy.receive_hit(1)
	check("legacy hidden-camera hit reaction preserved without legitimizing evidence",enemy.last_known==game.player.camera.global_position and director.get_active_observations().size()==count)
	# Exercise the real shot broadcast with no pellet collision required.
	game.player.global_position=Vector3(18,0,19)
	game.player.camera.rotation=Vector3.ZERO
	game.cooldown=0
	game.shoot()
	check("controller shot path emits one audible observation per guard",observation_count("sound_contact")>=2 and game.shots==1)
	enemy.receive_hit(100)
	count=director.get_active_observations().size()
	enemy.hear_shot(sound)
	check("dead enemy cannot emit further evidence",enemy.hp==0 and director.get_active_observations().size()==count)
	var only_values := true
	for observation in director.get_active_observations():
		for value in observation.values():
			if value is Object: only_values=false
	check("death leaves value snapshots without live actor references",only_values)
	var row: Dictionary = {}
	for event in game.events:
		if event.event=="security_observation": row=event
	var detail: Variant = JSON.parse_string(row.get("detail",""))
	check("telemetry keeps authored ID and structured evidence in existing columns",detail is Dictionary and detail.v==1 and detail.id>0 and detail.position is Array and row.bot_id==detail.observer_id)
	check("existing CSV exporter accepts structured telemetry",game.session.csv_text(game.events).contains("security_observation"))
	for i in 3:
		var prior: RefCounted = game.security_director
		game.retry_run()
		stop_enemies()
		check("retry %d replaces and clears old recorder" % i,game.security_director!=prior and prior.get_mission_id()=="" and prior.get_active_observations().is_empty() and game.security_director.get_simulation_time()==0 and game.security_director.get_active_observations().is_empty() and event_count("security_director_initialized",game.attempts)==1)
	var prior: RefCounted = game.security_director
	game.finish(false)
	check("defeat releases mission information",game.security_director==null and prior.get_mission_id()=="")
	game.retry_run()
	stop_enemies()
	prior=game.security_director
	game.finish(true)
	check("victory releases mission information",game.security_director==null and prior.get_active_observations().is_empty())
	game.retry_run()
	stop_enemies()
	prior=game.security_director
	game._abandon()
	check("abandon to title clears recorder",game.security_director==null and prior.get_mission_id()=="")
	game.new_operation()
	game.deploy_current()
	prior=game.security_director
	game.new_campaign()
	check("switching to campaign briefing clears Deep Signal state",game.security_director==null and prior.get_mission_id()=="")
	game.new_operation()
	game.deploy_current()
	prior=game.security_director
	game.queue_free()
	await frames(3)
	check("scene teardown clears retained recorder snapshots",prior.get_mission_id()=="" and prior.get_active_observations().is_empty())
	game=load("res://scenes/tactical_operation.tscn").instantiate()
	root.add_child(game)
	game.new_campaign()
	game.deploy_current()
	await frames(2)
	check("Iron Relay remains isolated and uses its own AI and navigation",game.security_director==null and game.enemies[0].get_script().resource_path=="res://scripts/tactical_enemy.gd" and game.room.has_method("find_path"))
	game.queue_free()
	await create_timer(.2,true).timeout
	print("SECURITY INTEGRATION: %d/%d passed; failures=%d" % [checks-failures,checks,failures])
	quit(1 if failures else 0)
