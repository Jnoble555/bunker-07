extends RefCounted
## Native port of src/bunker-systems.js. Session commits belong to main, never devices.

const CAMERA := Vector3(14.6, 0, 11)
const POWER := Vector3(13, 0, 15)
const OVERLOAD := Vector3(17, 0, 15)
const INTEL := Vector3(17, 0, 11)
const DOOR_SWITCH := Vector3(15, 0, 15)
const CACHE := Vector3(15, 0, 17)
const LAMP := Vector3(7, 0, 11.6)

var controller: Node
var power_routed: bool = false
var overloaded: bool = false
var intel: bool = false
var secret: bool = false
var door_open: bool = true
var camera_disabled: bool = false
var camera_alert: float = 0
var camera_angle: float = PI
var lamp_broken: bool = false
var investigation: Dictionary = {}
var noise_count: int = 0
var devices_node: Node3D
var _targets: Dictionary = {}
var _is_control: bool = false
var _visual_state: Array = []

func setup(main: Node) -> void:
	controller = main

func reset() -> void:
	power_routed = false
	overloaded = false
	intel = false
	secret = false
	door_open = true
	camera_disabled = false
	camera_alert = 0
	camera_angle = PI
	lamp_broken = false
	investigation = {}
	noise_count = 0
	_targets.clear()
	_visual_state.clear()
	if is_instance_valid(devices_node):
		if devices_node.get_parent():
			devices_node.get_parent().remove_child(devices_node)
		devices_node.queue_free()
	devices_node = Node3D.new()
	devices_node.name = "Devices"
	devices_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	controller.add_child(devices_node)
	var mission: Dictionary = controller.get("mission")
	var mission_id: String = mission.get("id", "control-room")
	_is_control = mission_id == "control-room"
	if _is_control:
		_make_target("camera", CAMERA)
		_make_target("lamp", LAMP)
		_note("CONTROL LOG: Evacuation cut short. Camera watches the direct hall. Maintenance power feeds the camera and service lights.")
	elif mission_id == "blackout":
		var session: RefCounted = controller.get("session")
		var decisions: Dictionary = session.get("decisions") if session else {}
		if decisions.get("security_disabled", false):
			_note("SECURITY LINK: Your Control Room shutdown has disabled the extraction turret.")
		elif decisions.get("alarm_raised", false):
			_note("SECURITY LINK: Control Room alarm remains on record. An armored pursuit unit is deployed.")
		else:
			_note("BLACKOUT LOG: Backup power is independent of the extraction turret. Watch the long corridor.")
		if decisions.get("intel", false):
			_note("RECOVERED INTEL: Backup switch is in the southwest service bay. Turrets cannot move; cross behind walls.")
	else:
		_note("BREACH LOG: Scout units move quickly but have light armor. Keep space and use the corners.")
	_refresh_visuals()

func _make_target(id: String, at: Vector3) -> void:
	var area := Area3D.new()
	area.name = id.capitalize() + "Target"
	area.position = at
	area.collision_layer = 8
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	area.set_meta("device_id", id)
	area.set_meta("target_center", at + Vector3(0, 1.4, 0))
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.36
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	area.add_child(collision)
	devices_node.add_child(area)
	_targets[id] = area

func update(delta: float) -> void:
	if not _is_control or not _playing():
		return
	camera_angle = PI + sin(float(controller.get("elapsed")) * 0.65) * 0.42
	var enabled: bool = not camera_disabled and not power_routed and not bool(controller.get("panel_disabled")) and not bool(controller.get("alarm_triggered"))
	var player: Node3D = controller.get("player")
	var offset: Vector3 = player.global_position - CAMERA
	var distance: float = Vector2(offset.x, offset.z).length()
	var angle: float = atan2(offset.z, offset.x)
	var in_cone: bool = cos(angle - camera_angle) > 0.91
	var was_tracking: bool = camera_alert > 0
	if not enabled:
		camera_alert = 0
	elif distance < 12 and in_cone and _visible(CAMERA, player.global_position):
		camera_alert = minf(1.25, camera_alert + delta)
	else:
		camera_alert = maxf(0, camera_alert - delta * 2)
	if not was_tracking and camera_alert > 0:
		_sound("detect", CAMERA)
	if camera_alert >= 1.25:
		_event("camera_detected", "camera_1")
		controller.call("trigger_alarm")
		camera_alert = 0
	# Investigation only ages while the surviving unalerted guard can act, as in the reference.
	if not investigation.is_empty() and not bool(controller.get("alarm_triggered")):
		var guard: Node3D = _living_guard()
		if guard and float(guard.get("stagger")) <= 0:
			investigation["left"] = float(investigation["left"]) - delta
			if float(investigation["left"]) <= 0 or _distance(guard.global_position, investigation["position"]) < 0.6:
				investigation = {}
	_refresh_visuals()

