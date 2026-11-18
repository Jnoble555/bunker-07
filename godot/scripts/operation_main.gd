extends "res://scripts/campaign_main.gd"
## Isolated operation mode. Campaign missions and their committed consequences stay separate.
const OperationLevel = preload("res://scenes/operation_level.tscn")
const TacticalEnemy = preload("res://scripts/tactical_enemy.gd")
var objective_stage := 0
var objective_history: Array[String] = []

func _ready() -> void:
	mission_index = 0
	super._ready()

func _load_mission() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			remove_child(enemy)
			enemy.queue_free()
	enemies.clear()
	guard = null
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
	room = OperationLevel.instantiate()
	room.name = "OperationWorld"
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	room.build()
	mission = room.mission_contract().duplicate(true)
	missions = [mission]
	mission_index = 0
	if not session.retries.has(mission.id): session.retries[mission.id] = 0
	for spec: Dictionary in mission.bots: spawn_enemy(spec)

func spawn_enemy(spec: Dictionary) -> CharacterBody3D:
	var enemy := TacticalEnemy.new()
	add_child(enemy)
	enemy.setup(self,spec.position,spec)
	enemies.append(enemy)
	if guard == null: guard = enemy
	return enemy

func show_title() -> void:
	active = false
	get_tree().paused = false
	pending_actions.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_menu("title","BUNKER 07 / IRON RELAY","TACTICAL OPERATION\n\nRestore service access, recover the elevated archive and extract. Armed SMG and rifle patrols investigate, search and use cover. The optional armory contains a shotgun.\n\nOriginal three-mission campaign remains available below.")
	deep_signal_button.hide()
	campaign_button.text = "Start Tactical Operation"
	operation_button.text = "Original Campaign"

func _launch_operation() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/control_room.tscn")

func new_campaign() -> void:
	session.new_campaign()
	session.retries["tactical-operation"] = 0
	show_briefing()

func show_briefing() -> void:
	active = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_menu("briefing","OPERATION: IRON RELAY",str(mission.briefing)+"\n\n1 pistol / 2 SMG / 3 shotgun. F collects and operates terminals. Each retry restores the complete operation. No checkpoint save is available in this milestone.")

func start_run() -> void:
	objective_stage = 0
	objective_history.clear()
	mission_index = 0
	super.start_run()
	tutorial_active = false
	session.journal.clear()
	session.note("IRON RELAY: Service access in Maintenance, raised archive in Operations, extraction lift east. Optional armory west.")
	announce("IRON RELAY / Restore Maintenance access. Optional armory west; lift east.")
	_update_hud()

func pickup_specs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for spec in mission.get("pickups",[]): result.append(spec.duplicate(true))
	return result

func current_objective() -> Dictionary:
	if objective_stage >= mission.get("objectives",[]).size(): return {}
	return mission.objectives[objective_stage]

func objective_reachable(goal: Dictionary) -> bool:
	if goal.is_empty(): return false
	var at: Vector3 = goal.position
	# An elevated archive requires actually reaching its platform, not reaching up from below.
	return absf(player.global_position.y-at.y) < 0.45 and player.camera.global_position.distance_to(at+Vector3(0,1.4,0)) <= 1.8 and interaction_los(player.camera.global_position,at+Vector3(0,1.4,0))

func interact() -> void:
	if not active or get_tree().paused: return
	if collect_pickup(): return
	var goal := current_objective()
	if not objective_reachable(goal): return
	var id: String = goal.id
	objective_history.append(id)
	objective_stage += 1
	if id == "access": room.set_access_granted(true)
	if room.has_method("set_objective_state"): room.set_objective_state(id,true)
	register_event("operation_objective",id)
	play_sound("use",goal.position)
	if id == "extract":
		finish(true)
	else:
		var next := current_objective()
		announce(str(goal.label)+" COMPLETE / "+str(next.get("label","EXTRACT")))
	_update_hud()

func _update_hud() -> void:
	super._update_hud()
	if not hud or mission.get("id","") != "tactical-operation": return
	var goal := current_objective()
	if goal.is_empty():
		status.text = "OPERATION COMPLETE"
		return
	var at: Vector3 = goal.position
	status.text = "%d/3 / %s / %.0fm" % [objective_stage+1,goal.label,player.global_position.distance_to(at)]
	if objective_reachable(goal): status.text += " / F TO OPERATE"
	var item := nearby_pickup()
	if not item.is_empty(): status.text += " / F "+str(item.label)

func finish(won: bool) -> void:
	if not active: return
	if won and objective_stage < mission.get("objectives",[]).size(): return
	last_won = won
	active = false
	pending_actions.clear()
	reload_remaining = 0
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.attack_windup = 0
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	register_event("operation_clear" if won else "operation_failed","iron-relay")
	var accuracy: int = roundi(float(hits)/shots*100) if shots>0 else 100
	last_result = {"time":elapsed,"accuracy":accuracy,"objectives":objective_stage,"retries":session.retries.get(mission.id,0)}
	_show_menu("result","IRON RELAY COMPLETE" if won else "OPERATION FAILED","Objectives: %d/3\nActive time: %.1fs\nAccuracy: %d%% (%d/%d)\nRetries: %d\n\nThis is the standalone tactical operation. Original campaign consequences are unchanged." % [objective_stage,elapsed,accuracy,hits,shots,last_result.retries])
	if won: continue_button.text = "Replay Operation"

func advance_campaign() -> void:
	new_campaign()
