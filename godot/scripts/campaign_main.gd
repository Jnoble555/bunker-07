extends "res://scripts/main.gd"
const OperationData = preload("res://scripts/tactical_operation_data.gd")
const OperationRoom = preload("res://scripts/tactical_operation_room.gd")
const TacticalEnemy = preload("res://scripts/tactical_enemy.gd")
var operation_mode := false
var operation_stage := 0
var operation_button: Button
const WeaponDefs = preload("res://scripts/weapon_definitions.gd")
var weapon_id := "pistol"
var weapon_ammo: Dictionary = {}
var pickups: Array[Dictionary] = []
var pickup_nodes: Node3D
func get_weapon_def() -> Dictionary:
	return WeaponDefs.DATA[weapon_id]

## Campaign session built on the independently tested M1 movement/UI shell.
const MissionData = preload("res://scripts/mission_data.gd")
const CampaignState = preload("res://scripts/campaign_state.gd")
const EncounterSystems = preload("res://scripts/encounter_systems.gd")
const NativeAudio = preload("res://scripts/native_audio.gd")
var session = CampaignState.new()
var systems: RefCounted
var audio: RefCounted
var missions: Array[Dictionary] = MissionData.all_missions()
var mission_index: int = 1
var mission: Dictionary = {}
var enemies: Array = []
var power_restored: bool = false
var reinforcement_spawned: bool = false
var first_route: String = ""
var last_result: Dictionary = {}
var last_won: bool = false
var message: String = ""
var message_left: float = 0
var damage_direction: String = ""
var tutorial_index: int = 0
var tutorial_active: bool = false
var tutorial_text: Label
var tutorial_steps: Array[String] = ["WASD move / Ctrl crouch / Shift sprint / Q,C lean / RMB aim / E pickups / 1,2,3 weapons","Aim with mouse / Left, Right","Fire with Click / Space","Reload with R"]
var campaign_button: Button
var continue_button: Button
var settings_button: Button
var journal_button: Button
var controls_button: Button
var export_button: Button
var back_button: Button
var confirm_button: Button
var settings_box: VBoxContainer
var volume_slider: HSlider
var sensitivity_slider: HSlider
var mute_check: CheckBox
var return_state: String = "title"
var quitting: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	_install_inputs()
	player = PlayerScript.new()
	player.name = "Player"
	add_child(player)
	player.setup(self)
	systems = EncounterSystems.new()
	systems.setup(self)
	audio = NativeAudio.new()
	audio.setup(self)
	_load_mission()
	super._build_ui()
	_build_campaign_ui()
	show_title()

func _exit_tree() -> void:
	# Explicitly detach streams before the audio server outlives scene teardown.
	if audio: audio.shutdown()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_safely()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		super._notification(what)

func _quit_safely() -> void:
	if quitting: return
	quitting = true
	active = false
	pending_actions.clear()
	get_tree().paused = true
	if audio: audio.shutdown()
	# The mixer releases stopped playbacks asynchronously; keep the event loop
	# alive briefly rather than exiting during the same audio command batch.
	await get_tree().create_timer(0.15,true).timeout
	get_tree().quit()

func _load_mission() -> void:
	mission = missions[mission_index].duplicate(true)
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.free()
	enemies.clear()
	guard = null
	if is_instance_valid(room): room.free()
	room = OperationRoom.new() if operation_mode else RoomScript.new()
	room.name = "World"
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	room.build(mission)
	for spec: Dictionary in mission.bots:
		var initial: Dictionary = spec.duplicate(true)
		if mission.id=="blackout" and session.decisions.security_disabled: initial.hp = 0
		spawn_enemy(initial)
	if mission.id=="blackout" and session.decisions.alarm_raised and not session.decisions.security_disabled:
		spawn_enemy({"id":"pursuit-armor","position":Vector3(15,0,9),"role":"armored","hp":3,"is_guard":false})

func spawn_enemy(spec: Dictionary) -> CharacterBody3D:
	var enemy = TacticalEnemy.new() if operation_mode else GuardScript.new()
	add_child(enemy)
	enemy.setup(self,spec.position,spec)
	enemies.append(enemy)
	if spec.get("is_guard",false) or guard==null: guard = enemy
	return enemy

