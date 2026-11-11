extends SceneTree
## Native physics integration checks, not a substitute for a human playthrough.
var checks: Array[Dictionary] = []
var game: Node

func _initialize() -> void:
	call_deferred("run")

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "ok": passed})
	print(("PASS " if passed else "FAIL ") + label)

func frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame

func fresh() -> void:
	game.set_paused(false)
	game.retry_run()
	# Isolate the original M1 guard mechanics from newly ported shootable devices.
	# Device occlusion and hits are tested separately in campaign_test.gd.
	game.systems.shootable_hit("camera")
	game.systems.shootable_hit("lamp")
	await frames(3)

func shoot_once() -> void:
	game.request_action("fire")
	await frames(2)

func walk_to(target: Vector3) -> bool:
	for _frame in range(900):
		var offset: Vector3 = target - game.player.global_position
		offset.y = 0.0
		if offset.length() < 0.12 or not game.active:
			Input.action_release("move_forward")
			return offset.length() < 0.12 or game.core_collected
		game.player.rotation.y = atan2(-offset.x, -offset.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	return false

func run() -> void:
	var packed := load("res://scenes/control_room.tscn") as PackedScene
	if packed == null:
		push_error("Milestone scene failed to load")
		quit(1)
		return
	game = packed.instantiate()
	root.add_child(game)
	await frames(3)
	game.start_run()
	await frames(3)
	check("fresh run health, magazine and active state", game.active and game.health == 100 and game.ammo == 8)
	var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
	var left_ray: Vector3 = game.player.camera.project_ray_normal(Vector2(0, viewport_size.y / 2.0))
	var right_ray: Vector3 = game.player.camera.project_ray_normal(Vector2(viewport_size.x, viewport_size.y / 2.0))
	check("camera horizontal field of view matches browser", absf(rad_to_deg(left_ray.angle_to(right_ray)) - rad_to_deg(2.0 * atan(0.68))) < 0.1)
	check("world blocks sight across maintenance partition", not game.has_los(Vector3(4, 1.4, 11), Vector3(4, 1.4, 15)))
	check("direct hallway has unobstructed sight", game.has_los(Vector3(4, 1.4, 11), Vector3(14, 1.4, 11)))
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(4, 0, 11)
	game.player.rotation.y = -PI / 2.0
	await frames(3)
	Input.action_press("strafe_right")
	await frames(40)
	Input.action_release("strafe_right")
	check("real player collision prevents crossing partition", game.player.global_position.z < 11.7)
	game.player.global_position = Vector3(5, 0, 16.3)
	await frames(2)
	var start: Vector3 = game.player.global_position
	Input.action_press("move_forward")
	await frames(12)
	Input.action_release("move_forward")
	var straight: float = Vector2(game.player.global_position.x - start.x, game.player.global_position.z - start.z).length()
	game.player.global_position = start
	await frames(2)
	Input.action_press("move_forward")
	Input.action_press("strafe_right")
	await frames(12)
	Input.action_release("move_forward")
	Input.action_release("strafe_right")
	var diagonal: float = Vector2(game.player.global_position.x - start.x, game.player.global_position.z - start.z).length()
	check("diagonal movement is normalized", straight > 0.5 and absf(diagonal - straight) < 0.15)
	var yaw: float = game.player.rotation.y
	Input.action_press("turn_right")
	await frames(12)
	Input.action_release("turn_right")
	check("arrow aim rotates player", absf(game.player.rotation.y - yaw) > 0.2)
	var pause_event := InputEventKey.new()
	pause_event.physical_keycode = KEY_P
	pause_event.pressed = true
	Input.parse_input_event(pause_event.duplicate())
	await frames(3)
	check("pause action reaches menu while game is active", paused and game.menu_state == "pause" and game.menu.visible)
	Input.parse_input_event(pause_event.duplicate())
	await frames(3)
	check("pause action resumes through always-processing controller", not paused and game.menu_state == "play" and not game.menu.visible)

	await fresh()
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(7, 0, 11)
	game.player.rotation.y = -PI / 2.0
	game.guard.global_position = Vector3(10, 0, 11)
	await frames(3)
	await shoot_once()
	check("hitscan damages armored guard and rewards hit", game.guard.hp == 2 and game.hits == 1 and game.ammo == 7)
	check("hit interrupts attack and applies armored stagger", game.guard.stagger > 0.0 and game.guard.attack_windup == 0.0)
	check("hit and muzzle feedback begin", game.hit_feedback > 0.0 and game.flash > 0.0)
	await shoot_once()
	check("shot cooldown rejects immediate second fire", game.ammo == 7 and game.guard.hp == 2)
	await frames(16)
	await shoot_once()
	await frames(16)
	await shoot_once()
	check("three successful hits disable representative enemy", game.guard.hp == 0)
	var hits_before_dead_shot: int = game.hits
	await frames(16)
	await shoot_once()
	check("disabled guard no longer intercepts or rewards shots", game.hits == hits_before_dead_shot)

	await fresh()
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(7, 0, 11.45)
	game.player.rotation.y = -PI / 2.0
	game.guard.global_position = Vector3(10, 0, 11)
	await frames(3)
	await shoot_once()
	check("grazing shot preserves reference .28 tile hit tolerance", game.guard.hp == 2 and game.hits == 1)
	game.player.global_position = Vector3(9.7, 0, 11)
	game.cooldown = 0.0
	await frames(3)
	await shoot_once()
	check("shots inside nonblocking enemy hurtbox still hit", game.guard.hp == 1 and game.hits == 2)
	game.player.global_position = Vector3(10.3, 0, 11)
	game.cooldown = 0.0
	await frames(3)
	await shoot_once()
	check("overlapping enemy behind camera is not a target", game.guard.hp == 1 and game.hits == 2)

	await fresh()
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(4, 0, 15)
	game.player.rotation.y = 0.0
	game.guard.global_position = Vector3(4, 0, 11)
	await frames(3)
	await shoot_once()
	check("wall occludes actual weapon shot", game.guard.hp == 3 and game.ammo == 7 and game.hits == 0)
	game.ammo = 3
	game.cooldown = 0.0
	game.request_action("reload")
	await frames(2)
	check("reload starts without instantly refilling", game.reload_remaining > 0.7 and game.ammo == 3)
	await shoot_once()
	check("reload blocks firing", game.ammo == 3)
	var reload_before: float = game.reload_remaining
	var elapsed_before: float = game.elapsed
	game.set_paused(true)
	await create_timer(0.25, true).timeout
	check("pause freezes reload and active clock", game.reload_remaining == reload_before and game.elapsed == elapsed_before)
	game.request_action("fire")
	check("pause does not queue a delayed shot", game.pending_actions.is_empty())
	game.set_paused(false)
	await frames(52)
	check("reload completes to eight rounds after resume", game.ammo == 8 and game.reload_remaining == 0.0)

	await fresh()
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(11, 0, 15)
	await frames(3)
	game.request_action("interact")
	await frames(2)
	check("panel refuses interaction beyond .85 tile", not game.panel_disabled)
	game.player.global_position = Vector3(10.5, 0, 15)
	await frames(3)
	game.request_action("interact")
	await frames(2)
	check("panel disables within .85 tile", game.panel_disabled)
	game.trigger_alarm()
	check("disabled panel prevents later alarm", not game.alarm_triggered)
	game.request_action("interact")
	await frames(2)
	check("repeat interaction remains disabled", game.panel_disabled)

	await fresh()
	game.guard.set_physics_process(true)
	game.alarm_triggered = true
	game.player.global_position = Vector3(8, 0, 11)
	game.guard.global_position = Vector3(9, 0, 11)
	game.guard.attack_cooldown = 0.0
	await frames(3)
	check("nearby alerted guard starts attack windup", game.guard.attack_windup > 0.0)
	var windup_before: float = game.guard.attack_windup
	game.set_paused(true)
	await create_timer(0.25, true).timeout
	check("pause freezes enemy windup", game.guard.attack_windup == windup_before and game.health == 100)
	game.set_paused(false)
	await frames(48)
	check("completed armored attack deals eighteen damage", game.health == 82 and game.hurt_feedback > 0.0)
	game.health = 100
	game.guard.attack_cooldown = 0.0
	game.guard.attack_windup = 0.5
	game.player.global_position = Vector3(8, 0, 15)
	await frames(4)
	check("breaking sight cancels timed attack", game.health == 100 and game.guard.attack_windup == 0.0)
	game.guard.attack_windup = 0.4
	game.guard.receive_hit()
	check("stagger cancels pending attack immediately", game.guard.stagger > 0.0 and game.guard.attack_windup == 0.0)

	await fresh()
	game.guard.set_physics_process(true)
	game.player.global_position = Vector3(7, 0, 11)
	game.guard.global_position = Vector3(10, 0, 11)
	game.guard.facing = PI
	await frames(74)
	check("guard facing and continuous sight trigger alarm", game.alarm_triggered)
	game.player.global_position = Vector3(5, 0, 11)
	var before_chase: Vector3 = game.guard.global_position
	await frames(20)
	check("alerted guard chases within visible hall", game.guard.global_position.x < before_chase.x - 0.1)
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(9, 0, 15)
	await frames(3)
	game.request_action("interact")
	await frames(2)
	check("panel silences alarm without undoing trigger history", game.panel_disabled and game.alarm_triggered)

	await fresh()
	game.guard.set_physics_process(true)
	game.player.global_position = Vector3(8, 0, 15)
	game.guard.global_position = Vector3(8, 0, 11)
	game.guard.facing = PI / 2.0
	await frames(78)
	check("partition prevents guard detection", not game.alarm_triggered)

	await fresh()
	game.guard.set_physics_process(false)
	game.player.global_position = Vector3(17, 0, 11)
	await frames(3)
	check("core stays locked before alarm or panel", not game.core_collected)
	check("core gate blocks physical sight before pickup", not game.has_los(Vector3(17, 1.4, 11), Vector3(17, 1.4, 8.5)))
	game.panel_disabled = true
	await frames(4)
	check("unlocked core pickup opens gate", game.core_collected and game.has_los(Vector3(17, 1.4, 11), Vector3(17, 1.4, 8.5)))
	game.player.global_position = Vector3(23, 0, 3)
	await frames(3)
	check("core extraction completes partial milestone", not game.active)

	game.ammo = 2
	game.reload_remaining = 0.5
	game.cooldown = 0.2
	game.core_collected = true
	game.panel_disabled = true
	game.guard.alert_progress = 0.7
	await fresh()
	check("retry resets all included encounter state", game.health == 100 and game.ammo == 8 and game.reload_remaining == 0.0 and game.cooldown == 0.0 and not game.panel_disabled and not game.alarm_triggered and not game.core_collected and game.guard.hp == 3 and game.guard.stagger == 0.0 and game.guard.attack_windup == 0.0 and game.guard.alert_progress == 0.0)
	game.guard.set_physics_process(false)
	var walked: bool = await walk_to(Vector3(3, 0, 15))
	walked = (await walk_to(Vector3(9, 0, 15))) and walked
	game.request_action("interact")
	await frames(2)
	check("collision-driven route reaches usable maintenance panel", walked and game.panel_disabled)
	for target: Vector3 in [Vector3(17, 0, 15), Vector3(17, 0, 11), Vector3(17, 0, 9), Vector3(21, 0, 9), Vector3(21, 0, 3), Vector3(23, 0, 3)]:
		walked = (await walk_to(target)) and walked
	check("complete maintenance route crosses opened gate and extracts", walked and game.core_collected and not game.active and game.health == 100 and game.menu_state == "result")
	check("successful result exposes campaign rank and continuation", game.menu_state == "result" and game.menu_text.text.contains("RANK") and game.continue_button.visible)
	await fresh()
	check("retry after extraction restores closed gate", not game.core_collected and not game.has_los(Vector3(17, 1.4, 11), Vector3(17, 1.4, 8.5)))

	var failed := 0
	for entry in checks:
		if not entry["ok"]:
			failed += 1
	var report := {"engine": Engine.get_version_info()["string"], "checks": checks, "failures": failed}
	var output := FileAccess.open("res://tests/milestone-results.json", FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(report, "\t") + "\n")
	print("NATIVE MILESTONE CHECKS: %d passed, %d failed" % [checks.size() - failed, failed])
	game.set_paused(false)
	game.queue_free()
	await process_frame
	# Audio-server stop/release commands are mixed asynchronously after Node teardown.
	# Do not terminate the process on the same frame as the final scene deletion.
	await create_timer(0.15, true).timeout
	quit(1 if failed else 0)
