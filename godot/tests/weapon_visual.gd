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
	game.request_action("fire")
	await frames(2)
	await shot("firing")
	await frames(15)
	game.request_action("reload")
	await frames(12)
	await shot("reload-out")
	var pose: Vector3=game.player.weapon.magazine.position
	game.set_paused(true)
	await create_timer(.2,true).timeout
	assert(game.player.weapon.magazine.position==pose)
	game.set_paused(false)
	await frames(12)
	await shot("reload-in")
	await frames(35)
	game.ammo=0
	await shot("empty")
	game.retry_run()
	await frames(3)
	assert(game.ammo==8)
	await shot("retry")
	print("WEAPON: movement/fire/reload/pause/empty/retry rendered; pause and retry assertions passed")
	game.queue_free()
	await create_timer(.2,true).timeout
	quit()