func _install_inputs() -> void:
	super._install_inputs()
	if not InputMap.has_action("weapon_3"):
		InputMap.add_action("weapon_3")
		var slot := InputEventKey.new()
		slot.physical_keycode = KEY_3
		InputMap.action_add_event("weapon_3",slot)
	if not InputMap.has_action("journal"):
		InputMap.add_action("journal")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_J
		InputMap.action_add_event("journal",event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event.is_action_pressed("pause") and active:
		if menu_state in ["settings","journal","confirm"]: _back_to_pause()
		else: set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal") and active:
		open_journal()
		return
	if event.is_action_pressed("retry") and menu_state not in ["title","briefing","settings"]:
		retry_run()
		return
	if not active or get_tree().paused: return
	for action in ["fire","reload","interact","weapon_1","weapon_2","weapon_3"]:
		if event.is_action_pressed(action):
			if action=="fire": Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			request_action(action)
			get_viewport().set_input_as_handled()

func new_operation() -> void:
	operation_mode = true
	missions = [OperationData.definition()]
	mission_index = 0
	operation_stage = 0
	session.retries["tactical-operation"] = 0
	show_briefing()

func new_campaign() -> void:
	operation_mode = false
	missions = MissionData.all_missions()
	session.new_campaign()
	mission_index = 0
	show_briefing()

func show_briefing() -> void:
	active = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var definition: Dictionary = missions[mission_index]
	_show_menu("briefing",definition.title,"%s\n\n%s" % ["STANDALONE TACTICAL OPERATION" if operation_mode else "MISSION %d OF %d" % [mission_index+1,missions.size()],definition.briefing])

func deploy_current() -> void:
	start_run()

func advance_campaign() -> void:
	if not last_won: return
	if operation_mode:
		show_title()
		return
	if mission_index<missions.size()-1:
		mission_index += 1
		show_briefing()
	else: new_campaign()

func start_run() -> void:
	active = false
	if audio: audio.stop_all()
	get_tree().paused = false
	pending_actions.clear()
	reset_inventory()
	health = 100
	cooldown = 0
	reload_remaining = 0
	flash = 0
	hit_feedback = 0
	hurt_feedback = 0
	elapsed = 0
	shots = 0
	hits = 0
	panel_disabled = false
	alarm_triggered = false
	alarm_active = false
	core_collected = false
	power_restored = false
	reinforcement_spawned = false
	operation_stage = 0
	first_route = ""
	message_left = 0
	session.begin_attempt()
	_load_mission()
	player.reset_player()
	player.global_position = mission.spawn
	systems.reset()
	make_pickups()
	attempts += 1
	register_event("mission_start","")
	last_result = {}
	last_won = false
	tutorial_index = 0
	tutorial_active = mission.id=="breach" and not session.tutorial_seen
	menu_state = "play"
	active = true
	menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_hud()

func retry_run() -> void:
	var id: String = missions[mission_index].id
	session.retries[id] = session.retries.get(id,0)+1
	start_run()

func show_title() -> void:
	active = false
	get_tree().paused = false
	pending_actions.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_menu("title","BUNKER 07","DEEP SIGNAL / TACTICAL PvE OPERATION\nArmed patrols, alternate approaches and an elevated archive.\n\nThe original three-mission campaign is also available.")

func set_paused(value: bool) -> void:
	if value and player: player.clear_held_inputs()
	super.set_paused(value)
	_update_hud()

func _physics_process(delta: float) -> void:
	if not active or get_tree().paused: return
	elapsed += delta
	cooldown = maxf(0,cooldown-delta)
	flash = maxf(0,flash-delta)
	hit_feedback = maxf(0,hit_feedback-delta)
	hurt_feedback = maxf(0,hurt_feedback-delta)
	message_left = maxf(0,message_left-delta)
	if reload_remaining>0:
		reload_remaining = maxf(0,reload_remaining-delta)
		if reload_remaining==0:
			var state: Dictionary = weapon_ammo[weapon_id]
			var loaded: int = mini(int(get_weapon_def().capacity)-ammo, int(state.reserve))
			ammo += loaded
			state.reserve -= loaded
			state.magazine = ammo
	if Input.get_vector("strafe_left","strafe_right","move_forward","move_back").length()>0: progress_tutorial("move")
	if Input.get_axis("turn_right","turn_left")!=0: progress_tutorial("aim")
	var actions := pending_actions.duplicate()
	pending_actions.clear()
	for action in actions:
		match action:
			"fire": shoot()
			"reload": begin_reload()
			"interact": interact()
			"weapon_1": switch_weapon("pistol")
			"weapon_2": switch_weapon("smg")
			"weapon_3": switch_weapon("shotgun")
	if get_weapon_def().automatic and Input.is_action_pressed("fire"): shoot()
	systems.update(delta)
	if not active: return
	if mission.id=="control-room":
		if first_route=="":
			var p: Vector3 = player.global_position/2
			if p.z>=4.7 and p.z<=6.1 and p.x>=1.8 and p.x<8.5: first_route = "direct"
			elif p.z>=6.8 and p.z<=8.2 and p.x>=3 and p.x<8.5: first_route = "maintenance"
			if first_route!="": register_event("route_entered",first_route)
		if not core_collected and (panel_disabled or alarm_triggered) and planar_distance(player.global_position,mission.core)<1.3:
			core_collected = true
			room.set_gate(false)
			room.set_core_collected(true)
			register_event("core_collected","data_core_1")
	if operation_mode:
		if operation_stage==2 and player.global_position.distance_to(mission.exit)<1.5: finish(true)
		_update_hud()
		return
	var unlocked: bool = core_collected if mission.id=="control-room" else power_restored if mission.id=="blackout" else remaining()==0
	if unlocked and planar_distance(player.global_position,mission.exit)<1.2: finish(true)
	_update_hud()

func shoot() -> void:
	if not active or get_tree().paused or ammo==0 or cooldown>0 or reload_remaining>0: return
	ammo -= 1
	shots += 1
	cooldown = get_weapon_def().interval
	weapon_ammo[weapon_id].magazine = ammo
	flash = .10
	hit_feedback = 0
	progress_tutorial("fire")
	play_sound(get_weapon_def().sound,player.global_position)
	var origin: Vector3 = player.camera.global_position
	var hit_target := ""
	var blast_hit := false
	var definition := get_weapon_def()
	for pellet in int(definition.get("pellets",1)):
		var direction: Vector3 = -player.camera.global_basis.z
		var spread: float = definition.spread * (0.5 if player.aiming else 1.0)
		if spread > 0:
			direction = (direction + player.camera.global_basis.x * randf_range(-spread,spread) + player.camera.global_basis.y * randf_range(-spread,spread)).normalized()
		var target := _fire_ray(origin,direction,float(definition.range),int(definition.damage))
		if target!="":
			blast_hit = true
			hit_target = target
	if blast_hit:
		hits += 1
		hit_feedback = .24
	# Damage callbacks observe the current counters after each ray; shot rows are blast-level.
	systems.on_shot()
	for enemy in enemies:
		if enemy.has_method("hear_shot"): enemy.hear_shot(origin)
	register_event("shot",weapon_id if weapon_id=="shotgun" else "",hit_target if hit_target not in ["camera","lamp"] else "")

func _fire_ray(origin: Vector3, direction: Vector3, shot_range: float, damage: int) -> String:
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*shot_range,1|4|8,[player.get_rid()])
	query.collide_with_areas = true
	query.hit_from_inside = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return ""
	_impact(hit.position)
	var object: Node3D = hit.collider
	var wall := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+direction*shot_range,1))
	var surface_depth: float = origin.distance_to(hit.position)
	if not wall.is_empty() and surface_depth>origin.distance_to(wall.position)+.001: return ""
	if object.has_method("receive_hit") and surface_depth<=.001:
		var center: Vector3 = object.get_parent().global_position if object is Area3D else object.global_position
		if (center-origin).dot(direction)<=0: return ""
	if object.has_meta("device_id"):
		var device: String = str(object.get_meta("device_id"))
		if systems.shootable_hit(device): return device
	elif object.has_method("receive_hit"):
		# The physical nearest ray surface enforces cover for each pellet independently.
		var actor: Node = object.get_parent() if object is Area3D else object
		if actor.get("hp") != null and int(actor.get("hp"))<=0: return ""
		# Count once before callbacks (bot_disabled analytics includes the hit).
		var old_hits := hits
		hits = mini(shots,hits+1)
		object.receive_hit(damage)
		hits = old_hits
		play_sound("hit",hit.position)
		return str(enemies.find(actor)+1)
	return ""

