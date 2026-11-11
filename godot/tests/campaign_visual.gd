extends SceneTree
## Scripted rendered validation, not a substitute for manual playtesting.
var game: Node3D
var output_folder := "res://../docs/godot/campaign-screenshots"

func _initialize() -> void:
	call_deferred("run")

func wait_frames(count: int = 8) -> void:
	for i in count: await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path(output_folder)
	DirAccess.make_dir_recursive_absolute(folder)
	if root.get_texture().get_image().save_png(folder.path_join(name+".png")) != OK:
		push_error("Could not capture "+name)
		quit(1)

func stop_enemies() -> void:
	for enemy in game.enemies: enemy.set_physics_process(false)

func run() -> void:
	game = load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await wait_frames()
	await capture("title")
	game.new_campaign()
	await wait_frames()
	await capture("briefing")
	game.deploy_current()
	stop_enemies()
	await wait_frames()
	game.player.rotation.y = -PI/2
	await capture("breach")
	game.open_settings()
	await wait_frames()
	await capture("settings")
	game.close_settings()
	game.set_paused(false)
	game.finish(true)
	game.advance_campaign()
	game.deploy_current()
	stop_enemies()
	game.player.global_position = Vector3(10.8,0,15)
	await wait_frames()
	await capture("control-room")
	game.open_journal()
	await wait_frames()
	await capture("journal")
	game._back_to_pause()
	game.set_paused(false)
	game.finish(true)
	game.advance_campaign()
	game.deploy_current()
	stop_enemies()
	await wait_frames()
	await capture("blackout")
	game.player.global_position = Vector3(21,0,9)
	game.player.rotation.y = 0
	game.enemies[0].facing = PI/2
	game.enemies[0]._update_pose(0)
	await wait_frames()
	await capture("turret")
	game.player.global_position = Vector3(7,0,15)
	game.request_action("interact")
	await wait_frames()
	if not game.power_restored:
		push_error("Rendered power interaction failed")
		quit(1)
		return
	game.player.global_position = Vector3(23,0,3)
	await wait_frames()
	if game.menu_state != "summary" or game.session.summaries.size()!=3:
		push_error("Rendered campaign did not reach summary")
		quit(1)
		return
	await capture("summary")
	print("CAMPAIGN RENDERED: three missions, settings, journal, power interaction and final summary passed")
	paused = false
	game.queue_free()
	await wait_frames(12)
	quit(0)
