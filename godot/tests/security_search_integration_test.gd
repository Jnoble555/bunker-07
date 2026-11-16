extends SceneTree

const A := Vector3(24,0,34)
const B := Vector3(5,0,35)
const C := Vector3(25,0,26)
const SMG := "security-smg"
const RIFLE := "security-rifle"
var checks := 0
var failures := 0
var game: Node
var sender: Node3D
var receiver: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(label: String, passed: bool) -> void:
	checks += 1
	print(("PASS " if passed else "FAIL ") + label)
	if not passed: failures += 1

func frames(count: int) -> void:
	for i in count: await physics_frame

func fresh(seed_attempt: int = 0) -> void:
	game.new_operation()
	if seed_attempt > 0: game.attempts = seed_attempt - 1
	game.deploy_current()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies: enemy.set_physics_process(false)
	sender = game._security_enemy_by_id(SMG)
	receiver = game._security_enemy_by_id(RIFLE)
	game.player.global_position = A
	await frames(3)

func step(delta: float) -> void:
	game._advance_security_director(delta)

func incident() -> Dictionary:
	return game.security_director.get_search_incident()

func report_and_break_sight(hidden: Vector3 = B) -> void:
	sender._physics_process(.016)
	step(.6)
	game.player.global_position = hidden
	await frames(2)
	sender._observe_visibility(false, .016)

func deliver(hidden: Vector3 = B) -> Dictionary:
	await report_and_break_sight(hidden)
	step(.8)
	return incident()