func begin_reload() -> void:
	if active and not get_tree().paused and ammo<int(get_weapon_def().capacity) and int(weapon_ammo[weapon_id].reserve)>0 and reload_remaining==0:
		reload_remaining = get_weapon_def().reload
		progress_tutorial("reload")
		play_sound("reload",player.global_position)
		register_event("reload","")

func interact() -> void:
	if not active or get_tree().paused: return
	if collect_pickup(): return
	if operation_mode:
		operation_interact()
		return
	if systems.interact():
		play_sound("use",player.global_position)
		return
	if mission.id=="breach" or panel_disabled or planar_distance(player.global_position,mission.panel)>1.7: return
	if not interaction_los(player.camera.global_position,mission.panel+Vector3(0,1.4,0)): return
	panel_disabled = true
	room.set_panel_disabled(true)
	play_sound("use",mission.panel)
	if mission.id=="control-room":
		alarm_active = false
		if is_instance_valid(guard): guard.alert_progress = 0
		register_event("alarm_disabled","silenced" if alarm_triggered else "prevented")
	else:
		power_restored = true
		room.set_power_restored(true)
		register_event("power_restored","power_switch_1")

func trigger_alarm() -> void:
	if not active or mission.id!="control-room" or panel_disabled or alarm_triggered: return
	alarm_triggered = true
	alarm_active = true
	register_event("alarm_triggered","guard_1")
	play_sound("alarm",player.global_position)
	if not reinforcement_spawned:
		reinforcement_spawned = true
		spawn_enemy({"id":"reinforcement_1","position":Vector3(15,0,15),"role":"scout","hp":2,"is_guard":false})
		register_event("reinforcement_spawned","reinforcement_1")
	announce("ALARM ACTIVE / Reinforcement deployed. Break sight or overload the grid.")