func on_shot() -> void:
	if not _is_control or not _playing():
		return
	noise_count += 1
	var guard: Node3D = _living_guard()
	var player: Node3D = controller.get("player")
	if guard and not bool(controller.get("alarm_triggered")) and _distance(guard.global_position, player.global_position) < 12:
		investigation = {"position": player.global_position, "left": 5.0}
		guard.set("facing", atan2(player.global_position.z - guard.global_position.z, player.global_position.x - guard.global_position.x))
		_event("guard_investigating", "guard_1|gunshot")

func shootable_hit(id: String) -> bool:
	if not _is_control or not _playing():
		return false
	if id == "camera" and not camera_disabled:
		camera_disabled = true
		camera_alert = 0
		_disable_target(id)
		_event("camera_destroyed", "camera_1")
		controller.call("announce", "CAMERA DESTROYED: Gunfire can still draw the guard.")
		_sound("impact", CAMERA)
	elif id == "lamp" and not lamp_broken:
		lamp_broken = true
		_disable_target(id)
		_event("light_destroyed", "service_lamp")
		controller.call("announce", "SERVICE LIGHT DESTROYED: Ambient emergency light remains.")
		_sound("impact", LAMP)
	else:
		return false
	_refresh_visuals()
	return true

func _disable_target(id: String) -> void:
	var area: Area3D = _targets.get(id)
	if is_instance_valid(area):
		area.collision_layer = 0

func _devices() -> Array[Dictionary]:
	if not _is_control:
		return []
	var result: Array[Dictionary] = [
		{"id": "power", "position": POWER, "label": "SERVICE POWER OFF" if power_routed else "REROUTE POWER"},
		{"id": "overload", "position": OVERLOAD, "label": "OVERLOAD SPENT" if overloaded else "OVERLOAD GRID"},
		{"id": "intel", "position": INTEL, "label": "INTEL RECOVERED" if intel else "RECOVER OPTIONAL INTEL"},
		{"id": "door", "position": DOOR_SWITCH, "label": "CLOSE BULKHEAD" if door_open else "OPEN BULKHEAD"}
	]
	if not secret:
		result.append({"id": "cache", "position": CACHE, "label": "SEARCH HIDDEN CACHE"})
	return result

func nearby() -> Dictionary:
	if not _is_control:
		return {}
	var player: Node3D = controller.get("player")
	var nearest: Dictionary = {}
	var nearest_distance: float = INF
	for device: Dictionary in _devices():
		var distance: float = _distance(device["position"], player.global_position)
		if distance <= 1.6 and distance < nearest_distance and _visible(player.global_position, device["position"]):
			nearest = device
			nearest_distance = distance
	return nearest

func prompt() -> String:
	var device := nearby()
	if not device.is_empty():
		return "E · " + str(device["label"])
	if camera_alert > 0:
		return "CAMERA TRACKING · %d%%" % ceili(camera_alert / 1.25 * 100)
	if not investigation.is_empty():
		return "GUARD INVESTIGATING · BREAK SIGHT"
	if intel:
		return "OPTIONAL INTEL SECURED"
	return "SERVICE LIGHTS OFF · CAMERA ISOLATED" if power_routed else ""