func run() -> void:
	game = load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await fresh(420)
	var sight: Vector3 = game.player.camera.global_position
	check("A starts with real sight only for SMG", sender.can_see_player() and not receiver.can_see_player())
	await report_and_break_sight()
	check("B is hidden from both guards and no role or receiver knowledge exists before delivery",
		not sender.can_see_player() and not receiver.can_see_player() and incident().is_empty() and receiver.last_known == Vector3.INF)
	var delivery_start := Time.get_ticks_usec()
	step(.8)
	print("SEARCH BENCH first delivery and planning: %d us" % (Time.get_ticks_usec() - delivery_start))
	var active := incident()
	check("A delivery creates one incident with two reservations", active.get("assignments", {}).size() == 2)
	if active.get("assignments", {}).size() != 2:
		print("Unexpected incident: ", active)
		quit(1)
		return
	var investigator: Dictionary = active.assignments[RIFLE]
	var holder: Dictionary = active.assignments[SMG]
	print("SEARCH SCENARIO A incident=", active.id, " investigator=", investigator, " holder=", holder)
	check("recipient investigates and sender holds", investigator.role == "investigator" and holder.role == "holder")
	check("reservations are separated and holder prefers authored cover",
		investigator.destination.distance_to(holder.destination) >= 2.2 and game.room.cover_points.has(holder.destination))
	check("both assignments use actual validated paths to clear destinations",
		game.room.security_search_path(receiver.global_position, investigator.destination) == investigator.path
		and game.room.security_search_path(sender.global_position, holder.destination) == holder.path
		and game.room.navigable(investigator.destination) and game.room.navigable(holder.destination))
	check("source observation, report, position and deadline remain intact",
		active.id == active.evidence.id and active.evidence.observation_id > 0 and receiver.last_known == sight
		and active.evidence.position == sight and active.deadline <= active.evidence.expires_at)
	active.assignments[RIFLE].destination = Vector3.ZERO
	check("query is detached from the actual reservation", incident().assignments[RIFLE].destination == investigator.path[-1])
	var magazine: int = receiver.magazine
	var health: int = game.health
	receiver._fire()
	check("B search cannot shoot through the partition", receiver.magazine == magazine and game.health == health)

	var samples: Array[int] = []
	var total := 0
	for i in 1000:
		var started := Time.get_ticks_usec()
		step(.00001)
		var cost := Time.get_ticks_usec() - started
		total += cost
		samples.append(cost)
	samples.sort()
	print("SEARCH BENCH active eight-guard controller sync + director mean %.2f us p95 %d us" % [total / 1000.0, samples[949]])
	check("stress ticks produce no new assignments or pending reports",
		incident().id == active.id and incident().assignments.size() == 2
		and game.security_director.get_pending_radio_reports().is_empty() and game.enemies.size() == 8)
	var physics_samples: Array[int] = []
	for i in 330:
		if incident().is_empty(): break
		await physics_frame
		var started := Time.get_ticks_usec()
		step(1.0 / 60)
		if incident().is_empty(): break
		for enemy in game.enemies: enemy._physics_process(1.0 / 60)
		physics_samples.append(Time.get_ticks_usec() - started)
	physics_samples.sort()
	if not physics_samples.is_empty():
		print("SEARCH BENCH eight guards + director: %d ticks p95 %d us max %d us" % [
			physics_samples.size(), physics_samples[ceili(physics_samples.size() * .95) - 1], physics_samples[-1]])
	var arrivals: Array = game.events.filter(func(event): return event.event == "security_search_arrived")
	var endings: Array = game.events.filter(func(event): return event.event == "security_search_completed")
	print("SEARCH SCENARIO B/D arrivals=", arrivals, " endings=", endings, " positions=", [sender.global_position, receiver.global_position])
	check("B both guards move on their paths and arrive at different positions",
		arrivals.size() == 2 and sender.global_position.distance_to(holder.destination) <= .65
		and receiver.global_position.distance_to(investigator.path[-1]) <= .65
		and sender.state == "hold" and receiver.state == "investigate")
	check("D investigator dwell completes and clears both assignments and reservations",
		incident().is_empty() and endings.size() == 1 and '"area_checked"' in endings[0].detail
		and sender._search_assignment.is_empty() and receiver._search_assignment.is_empty())
	sender._decide(.016, false)
	receiver._decide(.016, false)
	check("search completion returns both guards to their existing patrol", sender.state == "patrol" and receiver.state == "patrol")

	await fresh(420)
	var replay := await deliver(Vector3(6,0,35))
	check("same seed with alternate hidden position reproduces both assignments",
		replay.assignments[RIFLE].path == investigator.path and replay.assignments[SMG].path == holder.path)
	var rng := RandomNumberGenerator.new()
	var choices := {}
	for seed in range(1, 20):
		rng.seed = seed
		var choice: Dictionary = game.room.security_search_position("investigator", receiver.global_position,
			sender.global_position, sight, Vector3.INF, 9.0, rng)
		if choice.has("destination"): choices[choice.destination] = true
	check("different seeds choose several legal positions", choices.size() > 1)
	check("solid centers, wrong elevations, and nonfinite destinations are rejected",
		game.room.security_search_path(receiver.global_position, Vector3(27,0,35)).is_empty()
		and game.room.security_search_path(receiver.global_position, Vector3(27,1.2,33)).is_empty()
		and game.room.security_search_path(receiver.global_position, Vector3.INF).is_empty())

	await fresh()
	sender._physics_process(.016)
	step(.7)
	sender.receive_hit(100)
	step(.7)
	check("C transmission interrupted by death leaves no incident or receiver knowledge",
		incident().is_empty() and receiver.last_known == Vector3.INF)
	print("SEARCH SCENARIO C report=", game.security_director.get_radio_history())

	await fresh()
	active = await deliver()
	var old_destination: Vector3 = active.assignments[SMG].destination
	game.player.global_position = C
	await frames(2)
	check("E receiver can genuinely reacquire the player", receiver.can_see_player())
	receiver._physics_process(.016)
	check("E real sight clears coordinated execution and uses local combat reaction",
		receiver._search_assignment.is_empty() and receiver.last_known == game.player.camera.global_position
		and receiver._reaction > 0 and receiver.state == "suspicious" and incident().is_empty())
	check("E partner still knows only A after reacquisition", sender.last_known == sight
		and sender.last_known != receiver.last_known and sender._path_target != old_destination)
	check("new report delay keeps new information out of partner until delivery",
		game.security_director.get_pending_radio_reports().size() == 1)
	step(1.0)
	check("E partner remains uninformed just before the new deadline", sender.last_known == sight)
	step(.4)
	check("E new delivered evidence can start a distinct incident", incident().get("id", 0) > active.id
		and sender.last_known == game.player.camera.global_position)
	print("SEARCH SCENARIO E new incident=", incident())

	await fresh()
	active = await deliver()
	var episode: int = sender.get_sight_episode()
	var refresh: int = game.record_security_observation(sender, "visual_contact", sight, 1, 8)
	check("continuous visual refresh uses same acquisition token", episode > 0)
	game.queue_security_radio(sender, refresh)
	step(1.4)
	check("later report from same acquisition cannot reset deadline", incident().id == active.id and incident().deadline == active.deadline)
	sender.receive_hit(100)
	check("dead holder releases only its own reservation", incident().assignments.size() == 1 and sender._search_assignment.is_empty())
	receiver.receive_hit(100)
	check("dead investigator immediately cancels and clears final reservation", incident().is_empty() and receiver._search_assignment.is_empty())

	await fresh()
	active = await deliver()
	receiver.magazine = 0
	receiver._physics_process(.016)
	check("required reload suspends search execution", receiver.state == "reload" and not receiver._search_assignment.is_empty())
	game.set_paused(true)
	step(10)
	game.open_journal()
	step(10)
	game.open_settings()
	step(10)
	check("pause journal and settings freeze the incident deadline", incident().id == active.id
		and game.security_simulation_time() == 1.4)
	game.set_paused(false)
	step(7)
	check("original evidence expires and removes even a suspended assignment",
		incident().is_empty() and receiver._search_assignment.is_empty() and sender._search_assignment.is_empty())

	await fresh(420)
	game.session.preferences.muted = true
	active = await deliver()
	check("mute leaves assignment and knowledge unchanged", active.assignments[RIFLE].path == investigator.path
		and receiver.last_known == sight and game.audio._voices.is_empty())
	game.session.preferences.muted = false
	var retained: RefCounted = game.security_director
	var stale: Dictionary = active.assignments[RIFLE]
	game.retry_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	check("retry removes old incidents, reservations and enemy assignments", retained.get_search_incident().is_empty()
		and not game._security_enemy_by_id(RIFLE).receive_search_assignment(stale))
	for mode in ["victory", "defeat", "abandon"]:
		await fresh()
		await deliver()
		retained = game.security_director
		if mode == "abandon": game.show_title()
		else: game.finish(mode == "victory")
		check(mode + " clears the retained director incident", retained.get_search_incident().is_empty() and game.security_director == null)

	await fresh()
	await report_and_break_sight()
	receiver.global_position = Vector3(27,0,35) # Artificial invalid start inside a real solid.
	step(.8)
	check("blocked recipient falls back to a reachable solo sender assignment",
		incident().get("assignments", {}).size() == 1 and incident().assignments.has(SMG)
		and receiver._search_assignment.is_empty())

	await fresh()
	sender._physics_process(.016)
	step(1.4)
	check("busy sender leaves explicit single-guard fallback", incident().get("assignments", {}).size() == 1
		and incident().assignments.has(RIFLE) and sender._search_assignment.is_empty())
	print("SECURITY SEARCH: %d/%d passed; failures=%d" % [checks - failures, checks, failures])
	game.queue_free()
	await frames(2)
	quit(1 if failures else 0)
