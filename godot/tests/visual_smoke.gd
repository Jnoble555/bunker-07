extends SceneTree
## Rendered (non-headless) smoke capture. Scripted input is not a human playthrough.
var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func frame_wait(count: int) -> void:
	for i in count:
		await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../docs/godot/screenshots")
	DirAccess.make_dir_recursive_absolute(folder)
	var result := root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
	if result != OK:
		push_error("Screenshot failed: " + name)
		quit(1)

func run() -> void:
	game = load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frame_wait(10)
	await capture("title")
	game.start_run()
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(5, 0, 15)
	await frame_wait(10)
	await capture("maintenance")
	game.player.global_position = Vector3(5, 0, 11)
	game.player.rotation.y = -PI / 2
	await frame_wait(10)
	await capture("guard")
	# Exercise actual input dispatch; actions are queued and executed by physics.
	var fire_event := InputEventKey.new()
	fire_event.physical_keycode = KEY_SPACE
	fire_event.pressed = true
	Input.parse_input_event(fire_event)
	await frame_wait(5)
	fire_event.pressed = false
	Input.parse_input_event(fire_event)
	if game.shots != 1:
		push_error("Rendered input smoke: fire was not dispatched")
		quit(1)
		return
	game.set_paused(true)
	await frame_wait(5)
	await capture("pause")
	print("RENDERED SMOKE: title, maintenance, guard, pause captured; Space input dispatched")
	game.get_tree().paused = false
	game.queue_free()
	await process_frame
	quit(0)