func damage_player(amount: int,source: Vector3) -> void:
	if not active or get_tree().paused: return
	health = maxi(0,health-amount)
	hurt_feedback = .22
	damage_direction = "DAMAGE FROM RIGHT" if (source-player.global_position).dot(player.global_basis.x)>0 else "DAMAGE FROM LEFT"
	play_sound("damage",source)
	var attacker := ""
	for i in enemies.size():
		if enemies[i].global_position.distance_to(source)<.01:
			attacker = str(i+1)
			break
	register_event("damage",str(amount),attacker)
	if health==0: finish(false)

func remaining() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.hp>0: count += 1
	return count

func finish(won: bool) -> void:
	if not active: return
	register_event("mission_clear" if won else "mission_failed","failure" if not won else "alarm" if mission.id=="control-room" and alarm_triggered else "stealth" if mission.id=="control-room" else "clear")
	last_won = won
	last_result = session.commit(mission,_snapshot(),won)
	active = false
	pending_actions.clear()
	reload_remaining = 0
	for enemy in enemies: enemy.attack_windup = 0
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var accuracy: String = "%d%% (%d/%d)" % [roundi(float(hits)/shots*100),hits,shots] if shots else "No shots"
	var text: String = "Active time: %.1fs · Accuracy: %s\nRetries: %d\n" % [elapsed,accuracy,session.retries.get(mission.id,0)]
	if won:
		text += "RANK %s · %s\n" % [last_result.rank.grade,"CLEAN RUN" if last_result.rank.stealth else "COMBAT RUN"]
		if mission.id=="control-room": text += "Intel: %s · Secret: %s\n" % [systems.intel,systems.secret]
	if won and not operation_mode and mission_index==missions.size()-1:
		for id in ["breach","control-room","blackout"]:
			var summary: Dictionary = session.summaries.get(id,{})
			if not summary.is_empty(): text += "\n%s / %.1fs / Rank %s / %d retries" % [id.to_upper(),summary.time,summary.rank.grade,summary.retries]
	_show_menu("summary" if won and not operation_mode and mission_index==missions.size()-1 else "result","CAMPAIGN COMPLETE" if won and not operation_mode and mission_index==missions.size()-1 else mission.title+" CLEAR" if won else "MISSION FAILED",text)

