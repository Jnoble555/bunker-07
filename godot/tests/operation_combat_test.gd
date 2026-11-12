extends SceneTree
## Live production AI in the authored operation; stationary shooter isolates firing/perception.
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(n:int) -> void:
	for i in n: await physics_frame
func check(id:String,ok:bool) -> void:
	checks+=1
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failures+=1
func capture(id:String) -> void:
	if DisplayServer.get_name()=="headless": return
	# Hold the actual AI state for a reliable rendered snapshot.
	game._update_hud()
	paused=true
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/operation-combat-"+id+".png")
	paused=false
func run() -> void:
	game=load("res://scenes/tactical_operation.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.new_campaign()
	game.deploy_current()
	await frames(3)
	for actor in game.enemies: actor.set_physics_process(false)
	var enemy=game.enemies[0]
	enemy.reset_guard()
	enemy.rotation.y=PI/2
	enemy._speed=0
	game.player.global_position=Vector3(22,0,11)
	game.player.rotation.y=-PI/2
	game.player.velocity=Vector3.ZERO
	enemy.set_physics_process(true)
	for i in 180:
		await physics_frame
		if enemy.attack_windup>0: break
	check("live armed unit visibly prepares before firing",enemy.attack_windup>0 and enemy.shots_fired==0)
	await capture("windup")
	# Real world cover inserted during preparation must stop every pending shot.
	var cover:=StaticBody3D.new()
	cover.position=Vector3(24,1.5,11)
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(.2,3,6)
	shape.shape=box
	cover.add_child(shape)
	var mesh:=MeshInstance3D.new()
	var geometry:=BoxMesh.new()
	geometry.size=box.size
	mesh.mesh=geometry
	cover.add_child(mesh)
	game.add_child(cover)
	await frames(90)
	check("cover appearing during preparation prevents live damage",game.health==100 and enemy.shots_fired==0)
	var remembered:Vector3=enemy.last_known_position
	game.player.global_position=Vector3(22,0,12)
	await frames(160)
	check("lost-sight search retains remembered location",enemy.state=="search" and enemy.last_known_position==remembered)
	cover.queue_free()
	game.player.global_position=Vector3(22,0,11)
	for i in 240:
		await physics_frame
		if enemy.shots_fired>0: break
	check("reacquired target takes actual ray damage",enemy.shots_fired>0 and game.health<100)
	await capture("firing")
	for i in 900:
		await physics_frame
		if enemy.state=="reload": break
	check("live bursts exhaust magazine and enter reload",enemy.state=="reload" and enemy.magazine==0)
	await capture("reload")
	game.set_paused(true)
	var timer:float=enemy.reload_remaining
	var clock:float=game.elapsed
	await create_timer(.2,true).timeout
	check("pause freezes enemy reload and player clock",enemy.reload_remaining==timer and game.elapsed==clock)
	game.set_paused(false)
	await frames(160)
	check("live enemy completes finite reload",enemy.reserve<48 and enemy.magazine>0)
	print("OPERATION LIVE COMBAT ",checks-failures,"/",checks," failures=",failures)
	game.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