func interact() -> bool:
	if not _playing():
		return false
	var device := nearby()
	if device.is_empty():
		return false
	var id: String = device["id"]
	match id:
		"power":
			power_routed = not power_routed
			if power_routed:
				camera_alert = 0
			_event("power_rerouted", "service_grid|" + ("isolated" if power_routed else "restored"))
			_note("SERVICE GRID ISOLATED: Camera offline. Lights dimmed; emergency guidance remains active." if power_routed else "SERVICE GRID RESTORED: Camera and service lights online.")
		"overload":
			if overloaded:
				controller.call("announce", "OVERLOAD SPENT: The breaker is fused.")
				return true
			overloaded = true
			var affected: int = 0
			for enemy: Node3D in controller.get("enemies"):
				if int(enemy.get("hp")) > 0 and _distance(enemy.global_position, OVERLOAD) < 8 and _visible(OVERLOAD, enemy.global_position):
					enemy.set("stagger", 3.0)
					enemy.set("attack_windup", 0.0)
					affected += 1
			_event("grid_overloaded", "overload_terminal|%d" % affected)
			_note("GRID OVERLOAD: Nearby units staggered for three seconds. Breaker fused.")
		"intel":
			if intel:
				controller.call("announce", "INTEL ALREADY RECOVERED. Extract to preserve it.")
				return true
			intel = true
			_event("intel_recovered", "evacuation_manifest")
			if not bool(controller.get("panel_disabled")):
				controller.call("trigger_alarm")
			_note("MANIFEST RECOVERED: Personnel were evacuated through a southwest backup-power bay. Extract to preserve the intel.")
		"door":
			if door_open and _door_obstructed():
				_event("bulkhead_obstructed", "maintenance_bulkhead")
				controller.call("announce", "BULKHEAD OBSTRUCTED: Move clear before closing.")
				return true
			door_open = not door_open
			_event("bulkhead_toggled", "maintenance_bulkhead|" + ("open" if door_open else "closed"))
			controller.call("announce", "BULKHEAD OPEN." if door_open else "BULKHEAD CLOSED: Use switch here to reopen.")
		"cache":
			secret = true
			controller.set("health", mini(100, int(controller.get("health")) + 25))
			_event("secret_found", "maintenance_cache")
			_note("HIDDEN CACHE: Recovered medical supplies (+25 health, maximum 100). Log: We left the line live so the exit signs would hold.")
	_sound("use", device["position"])
	_refresh_visuals()
	return true

func _door_obstructed() -> bool:
	var actors: Array = [controller.get("player")]
	for enemy: Node3D in controller.get("enemies"):
		if int(enemy.get("hp")) > 0:
			actors.append(enemy)
	for actor: Node3D in actors:
		var point: Vector3 = actor.global_position
		if point.x + 0.4 > 16 and point.x - 0.4 < 18 and point.z + 0.4 > 12 and point.z - 0.4 < 14:
			return true
	return false

func _refresh_visuals() -> void:
	if not controller or not _is_control:
		return
	var state: Array = [door_open, power_routed, lamp_broken, camera_disabled, bool(controller.get("panel_disabled")), intel, secret]
	if state == _visual_state:
		return
	_visual_state = state
	_room_call("set_bulkhead", not door_open)
	_room_call("set_service_power", not power_routed)
	_room_call("set_service_lamp", not lamp_broken)
	_room_call("set_camera_enabled", not camera_disabled and not power_routed and not bool(controller.get("panel_disabled")))
	var room: Node = controller.get("room")
	if room and room.has_method("set_optional_collected"):
		room.call("set_optional_collected", intel, secret)

func _room_call(method: String, value: bool) -> void:
	var room: Node = controller.get("room")
	if room and room.has_method(method):
		room.call(method, value)

func _note(text: String) -> void:
	var session: RefCounted = controller.get("session")
	if session and session.has_method("note"):
		session.call("note", text)
	controller.call("announce", text)

func _event(event: String, detail: String) -> void:
	controller.call("register_event", event, detail)

func _sound(kind: String, at: Vector3) -> void:
	var audio: RefCounted = controller.get("audio")
	if audio and audio.has_method("play"):
		audio.call("play", kind, at)

func _visible(from: Vector3, to: Vector3) -> bool:
	return bool(controller.call("has_los", from + Vector3(0, 1.4, 0), to + Vector3(0, 1.4, 0)))

func _playing() -> bool:
	return controller and bool(controller.get("active")) and not controller.get_tree().paused

func _living_guard() -> Node3D:
	for enemy: Node3D in controller.get("enemies"):
		if bool(enemy.get("is_guard")) and int(enemy.get("hp")) > 0:
			return enemy
	return null

static func _distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
