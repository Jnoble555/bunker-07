extends Node3D
## M1 integration owner. This is a partial Control Room port, not campaign parity.

const PlayerScript = preload("res://scripts/player.gd")
const RoomScript = preload("res://scripts/room.gd")
const GuardScript = preload("res://scripts/armored_guard.gd")
const PANEL := Vector3(9, 0, 15)
const CORE := Vector3(17, 0, 11)
const EXIT := Vector3(23, 0, 3)

var player: CharacterBody3D
var guard: CharacterBody3D
var room: Node3D
var active: bool = false
var ammo: int = 8
var health: int = 100
var cooldown: float = 0
var reload_remaining: float = 0
var flash: float = 0
var hit_feedback: float = 0
var hurt_feedback: float = 0
var elapsed: float = 0
var panel_disabled: bool = false
var alarm_triggered: bool = false
var alarm_active: bool = false
var core_collected: bool = false
var shots: int = 0
var hits: int = 0
var attempts: int = 0
var events: Array[Dictionary] = []
var pending_actions: Array[String] = []
var hud: Label
var status: Label
var feedback: Label
var crosshair: Label
var tint: ColorRect
var menu: PanelContainer
var menu_title: Label
var menu_text: Label
var deploy_button: Button
var resume_button: Button
var retry_button: Button
var title_button: Button
var menu_state: String = "title"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_install_inputs()
	room = RoomScript.new()
	room.name = "World"
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	room.build()
	player = PlayerScript.new()
	player.name = "Player"
	add_child(player)
	player.setup(self)
	guard = GuardScript.new()
	guard.name = "ArmoredGuard"
	add_child(guard)
	guard.setup(self, Vector3(9, 0, 11))
	_build_ui()
	show_title()

func _install_inputs() -> void:
	var bindings := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"strafe_left": [KEY_A], "strafe_right": [KEY_D],
		"turn_left": [KEY_LEFT], "turn_right": [KEY_RIGHT], "fire": [KEY_SPACE],
		"weapon_1": [KEY_1], "weapon_2": [KEY_2], "crouch": [KEY_CTRL], "sprint": [KEY_SHIFT], "lean_left": [KEY_Q], "lean_right": [KEY_C],
		"reload": [KEY_R], "interact": [KEY_E], "pause": [KEY_ESCAPE, KEY_P], "retry": [KEY_F5]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("fire", mouse):
		InputMap.action_add_event("fire", mouse)

	var aim_button := InputEventMouseButton.new()
	aim_button.button_index = MOUSE_BUTTON_RIGHT
	if not InputMap.has_action("aim_weapon"): InputMap.add_action("aim_weapon")
	if not InputMap.action_has_event("aim_weapon", aim_button): InputMap.action_add_event("aim_weapon", aim_button)

func request_action(action: String) -> void:
	if active and not get_tree().paused:
		pending_actions.append(action)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("pause") and active:
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("retry") and menu_state != "title":
		retry_run()
		return
	if not active or get_tree().paused:
		return
	for action in ["fire", "reload", "interact", "weapon_1", "weapon_2"]:
		if event.is_action_pressed(action):
			if action == "fire":
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			request_action(action)
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active and not get_tree().paused:
		set_paused(true)

func start_run() -> void:
	get_tree().paused = false
	active = true
	ammo = 8
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
	pending_actions.clear()
	player.reset_player()
	guard.reset_guard()
	room.set_gate(true)
	room.set_panel_disabled(false)
	if room.has_method("set_core_collected"):
		room.set_core_collected(false)
	attempts += 1
	register_event("mission_start", "control-room / partial M1")
	menu_state = "play"
	menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_hud()

func retry_run() -> void:
	start_run()

func set_paused(value: bool) -> void:
	if not active:
		return
	pending_actions.clear()
	get_tree().paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if value:
		_show_menu("pause", "PAUSED", "Timed actions and enemy state are frozen.")
	else:
		menu_state = "play"
		menu.hide()

func show_title() -> void:
	active = false
	get_tree().paused = false
	pending_actions.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_menu("title", "BUNKER 07", "PARTIAL GODOT PORT / CONTROL ROOM M1\n\nDisable the alarm panel in maintenance, secure the core, and extract.\nOne armored patrol is active. Cameras and reinforcements are not ported yet.\n\nWASD / Up, Down: move · Mouse / Left, Right: aim\nClick / Space: fire · R: reload · E: panel · Esc / P: pause · F5: retry\n\nThe browser version remains the complete three-mission game.")

