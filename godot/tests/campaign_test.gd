extends SceneTree
## Independent deterministic native campaign checks; not a manual playthrough.
var game: Node
var checks: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	checks.append({"name": label, "ok": ok})
	print(("PASS " if ok else "FAIL ") + label)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func fresh(index: int = 1) -> void:
	game.set_paused(false)
	game.mission_index = index
	game.start_run()
	await frames(3)

func stop_enemies() -> void:
	for enemy in game.enemies:
		enemy.set_physics_process(false)

func place(at: Vector3, yaw: float = -PI / 2.0) -> void:
	game.player.global_position = at
	game.player.rotation.y = yaw
	game.player.velocity = Vector3.ZERO
	await frames(3)

func use_device(at: Vector3) -> void:
	await place(at)
	game.request_action("interact")
	await frames(2)

func fire() -> void:
	game.request_action("fire")
	await frames(2)

func last_event(name: String) -> Dictionary:
	for i in range(game.events.size() - 1, -1, -1):
		if game.events[i].event == name: return game.events[i]
	return {}

func walk_to(target: Vector3) -> bool:
	for i in range(700):
		var offset: Vector3 = target - game.player.global_position
		offset.y = 0
		if offset.length() < 0.14:
			Input.action_release("move_forward")
			return true
		if not game.active:
			Input.action_release("move_forward")
			return game.last_won and game.menu_state in ["result", "summary"]
		game.player.rotation.y = atan2(-offset.x, -offset.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	return false

func run() -> void:
	game = load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	var saved_preferences: Dictionary = game.session.preferences.duplicate(true)
	var saved_tutorial: bool = game.session.tutorial_seen
	game.session.tutorial_seen = false
	game.new_campaign()
	check("campaign begins with Breach briefing", game.mission_index == 0 and game.menu_state == "briefing" and not game.active)
	game.deploy_current()
	await frames(3)
	check("Breach uses reference spawn and scout", game.mission.id == "breach" and game.enemies.size() == 1 and game.enemies[0].role == "scout" and game.enemies[0].hp == 2 and game.player.global_position.distance_to(Vector3(4, 0, 4)) < 0.1)
	stop_enemies()
	Input.action_press("move_forward")
	await frames(3)
	Input.action_release("move_forward")
	Input.action_press("turn_right")
	await frames(3)
	Input.action_release("turn_right")
	await fire()
	game.request_action("reload")
	await frames(3)
	check("Breach onboarding follows move aim fire reload and persists", game.session.tutorial_seen)
	await frames(50)
	await place(Vector3(22, 0, 16))
	check("Breach exit remains locked with living bot", game.active)
	await place(Vector3(4, 0, 4))
	game.enemies[0].reset_guard()
	await frames(3)
	var hits_before_kill: int = game.hits
	await fire()
	game.cooldown = 0
	await fire()
	var disabled_row: Dictionary = last_event("bot_disabled")
	check("bot disable analytics contain current hit count and numeric target", game.hits == hits_before_kill + 2 and disabled_row.get("hits", -1) == game.hits and str(disabled_row.get("bot_id", "")) == "1")
	await frames(3)
	var breach_walked: bool = await walk_to(Vector3(22, 0, 4))
	breach_walked = (await walk_to(Vector3(22, 0, 16))) and breach_walked
	check("Breach collision route clears after scout disabled", breach_walked and not game.active and game.menu_state == "result")
	game.advance_campaign()
	check("Continue opens Control Room briefing", game.mission_index == 1 and game.menu_state == "briefing")
	game.deploy_current()
	await frames(3)
	check("Control Room starts clean with armored patrol", game.enemies.size() == 1 and game.enemies[0].role == "armored" and game.enemies[0].hp == 3 and not game.panel_disabled and not game.alarm_triggered)
	stop_enemies()
	await place(Vector3(12, 0, 11))
	await frames(80)
	check("camera visible tracking triggers alarm", game.alarm_triggered)
	check("alarm deploys exactly one scout reinforcement", game.enemies.size() == 2 and game.enemies[1].role == "scout")
	game.trigger_alarm()
	check("repeated alarm does not duplicate reinforcement", game.enemies.size() == 2)
	await fresh()
	stop_enemies()
	await place(Vector3(12, 0, 15))
	await frames(85)
	check("camera cannot detect through partition", not game.alarm_triggered and game.systems.camera_alert == 0)
	var fixture: OmniLight3D = game.room.get("_practical_lights")[0]
	var service_energy: float = fixture.light_energy
	await use_device(Vector3(13, 0, 15))
	check("service power isolates camera and dims real lighting", game.systems.power_routed and fixture.light_energy < service_energy)
	await place(Vector3(12, 0, 11))
	await frames(80)
	check("isolated camera cannot trigger alarm", not game.alarm_triggered and game.systems.camera_alert == 0)
	await fresh()
	stop_enemies()
	await place(Vector3(12, 0, 11))
	await fire()
	check("shooting camera disables it and rewards hit", game.systems.camera_disabled and game.hits == 1 and game.shots == 1 and game.hit_feedback > 0)
	await fresh()
	stop_enemies()
	await place(Vector3(12, 0, 15), atan2(-2.6, 4.0))
	await fire()
	check("wall blocks device hit", not game.systems.camera_disabled and game.hits == 0)
	await fresh()
	stop_enemies()
	await place(Vector3(5, 0, 11), atan2(-2.0, -0.6))
	await fire()
	check("service lamp can be destroyed", game.systems.lamp_broken and game.hits == 1)
	await fresh()
	stop_enemies()
	await use_device(Vector3(15, 0, 15))
	check("bulkhead closes and blocks LOS", not game.systems.door_open and not game.has_los(Vector3(17.5, 1.4, 14.5), Vector3(17.5, 1.4, 11)))
	game.request_action("interact")
	await frames(3)
	check("bulkhead reopens from switch", game.systems.door_open and game.has_los(Vector3(17.5, 1.4, 14.5), Vector3(17.5, 1.4, 11)))
	game.enemies[0].global_position = Vector3(17, 0, 13)
	await frames(3)
	game.request_action("interact")
	await frames(2)
	check("bulkhead refuses to close on living actor", game.systems.door_open)
	await fresh()
	stop_enemies()
	game.enemies[0].global_position = Vector3(17, 0, 11)
	game.enemies[0].attack_windup = 0.4
	await use_device(Vector3(17, 0, 15))
	check("one-use overload staggers visible enemy and cancels windup", game.systems.overloaded and game.enemies[0].stagger > 2.8 and game.enemies[0].attack_windup == 0)
	game.enemies[0].stagger = 0
	game.request_action("interact")
	await frames(2)
	check("spent overload cannot apply a second stagger", game.enemies[0].stagger == 0)
	await fresh()
	stop_enemies()
	await use_device(Vector3(17, 0, 11))
	check("optional intel raises alarm and is provisional", game.systems.intel and game.alarm_triggered and not game.session.decisions.intel)
	game.finish(false)
	check("failed run does not commit optional intel or alarm", not game.session.decisions.intel and not game.session.decisions.alarm_raised)
	game.retry_run()
	await frames(3)
	check("retry clears provisional device state and counts retry", not game.systems.intel and not game.alarm_triggered and game.session.retries.get("control-room", 0) > 0)
	stop_enemies()
	game.health = 40
	await use_device(Vector3(15, 0, 17))
	var cache_health: int = game.health
	game.request_action("interact")
	await frames(2)
	check("hidden cache restores 25 health only once", game.systems.secret and cache_health == 65 and game.health == 65)
	await fresh()
	stop_enemies()
	await use_device(Vector3(9, 0, 15))
	await use_device(Vector3(17, 0, 11))
	await use_device(Vector3(15, 0, 17))
	check("disabled panel makes optional intel quiet", game.panel_disabled and game.systems.intel and not game.alarm_triggered)
	check("optional rewards stay provisional before extraction", not game.session.decisions.intel and not game.session.decisions.security_disabled)
	var control_walked: bool = true
	for target: Vector3 in [Vector3(15, 0, 14.55),Vector3(17.5, 0, 14.55),Vector3(17.5, 0, 11),Vector3(17, 0, 9),Vector3(21, 0, 9),Vector3(21, 0, 3),Vector3(23, 0, 3)]:
		control_walked = (await walk_to(target)) and control_walked
	check("Control Room collision route commits quiet security and optional finds", control_walked and not game.active and game.session.decisions.security_disabled and game.session.decisions.intel and game.session.decisions.secret)
	check("fast accurate optional quiet route earns S rank", game.menu_text.text.contains("RANK S"))
	game.advance_campaign()
	check("Continue opens Blackout briefing", game.mission_index == 2 and game.menu_state == "briefing")
	game.deploy_current()
	await frames(3)
	var live_turrets: int = 0
	for enemy in game.enemies:
		if enemy.role == "turret" and enemy.hp > 0: live_turrets += 1
	check("quiet shutdown disables later turret", live_turrets == 0)
	check("successful intel journal survives mission transition", str(game.session.journal).contains("MANIFEST"))
	stop_enemies()
	await place(Vector3(23, 0, 3))
	check("Blackout extraction requires restored power", game.active and not game.power_restored)
	await place(Vector3(3, 0, 3))
	var blackout_walked: bool = await walk_to(Vector3(3, 0, 15))
	blackout_walked = (await walk_to(Vector3(6, 0, 14.35))) and blackout_walked
	game.request_action("interact")
	await frames(2)
	check("Blackout power switch restores power", game.power_restored and game.panel_disabled)
	blackout_walked = (await walk_to(Vector3(23, 0, 14.35))) and blackout_walked
	blackout_walked = (await walk_to(Vector3(23, 0, 3))) and blackout_walked
	check("Blackout collision route reaches complete campaign summary", blackout_walked and not game.active and game.menu_text.text.contains("BREACH") and game.menu_text.text.contains("BLACKOUT"))
	var event_count: int = game.events.size()
	game.new_campaign()
	check("new campaign clears decisions and keeps session events", not game.session.decisions.security_disabled and not game.session.decisions.intel and game.events.size() == event_count)
	await fresh()
	stop_enemies()
	game.trigger_alarm()
	game.core_collected = true
	game.finish(true)
	game.advance_campaign()
	game.deploy_current()
	await frames(3)
	var armored_count: int = 0
	for enemy in game.enemies:
		if enemy.role == "armored" and enemy.hp > 0: armored_count += 1
	check("committed alarm adds armored Blackout pursuer", armored_count == 1)
	var turret: Node = null
	for enemy in game.enemies:
		if enemy.role == "turret": turret = enemy
	check("turret role has stationary ranged combat", turret != null and turret.speed == 0 and turret.attack_range == 9.0 and turret.damage == 10)
	await place(Vector3(21, 0, 9))
	for enemy in game.enemies:
		if enemy != turret: enemy.set_physics_process(false)
	var turret_start: Vector3 = turret.global_position
	await frames(100)
	check("turret attacks at range without moving", game.health < 100 and turret.global_position.distance_to(turret_start) < 0.01)
	await fresh()
	stop_enemies()
	await place(Vector3(12, 0, 11))
	await frames(20)
	var tracking_before: float = game.systems.camera_alert
	var clock_before: float = game.elapsed
	game.set_paused(true)
	await create_timer(0.2, true).timeout
	check("pause freezes device tracking and active time", game.systems.camera_alert == tracking_before and game.elapsed == clock_before)
	game.set_paused(false)
	game.open_journal()
	check("journal pauses game and shows recovered text", paused and game.menu_state == "journal" and game.menu_text.text.contains("CONTROL LOG"))
	game.set_paused(false)
	game.open_settings()
	check("in-run settings pause simulation", paused and game.menu_state == "settings")
	game.close_settings()
	check("settings return preserves paused encounter", paused and game.active)
	game.session.preferences = {"volume": 0.25, "muted": true, "sensitivity": 0.005}
	game.session.save_preferences()
	game.session.preferences.volume = 1.0
	game.session.load_preferences()
	check("native preferences persist and reload", is_equal_approx(game.session.preferences.volume, 0.25) and game.session.preferences.muted and is_equal_approx(game.session.preferences.sensitivity, 0.005))
	game._reset_settings()
	check("settings reset restores native defaults", is_equal_approx(game.session.preferences.volume, 0.65) and not game.session.preferences.muted and is_equal_approx(game.session.preferences.sensitivity, 0.003))
	game.register_event("review_detail", "a,\"b\"\nc")
	var csv: String = game.session.csv_text(game.events)
	check("CSV preserves browser schema and mission data", csv.begins_with("run,elapsed_seconds,event,bot_id,health,ammo,shots,hits,detail,mission_id") and csv.contains("control-room") and csv.contains("mission_start"))
	check("CSV quotes commas quotes and newlines", csv.contains('"a,""b""\nc"'))
	var power_row: Dictionary = last_event("power_rerouted")
	var panel_row: Dictionary = last_event("alarm_disabled")
	var camera_row: Dictionary = last_event("camera_destroyed")
	check("device CSV target and detail match browser column semantics", power_row.get("bot_id", "") == "service_grid" and power_row.get("detail", "") == "isolated" and camera_row.get("bot_id", "") == "camera_1")
	check("panel CSV preserves panel ID and alarm outcome", panel_row.get("bot_id", "") == "alarm_panel_1" and panel_row.get("detail", "") in ["prevented", "silenced"])
	var csv_path: String = game.export_csv("user://campaign-test-session.csv")
	check("CSV export writes actual session file", FileAccess.file_exists(csv_path) and FileAccess.get_file_as_string(csv_path) == csv)
	game.session.preferences = saved_preferences
	game.session.tutorial_seen = saved_tutorial
	game.session.save_preferences()
	var failed: int = 0
	for entry in checks:
		if not entry.ok: failed += 1
	var output := FileAccess.open("res://tests/campaign-results.json", FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "checks": checks, "failures": failed}, "\t") + "\n")
	print("CAMPAIGN CHECKS: %d passed, %d failed" % [checks.size() - failed, failed])
	paused = false
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
