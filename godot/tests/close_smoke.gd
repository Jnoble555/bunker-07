extends SceneTree
## Exercise the actual window-close notification while sounds are active.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.start_run()
	game.play_sound("alarm",game.player.global_position)
	game.play_sound("fire",game.player.global_position)
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	if not game.quitting or game.active or not paused:
		push_error("Orderly close did not stop gameplay")
		quit(1)
	else:
		print("WINDOW CLOSE: game stopped, audio released; awaiting orderly exit")