func _physics_process(delta: float) -> void:
	if not active or get_tree().paused:
		return
	elapsed += delta
	cooldown = maxf(0, cooldown - delta)
	flash = maxf(0, flash - delta)
	hit_feedback = maxf(0, hit_feedback - delta)
	hurt_feedback = maxf(0, hurt_feedback - delta)
	if reload_remaining > 0:
		reload_remaining = maxf(0, reload_remaining - delta)
		if reload_remaining == 0:
			ammo = 8
	var actions := pending_actions.duplicate()
	pending_actions.clear()
	for action in actions:
		match action:
			"fire": shoot()
			"reload": begin_reload()
			"interact": interact()
	if not core_collected and (panel_disabled or alarm_triggered) and planar_distance(player.global_position, CORE) < 1.3:
		core_collected = true
		room.set_gate(false)
		if room.has_method("set_core_collected"):
			room.set_core_collected(true)
		register_event("core_collected", "data_core_1")
	if core_collected and planar_distance(player.global_position, EXIT) < 1.2:
		finish(true)
	_update_hud()

func shoot() -> void:
	if not active or get_tree().paused or ammo == 0 or cooldown > 0 or reload_remaining > 0:
		return
	ammo -= 1
	shots += 1
	cooldown = 0.24
	flash = 0.10
	var origin: Vector3 = player.camera.global_position
	var direction: Vector3 = -player.camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 50, 1 | 4, [player.get_rid()])
	query.collide_with_areas = true
	query.hit_from_inside = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	# Retain the browser's target-center depth rule at wall corners, even though
	# native hitscan first intersects a volume's surface rather than its center.
	var wall_query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 50, 1)
	var wall_hit := get_world_3d().direct_space_state.intersect_ray(wall_query)
	var wall_depth: float = origin.distance_to(wall_hit.position) if not wall_hit.is_empty() else 50.0
	var target_depth: float = (guard.global_position - origin).dot(direction)
	if not hit.is_empty() and hit.collider.has_method("receive_hit") and target_depth > 0 and target_depth < wall_depth:
		hit.collider.receive_hit()
		hits += 1
		hit_feedback = 0.24
	register_event("shot", "hit" if hit_feedback > 0 else "miss")

func begin_reload() -> void:
	if active and not get_tree().paused and ammo < 8 and reload_remaining == 0:
		reload_remaining = 0.8
		register_event("reload", "")

func interact() -> void:
	if not active or get_tree().paused or panel_disabled:
		return
	if planar_distance(player.global_position, PANEL) > 1.7:
		return
	if not has_los(player.camera.global_position, PANEL + Vector3(0, 1.4, 0)):
		return
	panel_disabled = true
	alarm_active = false
	guard.alert_progress = 0
	room.set_panel_disabled(true)
	register_event("alarm_disabled", "silenced" if alarm_triggered else "prevented")

func has_los(from: Vector3, to: Vector3) -> bool:
	if from.distance_to(to) < 0.001:
		return true
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func trigger_alarm() -> void:
	if not active or panel_disabled or alarm_triggered:
		return
	alarm_triggered = true
	alarm_active = true
	register_event("alarm_triggered", "reinforcements deferred in M1")

func damage_player(amount: int, source: Vector3) -> void:
	if not active or get_tree().paused:
		return
	health = maxi(0, health - amount)
	hurt_feedback = 0.22
	register_event("damage", "%s from %s" % [amount, source])
	if health == 0:
		finish(false)

func finish(won: bool) -> void:
	if not active:
		return
	register_event("mission_clear" if won else "mission_failed", "stealth" if not alarm_triggered else "alarm")
	active = false
	pending_actions.clear()
	reload_remaining = 0
	guard.attack_windup = 0
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var accuracy := "%d%% (%d/%d)" % [roundi(float(hits) / shots * 100), hits, shots] if shots else "No shots"
	_show_menu("result", "SECTION CLEAR" if won else "MISSION FAILED", "PARTIAL PORT RESULT\n\nActive time: %.1fs · Accuracy: %s\nAttempt: %d · Alarm: %s\n\nNo campaign decisions are committed by this milestone.\nRanks, optional objectives and other missions remain browser-only." % [elapsed, accuracy, attempts, "triggered" if alarm_triggered else "avoided"])