func _snapshot() -> Dictionary:
	return {"panel_disabled":panel_disabled,"alarm_triggered":alarm_triggered,"intel":systems.intel,"secret":systems.secret,"elapsed":elapsed,"shots":shots,"hits":hits,"health":health}

func register_event(event: String,detail: String="",bot_id: String="") -> void:
	# Preserve the browser's target/detail columns, including module adapters.
	if bot_id=="" and event=="alarm_disabled": bot_id = "alarm_panel_1"
	elif bot_id=="" and event in ["alarm_triggered","reinforcement_spawned","core_collected","power_restored","camera_detected","camera_destroyed","light_destroyed","grid_overloaded","intel_recovered","bulkhead_obstructed","bulkhead_toggled","secret_found","guard_investigating","power_rerouted","bot_disabled","attack_windup"]:
		var split: int = detail.find("|")
		bot_id = detail.substr(0,split) if split>=0 else detail
		detail = detail.substr(split+1) if split>=0 else ""
		if event in ["bot_disabled","attack_windup"]:
			for i in enemies.size():
				if enemies[i].id==bot_id:
					bot_id = str(i+1)
					break
	events.append({"run":attempts,"elapsed_seconds":"%.2f" % elapsed,"event":event,"bot_id":bot_id,"health":health,"ammo":ammo,"shots":shots,"hits":hits,"detail":detail,"mission_id":mission.get("id","")})

func export_csv(path: String="") -> String:
	var destination: String = "user://bunker-07-session.csv" if path=="" else path
	var file := FileAccess.open(destination,FileAccess.WRITE)
	if file==null:
		announce("CSV export failed: "+error_string(FileAccess.get_open_error()))
		return ""
	file.store_string(session.csv_text(events))
	file.close()
	var absolute := ProjectSettings.globalize_path(destination)
	announce("CSV exported: "+absolute)
	if menu_text and menu.visible: menu_text.text += "\n\nCSV saved: "+absolute
	return absolute

func announce(text: String) -> void:
	message = text
	message_left = 7

func play_sound(kind: String,at: Vector3) -> void:
	if audio: audio.play(kind,at)

func _impact(at: Vector3) -> void:
	if get_tree().get_nodes_in_group("impact_sparks").size()>=24: return
	var spark := MeshInstance3D.new()
	spark.process_mode = Node.PROCESS_MODE_PAUSABLE
	var mesh := SphereMesh.new()
	mesh.radius = .055
	mesh.height = .11
	spark.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("ffc175")
	spark.material_override = material
	add_child(spark)
	spark.add_to_group("impact_sparks")
	spark.global_position = at
	var tween := spark.create_tween()
	tween.tween_property(spark,"scale",Vector3.ONE*.01,.18)
	tween.tween_callback(spark.queue_free)
	play_sound("impact",at)

func progress_tutorial(trigger: String) -> void:
	if not active or not tutorial_active: return
	if ["move","aim","fire","reload"][tutorial_index]!=trigger: return
	tutorial_index += 1
	if tutorial_index>=4:
		tutorial_active = false
		session.tutorial_seen = true
		session.save_preferences()

func open_journal() -> void:
	if not active: return
	set_paused(true)
	_show_menu("journal","FIELD LOG","\n\n".join(session.journal))

func open_settings() -> void:
	if active and not get_tree().paused: set_paused(true)
	return_state = menu_state
	_show_menu("settings","SETTINGS","Preferences are saved locally. Audio is optional.")
	volume_slider.set_value_no_signal(session.preferences.volume)
	sensitivity_slider.set_value_no_signal(session.preferences.sensitivity)
	mute_check.set_pressed_no_signal(session.preferences.muted)

func close_settings() -> void:
	if return_state=="title": show_title()
	else: _back_to_pause()

