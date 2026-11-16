extends RefCounted
## Passive mission-scoped evidence store. No actor references or AI decisions.
signal telemetry_event(event: String, detail: Dictionary)

const MAX_OBSERVATIONS := 128
const KINDS := ["visual_contact", "sound_contact", "visual_lost"]
var _mission_id := ""
var _time := 0.0
var _next_id := 1
var _observations: Array[Dictionary] = []

func initialize_for_mission(mission_id: String) -> void:
	clear()
	if mission_id.strip_edges().is_empty() or mission_id.length() > 96: return
	_mission_id = mission_id
	_emit("security_director_initialized", {})

func get_simulation_time() -> float:
	return _time

func get_mission_id() -> String:
	return _mission_id

func advance(delta: float) -> void:
	if _mission_id.is_empty() or not is_finite(delta) or delta <= 0 or not is_finite(_time + delta): return
	_time += delta
	# Bounded scan; allocate no full-history copy on physics updates.
	var index := 0
	while index < _observations.size():
		if _observations[index].expires_at <= _time:
			var observation := _observations[index]
			_observations.remove_at(index)
			_emit("security_observation_expired", {"id":observation.id, "observer_id":observation.observer_id, "kind":observation.kind, "reason":"ttl"})
		else:
			index += 1

## Invalid input returns 0 without consuming an ID, storing data or emitting telemetry.
func record_observation(observer_id: String, kind: String, position: Vector3,
		confidence: float, ttl_seconds: float, sector_id: String = "", metadata: Dictionary = {}) -> int:
	if _mission_id.is_empty() or observer_id.strip_edges().is_empty() or observer_id.length() > 96: return 0
	if not KINDS.has(kind) or not position.is_finite(): return 0
	if not is_finite(confidence) or confidence < 0 or confidence > 1: return 0
	if not is_finite(ttl_seconds) or ttl_seconds <= 0: return 0
	var expires_at := _time + ttl_seconds
	if not is_finite(expires_at) or expires_at <= _time: return 0
	if sector_id.length() > 96 or not _valid_metadata(metadata): return 0
	if _observations.size() == MAX_OBSERVATIONS:
		# Oldest insertion first, even when a newer observation expires sooner.
		var evicted: Dictionary = _observations.pop_front()
		_emit("security_observation_expired", {"id":evicted.id, "observer_id":evicted.observer_id, "kind":evicted.kind, "reason":"capacity"})
	var observation := {"id":_next_id, "observer_id":observer_id, "kind":kind,
		"position":position, "confidence":confidence, "created_at":_time,
		"expires_at":expires_at, "sector_id":sector_id, "metadata":metadata.duplicate(true)}
	_next_id += 1
	_observations.append(observation)
	var detail := observation.duplicate(true)
	detail.position = [position.x, position.y, position.z]
	_emit("security_observation", detail)
	return int(observation.id)

func get_active_observations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for observation in _observations:
		result.append(observation.duplicate(true))
	return result

func get_observations_for(observer_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for observation in _observations:
		if observation.observer_id == observer_id: result.append(observation.duplicate(true))
	return result

func clear() -> void:
	var had_mission := not _mission_id.is_empty()
	var detail := {"count":_observations.size()}
	_observations.clear()
	if had_mission: _emit("security_director_cleared", detail)
	_mission_id = ""
	_time = 0.0
	_next_id = 1

func _valid_metadata(metadata: Dictionary) -> bool:
	# Flat JSON scalars only: bounded, copyable and incapable of retaining Nodes.
	if metadata.size() > 8: return false
	for key in metadata:
		if not key is String or key.length() > 64: return false
		var value: Variant = metadata[key]
		match typeof(value):
			TYPE_NIL, TYPE_BOOL, TYPE_INT: pass
			TYPE_FLOAT:
				if not is_finite(value): return false
			TYPE_STRING:
				if value.length() > 128: return false
			_: return false
	return true

func _emit(event: String, detail: Dictionary) -> void:
	detail["v"] = 1
	detail["simulation_time"] = _time
	detail["mission_id"] = _mission_id
	telemetry_event.emit(event, detail)
