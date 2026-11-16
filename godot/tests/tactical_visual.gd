extends SceneTree
## Scripted composition checks, not a human combat playthrough.
var game: Node
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func capture(id: String) -> void:
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/tactical-screenshots/"+id+".png")
func view(at: Vector3, target: Vector3) -> void:
	game.player.global_position=at
	game.player.rotation=Vector3.ZERO
	game.player.pitch=0
	game.player.camera.rotation=Vector3.ZERO
	game.player.camera.look_at(target,Vector3.UP)
func run() -> void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	await capture("title")
	game.new_operation()
	game.deploy_current()
	for enemy in game.enemies: enemy.set_physics_process(false)
	await frames(4)
	# Freeze player pose so manually composed views keep full camera pitch.
	game.player.set_physics_process(false)
	view(Vector3(5,0,44),Vector3(12,1.4,34))
	await capture("entry")
	view(Vector3(22,0,43),Vector3(25,1.3,35))
	await capture("security")
	view(Vector3(38,0,23),Vector3(38,2.1,12))
	await capture("ramp")
	game.operation_stage=1
	view(Vector3(37,1.2,14),Vector3(43,2.4,7))
	await capture("operations")
	game.weapon_ammo.shotgun={"magazine":4,"reserve":16}
	game.switch_weapon("shotgun")
	view(Vector3(42,0,42),Vector3(43,1.4,35))
	await capture("shotgun")
	var enemy=game.enemies[4]
	enemy._visual.pose("engage",true,.4,true)
	view(Vector3(41,0,43),Vector3(43,1.2,39))
	await capture("armed-unit")
	game.queue_free()
	await create_timer(.2,true).timeout
	print("TACTICAL VISUAL: captured final integrated scenes")
	quit()
