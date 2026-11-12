extends SceneTree
## Integrated physical traversal + new combat contracts; enemies isolated during route checks.
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(label: String, ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures += 1
func stop_enemies() -> void:
	for enemy in game.enemies: enemy.set_physics_process(false)
func fresh() -> void:
	game.new_operation()
	game.deploy_current()
	stop_enemies()
	await frames(4)
func walk_to(target: Vector3) -> bool:
	var path: Array[Vector3] = game.room.tactical_path(game.player.global_position,target)
	if path.is_empty():
		print("NO PATH ",game.player.global_position," -> ",target)
		return false
	for point in path:
		var reached := false
		for i in 120:
			var offset: Vector3 = point-game.player.global_position
			offset.y = 0
			if offset.length()<.18:
				reached = true
				break
			if not game.active:
				Input.action_release("move_forward")
				return game.last_won
			game.player.rotation.y = atan2(-offset.x,-offset.z)
			Input.action_press("move_forward")
			await physics_frame
		Input.action_release("move_forward")
		if not reached:
			print("BLOCKED ",game.player.global_position," -> ",point)
			return false
	return true
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/tactical-screenshots/"+id+".png")
func aim(at: Vector3) -> void:
	game.player.camera.look_at(at,Vector3.UP)
func run() -> void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	check("title retains campaign and adds operation",game.campaign_button.visible and game.operation_button.visible)
	await capture("title")
	await fresh()
	check("separate operation has eight armed enemies and pistol start",game.mission.id=="tactical-operation" and game.enemies.size()==8 and game.weapon_id=="pistol")
	game.player.rotation.y=0
	await capture("entry")
	# Attempting data collection before restoring access does nothing.
	game.player.global_position=Vector3(43,1.2,6)
	await frames(3)
	game.interact()
	check("data cannot skip access objective",game.operation_stage==0)
	var navigator: Node3D = game.enemies[5]
	navigator.global_position=Vector3(38,0,23)
	navigator.patrol_points.assign([Vector3(38,1.2,12)])
	game.player.global_position=Vector3(5,0,44)
	navigator.set_physics_process(true)
	await frames(700)
	navigator.set_physics_process(false)
	check("armed enemy follows authored navigation up ramp",navigator.global_position.y>1.1 and navigator.global_position.z<15)
	var all_routes := true
	for bot: Dictionary in game.mission.bots:
		if game.room.tactical_path(bot.position,game.mission.spawn).is_empty(): all_routes=false
	check("all authored enemy spawns connect to operation navigation",all_routes)
	game.player.global_position=game.mission.spawn
	await frames(3)
	check("maintenance alternate route physically traversable",await walk_to(Vector3(8,0,23)))
	check("security terminal reachable from alternate route",await walk_to(Vector3(23,0,38)))
	game.interact()
	check("access terminal advances once",game.operation_stage==1)
	game.interact()
	check("repeated terminal cannot duplicate progression",game.operation_stage==1)
	check("relay route reaches ramp base",await walk_to(Vector3(38,0,23)))
	check("striped ramp physically reaches upper deck",await walk_to(Vector3(38,1.2,14)))
	check("player stands on elevated collision",game.player.global_position.y>1.1)
	check("archive reachable upstairs",await walk_to(Vector3(43,1.2,6)))
	game.interact()
	check("data recovery advances extraction objective",game.operation_stage==2 and game.core_collected)
	game.player.rotation.y=PI
	await capture("operations")
	check("complete objective path extracts",await walk_to(game.mission.exit) and game.last_won)
	await capture("result")
	game.advance_campaign()
	check("operation results return to title",game.menu_state=="title")
	await fresh()
	check("direct security route physically traversable",await walk_to(Vector3(23,0,38)))
	check("optional armory physically reachable",await walk_to(Vector3(44,0,42)))
	game.interact()
	check("shotgun collected with independent finite ammo",game.weapon_ammo.has("shotgun") and game.weapon_ammo.shotgun.magazine==4 and game.weapon_id=="pistol")
	var key := InputEventKey.new()
	key.physical_keycode=KEY_3
	key.pressed=true
	game._unhandled_input(key)
	await frames(2)
	check("actual slot-3 input equips shotgun",game.weapon_id=="shotgun" and game.ammo==4)
	game.player.global_position=Vector3(38,0,26)
	await frames(3)
	aim(Vector3(38,1.4,20))
	await capture("shotgun")
	# A wide target tests every pellet, not a probabilistic small target.
	var enemy: Node3D = game.enemies[0]
	enemy.global_position=Vector3(38,0,23)
	enemy.hp=100
	await frames(3)
	game.cooldown=0
	aim(enemy.global_position+Vector3.UP*1.2)
	seed(71)
	game.shoot()
	check("shotgun close blast applies several pellets but one accuracy hit",enemy.hp<99 and game.hits==1 and game.shots==1 and game.ammo==3)
	var shield := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(8,4,.3)
	shape.shape=box
	shield.add_child(shape)
	shield.position=Vector3(38,1.5,24.5)
	game.add_child(shield)
	await frames(3)
	var hp: int=enemy.hp
	game.cooldown=0
	game.shoot()
	check("every shotgun pellet respects solid occlusion",enemy.hp==hp and game.hits==1 and game.shots==2)
	shield.queue_free()
	await frames(3)
	# Range check uses a clean line crossing the large relay room.
	game.player.global_position=Vector3(18,0,25)
	enemy.global_position=Vector3(39,0,25)
	await frames(3)
	aim(enemy.global_position+Vector3.UP*1.2)
	game.cooldown=0
	game.shoot()
	check("shotgun cannot hit beyond 18m",enemy.hp==hp)
	game.begin_reload()
	var reserve: int=game.weapon_ammo.shotgun.reserve
	game.switch_weapon("pistol")
	game.switch_weapon("shotgun")
	check("shotgun switch cancels reload without ammo transfer",game.reload_remaining==0 and game.ammo==1 and game.weapon_ammo.shotgun.reserve==reserve)
	game.begin_reload()
	var before: float=game.reload_remaining
	game.set_paused(true)
	await create_timer(.12,true).timeout
	game.interact()
	game.shoot()
	check("pause freezes shotgun and operation interactions",game.reload_remaining==before and game.ammo==1 and game.operation_stage==0)
	game.set_paused(false)
	game.damage_player(100,enemy.global_position)
	check("death produces retryable failure",not game.active and not game.last_won and game.menu_state=="result")
	game.retry_run()
	stop_enemies()
	await frames(3)
	check("retry resets enemies objectives pickups and inventory",game.operation_stage==0 and game.enemies[0].hp==5 and not game.pickups[0].taken and not game.weapon_ammo.has("shotgun") and game.ammo==8)
	game.new_campaign()
	game.deploy_current()
	check("original campaign still starts Breach with old scout",not game.operation_mode and game.mission.id=="breach" and game.enemies[0].role=="scout")
	print("TACTICAL OPERATION ",checks-failures,"/",checks," failures=",failures)
	game.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
