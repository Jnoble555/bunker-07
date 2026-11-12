extends SceneTree
var game: Node
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(label: String, ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func capture(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/inventory-"+id+".png")
func run() -> void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	game.mission_index=0
	game.start_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	await frames(3)
	check("starts pistol only with finite reserve",game.weapon_id=="pistol" and game.ammo==8 and game.weapon_ammo.pistol.reserve==40 and not game.weapon_ammo.has("smg"))
	await capture("pistol")
	game.player.global_position=Vector3(8,0,4)
	await frames(3)
	check("distance prevents remote pickup",not game.collect_pickup() and not game.weapon_ammo.has("smg"))
	game.player.global_position=Vector3(4.3,0,4)
	await frames(3)
	var blocker := StaticBody3D.new()
	blocker.position=Vector3(4.65,1.2,4)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(0.1,2.4,1)
	shape.shape=box
	blocker.add_child(shape)
	game.add_child(blocker)
	await frames(3)
	check("obstacle blocks pickup",not game.collect_pickup() and not game.weapon_ammo.has("smg"))
	blocker.queue_free()
	await frames(3)
	game.interact()
	check("E acquires SMG without changing current weapon",game.weapon_ammo.has("smg") and game.weapon_id=="pistol")
	game.shoot()
	game.request_action("weapon_2")
	await frames(2)
	check("switch preserves independent pistol ammo",game.ammo==24 and game.weapon_ammo.pistol.magazine==7)
	await capture("smg")
	game.cooldown=0
	game.shoot()
	game.begin_reload()
	var reserve: int=game.weapon_ammo.smg.reserve
	game.switch_weapon("pistol")
	game.switch_weapon("smg")
	check("reload interruption neither transfers nor loses ammo",game.ammo==23 and game.weapon_ammo.smg.reserve==reserve and game.reload_remaining==0)
	game.begin_reload()
	await frames(25)
	await capture("reload")
	var remaining: float=game.reload_remaining
	game.set_paused(true)
	await create_timer(.15,true).timeout
	check("pause freezes reload",game.reload_remaining==remaining)
	game.set_paused(false)
	await frames(80)
	check("reload consumes only missing reserve",game.ammo==24 and game.weapon_ammo.smg.reserve==reserve-1)
	game.cooldown=0
	var before: int=game.shots
	Input.action_press("fire")
	await frames(30)
	Input.action_release("fire")
	var fired: int=game.shots-before
	check("automatic timing bounded by interval",fired>=4 and fired<=6)
	game.switch_weapon("pistol")
	game.cooldown=0
	before=game.shots
	Input.action_press("fire")
	await frames(20)
	Input.action_release("fire")
	check("pistol does not repeat held fire",game.shots==before)
	game.player.global_position=Vector3(6,0,4)
	await frames(3)
	var supplied: int=game.weapon_ammo.pistol.reserve
	game.interact()
	check("finite supply grants ammunition once",game.weapon_ammo.pistol.reserve==supplied+24 and game.pickups[1].taken and not game.collect_pickup())
	game.set_paused(true)
	game.switch_weapon("smg")
	check("pause rejects weapon switching",game.weapon_id=="pistol")
	game.set_paused(false)
	game.ammo=0
	game.weapon_ammo.pistol.reserve=0
	game.begin_reload()
	game.shoot()
	check("empty ammo and reserve cannot fire or reload",game.ammo==0 and game.reload_remaining==0)
	await capture("empty")
	game.retry_run()
	await frames(3)
	check("retry resets weapons ammo and pickups",game.weapon_id=="pistol" and game.ammo==8 and game.weapon_ammo.pistol.reserve==40 and not game.weapon_ammo.has("smg") and not game.pickups[0].taken)
	await capture("retry")
	game.mission_index=1
	game.start_run()
	await frames(3)
	check("mission transition uses fresh pistol inventory",game.weapon_id=="pistol" and game.ammo==8 and not game.weapon_ammo.has("smg") and not game.pickups[0].taken)
	var pickup_event := false
	var switch_event := false
	for row in game.events:
		if row.event=="weapon_pickup": pickup_event=true
		if row.event=="weapon_switched": switch_event=true
	check("pickup and switch analytics recorded compatibly",pickup_event and switch_event)
	print("INVENTORY ",checks-failures,"/",checks," failures=",failures)
	game.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