func _back_to_pause() -> void:
	if active: get_tree().paused = true
	_show_menu("pause","PAUSED","Timed actions and enemy state are frozen.")

func _confirm_return() -> void:
	_show_menu("confirm","ABANDON RUN?","Discard this attempt? Session analytics and earlier successful decisions remain until Start Campaign.")

func _abandon() -> void:
	register_event("mission_abandoned","")
	show_title()

func _show_controls() -> void:
	_show_menu("controls","CONTROLS","WASD: move / Mouse: full look\nCtrl: crouch / Shift: sprint / Q,C: lean / RMB: aim / 1,2,3: weapons\nClick / Space: fire · R: reload · E: interact\nJ: field log · P / Esc: pause · F5: retry\n\nBreak sight during enemy windup. Devices show interaction prompts.\nCSV exports to the native user-data folder.")

func _save_settings() -> void:
	session.preferences.volume = volume_slider.value
	session.preferences.sensitivity = sensitivity_slider.value
	session.preferences.muted = mute_check.button_pressed
	session.save_preferences()
	if audio: audio.refresh_volume()

func _reset_settings() -> void:
	session.preferences = CampaignState.DEFAULTS.duplicate()
	session.save_preferences()
	volume_slider.set_value_no_signal(session.preferences.volume)
	sensitivity_slider.set_value_no_signal(session.preferences.sensitivity)
	mute_check.set_pressed_no_signal(false)
	if audio: audio.refresh_volume()

func _build_campaign_ui() -> void:
	var column: VBoxContainer = menu_title.get_parent()
	deploy_button.text = "Deploy"
	campaign_button = _button(column,"Start Campaign",new_campaign)
	operation_button = _button(column,"Deep Signal / Tactical Operation",new_operation)
	continue_button = _button(column,"Continue",advance_campaign)
	settings_button = _button(column,"Settings",open_settings)
	journal_button = _button(column,"Field Log [J]",open_journal)
	controls_button = _button(column,"Controls",_show_controls)
	export_button = _button(column,"Export session CSV",func(): export_csv())
	back_button = _button(column,"Back",func():
		if menu_state=="settings": close_settings()
		elif menu_state=="controls": show_title()
		else: _back_to_pause())
	confirm_button = _button(column,"Confirm return to title",_abandon)
	settings_box = VBoxContainer.new()
	column.add_child(settings_box)
	var label := Label.new()
	label.text = "Master volume"
	settings_box.add_child(label)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 1
	volume_slider.step = .05
	settings_box.add_child(volume_slider)
	label = Label.new()
	label.text = "Mouse sensitivity"
	settings_box.add_child(label)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = .0005
	sensitivity_slider.max_value = .01
	sensitivity_slider.step = .0005
	settings_box.add_child(sensitivity_slider)
	mute_check = CheckBox.new()
	mute_check.text = "Mute"
	settings_box.add_child(mute_check)
	_button(settings_box,"Reset to defaults",_reset_settings)
	volume_slider.value_changed.connect(func(_value): _save_settings())
	sensitivity_slider.value_changed.connect(func(_value): _save_settings())
	mute_check.toggled.connect(func(_value): _save_settings())
	title_button.pressed.disconnect(show_title)
	title_button.pressed.connect(_confirm_return)
	tutorial_text = Label.new()
	tutorial_text.position = Vector2(24,130)
	tutorial_text.size = Vector2(1232,90)
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_text.add_theme_color_override("font_color",Color("e5d7ae"))
	hud.get_parent().add_child(tutorial_text)
	# Long journals/results scroll instead of growing outside the viewport.
	column.remove_child(menu_text)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(menu_text)
	column.add_child(scroll)
	column.move_child(scroll,1)

