extends SceneTree
var game: Node
var failed := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(label: String, passed: bool) -> void:
	print(("PASS " if passed else "FAIL ") + label)
	if not passed: failed += 1
func run() -> void:
	game = load("res://scenes/movement_lab.tscn").instantiate()
	root.add_child(game)
	await frames(8)
	var p = game.player
	await capture("movement-lab")
	p.global_position = Vector3(96,0,100)
	Input.action_press("crouch")
	await frames(4)
	check("crouch uses short capsule",p.crouched and p.body_shape.shape.height < 1.1)
	Input.action_release("crouch")
	await frames(4)
	check("headroom prevents standing",p.crouched and not p.can_stand())
	await capture("movement-headroom")
	p.global_position = Vector3(100,0,105)
	await frames(4)
	check("clearance restores standing",not p.crouched)
	p.pitch = 1.0
	Input.action_press("move_forward")
	await frames(5)
	var walk_speed: float = Vector2(p.velocity.x,p.velocity.z).length()
	check("pitch does not lift horizontal movement",absf(p.global_position.y) < 0.05)
	Input.action_press("sprint")
	await frames(3)
	check("held sprint increases speed",Vector2(p.velocity.x,p.velocity.z).length() > walk_speed)
	Input.action_press("aim_weapon")
	await frames(5)
	check("aim narrows FOV and slows movement",p.camera.fov < 65 and Vector2(p.velocity.x,p.velocity.z).length() < walk_speed)
	p.clear_held_inputs()
	Input.action_press("crouch")
	Input.action_press("move_forward")
	await frames(3)
	check("crouch slows movement",Vector2(p.velocity.x,p.velocity.z).length() < walk_speed)
	p.clear_held_inputs()
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(0,-10000)
	p._unhandled_input(mouse)
	check("mouse pitch clamps at eighty degrees",is_equal_approx(p.pitch,deg_to_rad(80)))
	p.pitch = 0
	p.global_position = Vector3(100,0,105)
	var wall = game.box("LeanWall",Vector3(100.5,1.4,105),Vector3(0.2,2.8,2))
	await frames(3)
	check("lean sweep stops camera before wall",absf(p.safe_lean(Vector3(0,1.4,0),0.32)) < 0.30)
	wall.queue_free()
	await frames(3)
	p.global_position = Vector3(106,0,102)
	p.rotation.y = 0
	Input.action_press("move_forward")
	await frames(33)
	Input.action_release("move_forward")
	check("stairs lift grounded player",p.global_position.y > 0.5)
	p.global_position = Vector3(103,0,102)
	p.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(42)
	Input.action_release("move_forward")
	check("ramp lifts grounded player",p.global_position.y > 0.3)
	p.global_position = Vector3(100,0,105)
	p.velocity = Vector3.ZERO
	await frames(4)
	var target = game.spawn_enemy({"position":Vector3(100,3,99),"role":"turret","is_guard":false})
	target.set_physics_process(false)
	await frames(3)
	p.camera.look_at(target.global_position + Vector3(0,1.4,0))
	p.pitch = p.camera.rotation.x
	game.shoot()
	check("camera-directed vertical shot hits elevated target",target.hp == 2)
	var blocker = game.box("VerticalOccluder",Vector3(100,3.0,102),Vector3(2,2,0.3))
	await frames(3)
	game.cooldown = 0
	game.shoot()
	check("solid geometry occludes vertical shot",target.hp == 2)
	check("interaction and enemy sight respect elevated obstacle",not game.interaction_los(p.camera.global_position,target.global_position + Vector3(0,1.4,0)) and not target._can_see(p))
	Input.action_press("aim_weapon")
	Input.action_press("sprint")
	Input.action_press("lean_left")
	await frames(2)
	game.set_paused(true)
	var frozen: Vector3 = p.camera.position
	await create_timer(0.15,true).timeout
	check("pause freezes camera pose",p.camera.position == frozen)
	check("pause clears held tactical inputs",not Input.is_action_pressed("aim_weapon") and not Input.is_action_pressed("sprint") and not Input.is_action_pressed("lean_left"))
	game.set_paused(false)
	game.retry_run()
	await frames(3)
	check("retry restores pitch crouch lean aim",not p.crouched and not p.aiming and p.pitch == 0 and p.lean == 0)
	print("TACTICAL failures: ",failed)
	game.queue_free()
	await create_timer(.2).timeout
	quit(1 if failed else 0)

func capture(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/" + id + ".png")
