extends SceneTree
## Integrated operation checks; traversal isolates AI, which has separate live combat tests.
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(id: String,ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failures += 1
func stop_enemies() -> void:
	for enemy in game.enemies: enemy.set_physics_process(false)
func place(at: Vector3) -> void:
	game.player.global_position=at
	game.player.velocity=Vector3.ZERO
	await frames(3)
func walk_to(at: Vector3) -> bool:
	for i in 1000:
		var delta: Vector3 = at-game.player.global_position
		delta.y=0
		if delta.length()<0.16:
			Input.action_release("move_forward")
			return absf(game.player.global_position.y-at.y)<0.3
		game.player.rotation.y=atan2(-delta.x,-delta.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	print("STUCK ",game.player.global_position," target ",at)
	return false
func route(points: Array) -> bool:
	for at: Vector3 in points:
		if not await walk_to(at): return false
	return true
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/operation-"+id+".png")
func slot(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode=key
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	await frames(2)
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
	await frames(1)
func run() -> void:
	game=load("res://scenes/tactical_operation.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	check("operation menu retains original campaign entry",game.operation_button.text=="Original Campaign" and game.campaign_button.text.contains("Operation"))
	await capture("title")
	game.new_campaign()
	check("operation briefing identifies objective sequence",game.menu_state=="briefing" and game.menu_text.text.contains("archive"))
	game.deploy_current()
	await frames(4)
	stop_enemies()
	check("operation spawns distinct armed roles",game.enemies.size()==11 and game.enemies[0].has_method("on_noise"))
	await capture("entry")
	var routes: Dictionary=game.mission.route_waypoints
	# Pickup and actual keyboard dispatch use the same production input path.
	await place(Vector3(10.5,0,7))
	game.interact()
	# Supply can be the first nearest object; collect again for the SMG if necessary.
	if not game.weapon_ammo.has("smg"): game.interact()
	check("operation entry SMG is collectible",game.weapon_ammo.has("smg"))
	await slot(KEY_2)
	check("real slot-two event reaches campaign override",game.weapon_id=="smg")
	await slot(KEY_1)
	check("real slot-one event restores independent pistol state",game.weapon_id=="pistol" and game.ammo==8)
	var saved_hp: Array = []
	for enemy in game.enemies:
		saved_hp.append(enemy.hp)
		enemy.hp = 0
	await place(game.mission.exit)
	game.interact()
	check("clearing all enemies cannot skip access and data at extraction",game.objective_stage==0 and game.active)
	for index in game.enemies.size(): game.enemies[index].hp = saved_hp[index]
	await place(game.mission.spawn)
	check("complete access approach uses real player collision",await route(routes.to_access))
	game.interact()
	check("access interaction advances stage and opens gate",game.objective_stage==1 and game.room.access_granted)
	await capture("access")
	# Archive cannot be recovered by reaching through the platform from ground level.
	await place(Vector3(41,0,36.5))
	game.interact()
	check("archive requires its elevated approach",game.objective_stage==1)
	await place(Vector3(12,0,38.5))
	check("optional armory route traverses to shotgun",await route(routes.armory))
	game.interact()
	check("risk side room grants shotgun",game.weapon_ammo.has("shotgun"))
	await slot(KEY_3)
	check("real slot-three event equips shotgun",game.weapon_id=="shotgun")
	await capture("shotgun")
	game.shoot()
	game.begin_reload()
	var mag: int=game.ammo
	var reserve: int=game.weapon_ammo.shotgun.reserve
	await slot(KEY_1)
	await slot(KEY_3)
	check("shotgun switch cancels reload without ammunition transfer",game.reload_remaining==0 and game.ammo==mag and game.weapon_ammo.shotgun.reserve==reserve)
	await place(Vector3(12,0,38.5))
	check("alternate maintenance route reaches archive",await route(routes.alternate_to_data))
	game.interact()
	check("archive collection advances extraction objective",game.objective_stage==2)
	await capture("archive")
	check("stairs and lift complete objective route",await route(routes.to_extract))
	game.interact()
	check("ordered objective path completes standalone operation",game.last_won and game.objective_stage==3 and game.objective_history==["access","data","extract"] and not game.active)
	check("multi-pellet accuracy cannot exceed one hundred percent",game.hits<=game.shots and game.last_result.accuracy<=100)
	await capture("complete")
	game.retry_run()
	await frames(4)
	stop_enemies()
	check("retry resets operation gate objectives inventory and pickups",game.objective_stage==0 and not game.room.access_granted and game.weapon_id=="pistol" and not game.weapon_ammo.has("shotgun") and not game.pickups[0].taken)
	game.begin_reload()
	game.set_paused(true)
	var elapsed: float=game.elapsed
	await create_timer(.15,true).timeout
	check("pause freezes operation clock",game.elapsed==elapsed)
	game.set_paused(false)
	game.damage_player(100,game.enemies[0].global_position)
	check("death produces retryable failure",not game.active and not game.last_won and game.menu_state=="result")
	game.retry_run()
	await frames(4)
	stop_enemies()
	check("death retry restores health and complete encounter",game.health==100 and game.enemies.size()==11 and game.objective_stage==0)
	print("OPERATION CHECKS ",checks-failures,"/",checks," failures=",failures)
	game.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