func _show_menu(state: String,title: String,text: String) -> void:
	if player: player.clear_held_inputs()
	menu_state = state
	menu_title.text = title
	menu_text.text = text
	deploy_button.visible = state=="briefing"
	resume_button.visible = state=="pause"
	retry_button.visible = state=="pause" or (state=="result" and not last_won)
	title_button.visible = state=="pause"
	campaign_button.visible = state=="title"
	operation_button.visible = state=="title"
	continue_button.visible = (state=="result" and last_won) or state=="summary"
	continue_button.text = "Return to title" if operation_mode else "Start New Campaign" if state=="summary" else "Continue"
	settings_button.visible = state in ["title","pause"]
	journal_button.visible = state=="pause"
	controls_button.visible = state=="title"
	export_button.visible = state in ["result","summary","pause"] and not events.is_empty()
	back_button.visible = state in ["settings","journal","confirm","controls"]
	confirm_button.visible = state=="confirm"
	settings_box.visible = state=="settings"
	menu.show()
	_update_hud()

func _update_hud() -> void:
	if not hud: return
	hud.text = "BUNKER 07 / %s | HEALTH %d | %s %d/%d RESERVE %d | %.0fs" % [mission.get("title",""),health,get_weapon_def().name,ammo,get_weapon_def().capacity,weapon_ammo.get(weapon_id,{}).get("reserve",0),elapsed]
	var objective := ""
	match mission.get("id",""):
		"tactical-operation": objective = operation_objective()
		"breach": objective = "DISABLE SECURITY SCOUT" if remaining()>0 else "REACH CONTROL SECTOR"
		"blackout": objective = "POWER RESTORED · REACH LIFT" if power_restored else "FIND BACKUP POWER / SOUTHWEST BAY"
		_: objective = "CORE SECURED · EXTRACT" if core_collected else "DATA CORE REQUIRED · PANEL OR GUARD ALERT"
	if not operation_mode and mission.get("id","")!="breach" and planar_distance(player.global_position,mission.panel)<=1.7: objective += " | PANEL OFF" if panel_disabled else " | E · USE PANEL"
	var nearby_pickup := nearby_pickup()
	var prompt: String = ("E / " + str(nearby_pickup.label)) if not nearby_pickup.is_empty() else (systems.prompt() if systems else "")
	if prompt!="": objective += " | "+prompt
	status.text = objective
	var warnings: Array[String] = []
	if alarm_active: warnings.append("ALARM ACTIVE / REINFORCEMENT DEPLOYED")
	for enemy in enemies:
		if enemy.alert_progress>0 and not alarm_triggered: warnings.append("GUARD LOCKING · BREAK SIGHT")
		if enemy.attack_windup>0: warnings.append("BOT ATTACK · MOVE!")
	if reload_remaining>0: warnings.append("RELOADING %.1fs" % reload_remaining)
	if ammo==0 and reload_remaining==0: warnings.append("EMPTY · R TO RELOAD")
	if hurt_feedback>0: warnings.append(damage_direction)
	feedback.text = " | ".join(warnings)
	tint.color.a = hurt_feedback*1.4
	crosshair.text = "×" if hit_feedback>0 else "+"
	hud.visible = active and not get_tree().paused
	status.visible = hud.visible
	feedback.visible = hud.visible
	crosshair.visible = hud.visible
	if tutorial_text:
		tutorial_text.visible = hud.visible
		tutorial_text.text = tutorial_steps[tutorial_index] if tutorial_active else message if message_left>0 else ""

func reset_inventory() -> void:
	weapon_id = "pistol"
	weapon_ammo = {"pistol":{"magazine":WeaponDefs.DATA.pistol.capacity,"reserve":WeaponDefs.DATA.pistol.reserve}}
	ammo = WeaponDefs.DATA.pistol.capacity
	if player and player.weapon: player.weapon.equip(weapon_id)

func switch_weapon(id: String) -> void:
	if not active or get_tree().paused or not weapon_ammo.has(id) or id == weapon_id: return
	weapon_ammo[weapon_id].magazine = ammo
	reload_remaining = 0
	flash = 0
	var previous := weapon_id
	weapon_id = id
	ammo = int(weapon_ammo[id].magazine)
	player.weapon.equip(id)
	player.muzzle.hide()
	player.muzzle_light.light_energy = 0
	player.weapon.pose(0,0,get_weapon_def().reload,get_weapon_def().recoil)
	register_event("weapon_switched",previous + "->" + id)

