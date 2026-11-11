extends SceneTree
var game: Node
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/weapon-"+name+".png")
func run() -> void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.start_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	await frames(3)
	await shot("idle")
	Input.action_press("move_forward")
	await frames(5)
	Input.action_release("move_forward")
	await shot("movement")
	game.shoot()
	game._update_hud()
	# Hold the controller-triggered firing state for a reliable GPU capture.
	paused = true
	game.player.weapon.pose(game.flash, 0)
	game.player.muzzle.visible = true
	game.player.muzzle_light.light_energy = 1.3
	await shot("firing")
	paused = false
	await frames(15)
	game.request_action("reload")
	await frames(24)
	await shot("reload-out")
	var pose: Vector3=game.player.weapon.magazine.position
	game.set_paused(true)
	await create_timer(.2,true).timeout
	assert(game.player.weapon.magazine.position==pose)
	game.set_paused(false)
	await frames(18)
	await shot("reload-in")
	await frames(35)
	game.ammo=0
	await shot("empty")
	game.retry_run()
	await frames(3)
	assert(game.ammo==8)
	await shot("retry")
	assert(game.player.weapon.magazine.position == game.player.weapon.magazine_home)
	assert(game.player.weapon.slide.position == game.player.weapon.slide_home)
	game.mission_index = 0
	game.start_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	await frames(3)
	await shot("bright")
	game.mission_index = 2
	game.start_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	await frames(3)
	await shot("dark")
	game.mission_index = 1
	game.start_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	game.player.global_position = Vector3(7.4, 0, 15)
	await frames(3)
	await shot("interaction")
	game.player.global_position = Vector3(7, 0, 14.4)
	game.player.rotation.y = 0
	await frames(3)
	await shot("near-wall")
	print("WEAPON: movement/fire/reload/pause/empty/retry rendered; pause and retry assertions passed")
	game.queue_free()
	await create_timer(.2,true).timeout
	quit()