func register_event(event: String, detail: String = "", _bot_id: String = "") -> void:
	events.append({"attempt": attempts, "time": elapsed, "event": event, "detail": detail})

static func planar_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	tint = ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.8, 0.08, 0.02, 0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tint)
	hud = Label.new()
	hud.position = Vector2(24, 18)
	hud.add_theme_font_size_override("font_size", 22)
	hud.add_theme_color_override("font_color", Color("e0cf94"))
	root.add_child(hud)
	status = Label.new()
	status.position = Vector2(24, 52)
	status.add_theme_font_size_override("font_size", 19)
	status.add_theme_color_override("font_color", Color("8cddc6"))
	root.add_child(status)
	feedback = Label.new()
	feedback.position = Vector2(24, 84)
	feedback.add_theme_color_override("font_color", Color("ffb277"))
	root.add_child(feedback)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 28)
	root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(8, 18)
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -430
	menu.offset_right = 430
	menu.offset_top = -245
	menu.offset_bottom = 245
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.065, 0.97)
	style.border_color = Color("7b8962")
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	menu.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	menu.add_child(column)
	menu_title = Label.new()
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 42)
	column.add_child(menu_title)
	menu_text = Label.new()
	menu_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_text.add_theme_font_size_override("font_size", 18)
	column.add_child(menu_text)
	deploy_button = _button(column, "Deploy to Control Room", start_run)
	resume_button = _button(column, "Resume", func(): set_paused(false))
	retry_button = _button(column, "Retry section [F5]", retry_run)
	title_button = _button(column, "Return to title", show_title)

func _button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_menu(state: String, title: String, text: String) -> void:
	menu_state = state
	menu_title.text = title
	menu_text.text = text
	deploy_button.visible = state == "title"
	resume_button.visible = state == "pause"
	retry_button.visible = state != "title"
	title_button.visible = state != "title"
	menu.show()
	_update_hud()

func _update_hud() -> void:
	hud.text = "BUNKER 07 / PARTIAL GODOT PORT   |   HEALTH %d   AMMO %d/8   %.0fs" % [health, ammo, elapsed]
	var objective := "CORE SECURED · REACH EXTRACTION" if core_collected else "DISABLE PANEL OR RISK DETECTION · SECURE CORE"
	if planar_distance(player.global_position, PANEL) <= 1.7:
		objective += "   |   " + ("PANEL OFF" if panel_disabled else "E · DISABLE / SILENCE ALARM")
	status.text = objective
	var warnings: Array[String] = []
	if alarm_active: warnings.append("ALARM ACTIVE (reinforcements not ported)")
	if guard.alert_progress > 0 and not alarm_triggered: warnings.append("GUARD LOCKING · BREAK SIGHT")
	if guard.attack_windup > 0: warnings.append("BOT ATTACK · MOVE!")
	if reload_remaining > 0: warnings.append("RELOADING %.1fs" % reload_remaining)
	if ammo == 0 and reload_remaining == 0: warnings.append("EMPTY · R TO RELOAD")
	feedback.text = "   |   ".join(warnings)
	tint.color.a = hurt_feedback * 1.4
	crosshair.text = "×" if hit_feedback > 0 else "+"
	hud.visible = active and not get_tree().paused
	status.visible = hud.visible
	feedback.visible = hud.visible
	crosshair.visible = hud.visible


func interaction_los(from: Vector3, target: Vector3) -> bool:
	if from.distance_to(target) < 0.03: return true
	var query := PhysicsRayQueryParameters3D.create(from, target, 1)
	query.hit_from_inside = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return true
	return hit.collider.get_meta("interaction_at", Vector3.INF).distance_to(target - Vector3(0,1.4,0)) < 0.01

func device_los(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from + Vector3(0,1.4,0), to + Vector3(0,1.4,0), 1)
	var excluded: Array[RID] = []
	for prop in get_tree().get_nodes_in_group("solid_props"):
		if prop.get_meta("interaction_at", Vector3.INF).distance_to(from) < 0.01:
			excluded.append(prop.get_rid())
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func get_weapon_def() -> Dictionary:
	return preload("res://scripts/weapon_definitions.gd").DATA.pistol