func make_pickups() -> void:
	if is_instance_valid(pickup_nodes): pickup_nodes.free()
	pickup_nodes = Node3D.new()
	pickup_nodes.name = "WeaponPickups"
	add_child(pickup_nodes)
	var locations: Array = [
		[Vector3(5,0,4),Vector3(6,0,4)],
		[Vector3(5,0,17),Vector3(5,0,15)],
		[Vector3(5,0,3),Vector3(3,0,5)]
	][0 if operation_mode else mission_index]
	pickups = [
		{"id":"smg","label":"PICK UP SMG / 2 TO EQUIP","position":locations[0],"taken":false},
		{"id":"supply","label":"TAKE AMMUNITION","position":locations[1],"taken":false}
	]
	if operation_mode: pickups = OperationData.supplies()
	for item: Dictionary in pickups:
		var prop := Node3D.new()
		prop.position = item.position + Vector3(0,0.75,0)
		pickup_nodes.add_child(prop)
		if item.id in ["smg","shotgun"]:
			var model: Node3D = load("res://assets/weapons/security_"+str(item.id)+".glb").instantiate()
			model.scale = Vector3.ONE * 0.8
			prop.add_child(model)
		else:
			var mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.3,0.2,0.25)
			mesh.mesh = box
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("ac8750")
			mesh.material_override = material
			prop.add_child(mesh)
		var label := Label3D.new()
		label.text = str(item.id).to_upper()
		label.position.y = 0.4
		label.font_size = 24
		label.pixel_size = 0.0012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		prop.add_child(label)
		item.node = prop

func nearby_pickup() -> Dictionary:
	if not player: return {}
	for item: Dictionary in pickups:
		var target: Vector3 = item.position + Vector3(0,1.0,0)
		if not item.taken and player.camera.global_position.distance_to(target) <= 1.6 and has_los(player.camera.global_position,target):
			return item
	return {}

func collect_pickup() -> bool:
	if not active or get_tree().paused: return false
	var item := nearby_pickup()
	if item.is_empty(): return false
	item.taken = true
	item.node.hide()
	if item.id in ["smg","shotgun"]:
		if not weapon_ammo.has(item.id):
			var definition: Dictionary = WeaponDefs.DATA[item.id]
			weapon_ammo[item.id] = {"magazine":definition.capacity,"reserve":definition.reserve}
		announce(str(item.id).to_upper()+" SECURED / Select 1, 2 or 3.")
	elif item.id == "medical":
		health = mini(100,health+40)
		announce("MEDICAL SUPPLIES +40")
	else:
		for id in weapon_ammo:
			weapon_ammo[id].reserve += 24 if id == "pistol" else 8 if id == "shotgun" else 48
		announce("AMMUNITION SECURED")
	register_event("weapon_pickup",item.id)
	play_sound("use",item.position)
	return true

func operation_objective() -> String:
	var text: String = ["01 / RESTORE ACCESS · SECURITY AMBER TERMINAL", "02 / RECOVER DATA · OPERATIONS UP THE STRIPED RAMP", "03 / EXTRACT · NORTHEAST LIFT"][operation_stage]
	var target: Vector3 = mission.panel if operation_stage==0 else mission.core if operation_stage==1 else mission.exit
	text += " / %dm" % roundi(player.global_position.distance_to(target))
	if operation_stage<2 and player.camera.global_position.distance_to(target+Vector3(0,1.35,0))<1.8 and has_los(player.camera.global_position,target+Vector3(0,1.35,0)):
		text += " | E · " + ("RESTORE ACCESS" if operation_stage==0 else "RECOVER DATA")
	return text

func operation_interact() -> void:
	if operation_stage>=2: return
	var target: Vector3 = mission.panel if operation_stage==0 else mission.core
	var eye_target := target+Vector3(0,1.35,0)
	if player.camera.global_position.distance_to(eye_target)>1.8 or not has_los(player.camera.global_position,eye_target): return
	operation_stage += 1
	panel_disabled = true
	core_collected = operation_stage==2
	register_event("access_restored" if operation_stage==1 else "operation_data_recovered","deep_signal")
	play_sound("use",target)
	announce("ACCESS RESTORED / Reach OPERATIONS via the striped ramp." if operation_stage==1 else "DATA SECURED / Reach the northeast extraction lift.")
