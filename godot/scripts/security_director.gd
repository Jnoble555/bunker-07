extends RefCounted
## Mission-scoped evidence and radio snapshots. No actor/player references.
signal search_assignment_changed(guard_id: String, assignment: Dictionary, reason: String)
signal telemetry_event(event: String, detail: Dictionary)
signal radio_report_changed(report: Dictionary)
signal radio_report_delivered(recipient_id: String, report: Dictionary)

const SECURITY_PARTNERS := {"security-smg": "security-rifle", "security-rifle": "security-smg"}
const SEARCH_ARRIVAL := .65
const MAX_OBSERVATIONS := 128
const KINDS := ["visual_contact", "sound_contact", "visual_lost"]
const RADIO_RANGE := 12.0
const MAX_PENDING_REPORTS := 16
const MAX_RADIO_HISTORY := 64
const MAX_KNOWLEDGE_PER_GUARD := 32
const MAX_RADIO_RECIPIENTS := 2
var _search := {}
var _search_episodes := {}
var _last_search_report := 0
var _mission_id := ""
var _attempt_id := 0
var _generation := 0
var _time := 0.0
var _next_id := 1
var _observations: Array[Dictionary] = []
var _next_report_id := 1
var _pending_reports: Array[Dictionary] = []
var _radio_history: Array[Dictionary] = []
var _radio_knowledge: Dictionary = {}
var _radio_actors: Dictionary = {}
var _delivered_keys: Dictionary = {}

func initialize_for_mission(mission_id: String, attempt_id: int = 0) -> void:
	clear()
	if mission_id.strip_edges().is_empty() or mission_id.length() > 96: return
	_mission_id = mission_id
	_generation += 1
	_attempt_id = attempt_id if attempt_id > 0 else _generation
	_emit("security_director_initialized", {})

func get_simulation_time() -> float:
	return _time

func get_mission_id() -> String:
	return _mission_id

func get_attempt_id() -> int:
	return _attempt_id

func advance(delta: float) -> void:
	if _mission_id.is_empty() or not is_finite(delta) or delta <= 0 or not is_finite(_time + delta): return
	_time += delta
	# Bounded scan; allocate no full-history copy on physics updates.
	var index := 0
	while index < _observations.size():
		if _observations[index].expires_at <= _time:
			var observation := _observations[index]
			_observations.remove_at(index)
			_forget_delivery_key(int(observation.id))
			_emit("security_observation_expired", {"id":observation.id, "observer_id":observation.observer_id, "kind":observation.kind, "reason":"ttl"})
		else:
			index += 1
	_expire_radio_knowledge()
	_advance_search()
	_advance_radio_reports()

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
		_forget_delivery_key(int(evicted.id))
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
	_finish_search("mission_end")
	_search_episodes.clear()
	_last_search_report = 0
	var had_mission := not _mission_id.is_empty()
	var detail := {"count":_observations.size()}
	_observations.clear()
	while not _pending_reports.is_empty():
		cancel_radio_report(int(_pending_reports[0].id), "mission_end")
	_radio_history.clear()
	_radio_knowledge.clear()
	_radio_actors.clear()
	_delivered_keys.clear()
	_next_report_id = 1
	if had_mission: _emit("security_director_cleared", detail)
	_attempt_id = 0
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
	detail["attempt_id"] = _attempt_id
	telemetry_event.emit(event, detail)

## Controller supplies small value-only actor snapshots before advancing/delivery.
func sync_radio_actors(actors: Dictionary) -> void:
	_radio_actors.clear()
	if _mission_id.is_empty(): return
	# Bound even malformed/test callers; production supplies only the SECURITY pair.
	var ids: Array = actors.keys()
	ids = ids.filter(func(value): return value is String)
	ids.sort()
	for actor_id: String in ids.slice(0, 64):
		var actor: Variant = actors[actor_id]
		if actor_id.is_empty() or actor_id.length() > 96 or not actor is Dictionary: continue
		var position: Variant = actor.get("position")
		if not position is Vector3 or not position.is_finite(): continue
		_radio_actors[actor_id] = {"position":position, "alive":actor.get("alive",false)==true,
			"interrupted":actor.get("interrupted",false)==true}
	for report in _pending_reports.duplicate():
		if not _radio_alive(str(report.sender_id)):
			cancel_radio_report(int(report.id),"sender_unavailable")
		elif _radio_actors[report.sender_id].interrupted:
			cancel_radio_report(int(report.id),"hit_stagger")
	# Removed/dead guards do not accumulate historical recipient state.
	for actor_id: String in _radio_knowledge.keys():
		if not _radio_alive(actor_id): _radio_knowledge.erase(actor_id)
	for actor_id: String in _delivered_keys.keys():
		if not _radio_alive(actor_id): _delivered_keys.erase(actor_id)

func queue_radio_report(sender_id: String, observation_id: int, recipient_ids: Array, delay_seconds: float) -> int:
	if _mission_id.is_empty() or not _radio_alive(sender_id) or _radio_actors[sender_id].interrupted: return 0
	if not is_finite(delay_seconds) or delay_seconds <= 0: return 0
	if recipient_ids.size() > 64: return 0
	var completion := _time + delay_seconds
	if not is_finite(completion) or completion <= _time or _pending_reports.size() >= MAX_PENDING_REPORTS: return 0
	for pending in _pending_reports:
		if pending.sender_id == sender_id: return 0
	var observation: Dictionary = {}
	for candidate in _observations:
		if candidate.id == observation_id:
			observation = candidate
			break
	if observation.is_empty() or observation.observer_id != sender_id or observation.kind != "visual_contact": return 0
	if observation.expires_at <= completion: return 0
	var recipients: Array[String] = []
	for recipient_id in recipient_ids:
		if not recipient_id is String: continue
		if _radio_partner(sender_id,recipient_id) and not recipients.has(recipient_id) and not _already_delivered(recipient_id,observation_id):
			recipients.append(recipient_id)
	recipients.sort()
	if recipients.is_empty(): return 0
	recipients.resize(mini(recipients.size(),MAX_RADIO_RECIPIENTS))
	var report := {"id":_next_report_id,"observation_id":observation_id,
		"observer_id":str(observation.observer_id),"sender_id":sender_id,
		"recipient_ids":recipients,"position":observation.position,
		"observed_at":observation.created_at,"confidence":observation.confidence,
		"expires_at":observation.expires_at,"submitted_at":_time,"completes_at":completion,
		"sight_episode":observation.metadata.get("sight_episode", 0),
		"status":"pending","cancellation_reason":"","attempt_id":_attempt_id,"mission_id":_mission_id}
	_next_report_id += 1
	_pending_reports.append(report)
	_radio_event("security_radio_started",report)
	radio_report_changed.emit(report.duplicate(true))
	return int(report.id)

func cancel_radio_report(report_id: int, reason: String) -> bool:
	if reason.is_empty() or reason.length() > 64: return false
	for index in _pending_reports.size():
		if _pending_reports[index].id != report_id: continue
		var report := _pending_reports[index]
		_pending_reports.remove_at(index)
		report.status = "cancelled"
		report.cancellation_reason = reason
		_finish_radio(report)
		return true
	return false

func cancel_reports_from(sender_id: String, reason: String) -> void:
	for report in _pending_reports.duplicate():
		if report.sender_id == sender_id: cancel_radio_report(int(report.id),reason)

func get_pending_radio_reports() -> Array[Dictionary]:
	return _pending_reports.duplicate(true)

func get_radio_history() -> Array[Dictionary]:
	return _radio_history.duplicate(true)

func get_radio_report(report_id: int) -> Dictionary:
	for collection in [_pending_reports,_radio_history]:
		for report: Dictionary in collection:
			if report.id == report_id: return report.duplicate(true)
	return {}

func get_delivered_knowledge_for(recipient_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for report: Dictionary in _radio_knowledge.get(recipient_id,[]):
		if report.expires_at > _time: result.append(report.duplicate(true))
	return result

func _radio_alive(actor_id: String) -> bool:
	return _radio_actors.has(actor_id) and bool(_radio_actors[actor_id].alive)

func _radio_partner(sender_id: String, recipient_id: String) -> bool:
	return sender_id != recipient_id and _radio_alive(sender_id) and _radio_alive(recipient_id) and _radio_actors[sender_id].position.distance_to(_radio_actors[recipient_id].position) <= RADIO_RANGE

func _already_delivered(recipient_id: String, observation_id: int) -> bool:
	return _delivered_keys.has(recipient_id) and _delivered_keys[recipient_id].has(observation_id)

func _forget_delivery_key(observation_id: int) -> void:
	# Only live source observations are queueable: dedup remains <=128 IDs/actor.
	for actor_id: String in _delivered_keys.keys():
		_delivered_keys[actor_id].erase(observation_id)
		if _delivered_keys[actor_id].is_empty(): _delivered_keys.erase(actor_id)

func _expire_radio_knowledge() -> void:
	for actor_id: String in _radio_knowledge.keys():
		var records: Array = _radio_knowledge[actor_id]
		for index in range(records.size()-1,-1,-1):
			if records[index].expires_at <= _time: records.remove_at(index)
		if records.is_empty(): _radio_knowledge.erase(actor_id)

func _advance_radio_reports() -> void:
	# Insertion/report-ID order is deterministic, including simultaneous deadlines.
	for report in _pending_reports.duplicate():
		# An earlier completion callback may cancel another entry in this snapshot.
		if report.status!="pending" or not _pending_reports.has(report): continue
		var report_id := int(report.id)
		if report.attempt_id != _attempt_id or report.mission_id != _mission_id:
			cancel_radio_report(report_id,"attempt_changed")
		elif not _radio_alive(str(report.sender_id)):
			cancel_radio_report(report_id,"sender_unavailable")
		elif _radio_actors[report.sender_id].interrupted:
			cancel_radio_report(report_id,"hit_stagger")
		elif report.expires_at <= _time:
			cancel_radio_report(report_id,"evidence_expired")
		elif report.completes_at <= _time:
			var recipients: Array[String] = []
			for recipient_id: String in report.recipient_ids:
				if _radio_partner(str(report.sender_id),recipient_id) and not _already_delivered(recipient_id,int(report.observation_id)):
					recipients.append(recipient_id)
			if recipients.is_empty():
				cancel_radio_report(report_id,"no_recipients")
				continue
			_pending_reports.erase(report)
			report.status = "delivered"
			report["delivered_recipient_ids"] = recipients
			_finish_radio(report)
			for recipient_id: String in recipients:
				if report.attempt_id != _attempt_id or report.mission_id != _mission_id: break
				if not _radio_knowledge.has(recipient_id): _radio_knowledge[recipient_id]=[]
				var records: Array = _radio_knowledge[recipient_id]
				if records.size() == MAX_KNOWLEDGE_PER_GUARD: records.pop_front()
				records.append(report.duplicate(true))
				# Evicted source IDs cannot be queued again; never retain orphan dedup keys.
				for source in _observations:
					if source.id == report.observation_id:
						if not _delivered_keys.has(recipient_id): _delivered_keys[recipient_id]={}
						_delivered_keys[recipient_id][report.observation_id]=true
						break
				radio_report_delivered.emit(recipient_id,report.duplicate(true))

func _finish_radio(report: Dictionary) -> void:
	if _radio_history.size() == MAX_RADIO_HISTORY: _radio_history.pop_front()
	_radio_history.append(report.duplicate(true))
	_radio_event("security_radio_"+str(report.status),report)
	radio_report_changed.emit(report.duplicate(true))

func _radio_event(event: String, report: Dictionary) -> void:
	var detail := report.duplicate(true)
	var at: Vector3 = detail.position
	detail.position = [at.x,at.y,at.z]
	_emit(event,detail)

## Returns a detached snapshot of the only active incident and its reservations.
func get_search_incident() -> Dictionary:
	return _search.duplicate(true)

## Use the retained delivered record, never the caller's copy of the evidence.
func consider_search(report_id: int, recipient_id: String, attempt_id: int, plan: Callable) -> void:
	if attempt_id != _attempt_id or attempt_id <= 0 or report_id <= _last_search_report: return
	if not plan.is_valid() or not SECURITY_PARTNERS.has(recipient_id): return
	var report: Dictionary = {}
	for delivered: Dictionary in _radio_knowledge.get(recipient_id, []):
		if delivered.id == report_id:
			report = delivered
			break
	if report.is_empty() or report.expires_at <= _time: return
	if SECURITY_PARTNERS[recipient_id] != report.sender_id: return
	_last_search_report = report_id
	var episode: Variant = report.sight_episode
	if episode is int and episode > 0:
		if episode <= int(_search_episodes.get(report.sender_id, 0)): return
		_search_episodes[report.sender_id] = episode
	if not _search.is_empty():
		var old: Dictionary = _search.evidence
		if report.observed_at <= old.observed_at or report.position.distance_to(old.position) < 3.0: return
	# The callback is synchronous and is never retained. Its input is evidence and IDs.
	var rng := RandomNumberGenerator.new()
	rng.seed = attempt_id * 1000003 + int(report.observation_id) * 97 + report_id
	var deadline: float = minf(report.expires_at, _time + 6.5)
	var assignments: Dictionary = plan.call(report.duplicate(true), recipient_id, rng, deadline - _time)
	if assignments.is_empty(): return
	_finish_search("superseded")
	_search = {"id": report_id, "attempt_id": attempt_id, "evidence": report,
		"state": "active", "deadline": deadline, "assignments": assignments.duplicate(true)}
	_emit_search("started", {}, "paired" if assignments.size() == 2 else "solo")
	for guard_id: String in _search.assignments:
		var assignment: Dictionary = _search.assignments[guard_id]
		assignment.merge({"incident_id": report_id, "attempt_id": attempt_id, "guard_id": guard_id,
			"evidence_position": report.position, "observed_at": report.observed_at,
			"assigned_at": _time, "deadline": deadline, "state": "moving", "arrived_at": -1.0})
		_emit_search("assigned", assignment)
		search_assignment_changed.emit(guard_id, assignment.duplicate(true), "")

func mark_search_arrival(guard_id: String, incident_id: int, attempt_id: int, at: Vector3) -> void:
	if _search.is_empty() or _search.id != incident_id or attempt_id != _attempt_id: return
	var assignment: Dictionary = _search.assignments.get(guard_id, {})
	if assignment.is_empty() or assignment.state != "moving" or not at.is_finite(): return
	if at.distance_to(assignment.destination) > SEARCH_ARRIVAL: return
	assignment.state = "arrived"
	assignment.arrived_at = _time
	_emit_search("arrived", assignment)

func interrupt_search(guard_id: String, reason: String) -> void:
	if _search.is_empty() or not _search.assignments.has(guard_id): return
	var assignment: Dictionary = _search.assignments[guard_id]
	if assignment.role == "investigator":
		_finish_search(reason)
	else:
		_release_search_guard(guard_id, reason)

func _advance_search() -> void:
	if _search.is_empty(): return
	if _search.deadline <= _time:
		_finish_search("evidence_expired" if _search.evidence.expires_at <= _time else "search_timeout")
		return
	for guard_id: String in _search.assignments.keys():
		if not _radio_alive(guard_id):
			interrupt_search(guard_id, "guard_unavailable")
			if _search.is_empty(): return
	for assignment: Dictionary in _search.assignments.values():
		if assignment.role == "investigator" and assignment.state == "arrived" and _time >= assignment.arrived_at + 1.2:
			_finish_search("area_checked")
			return

func _finish_search(reason: String) -> void:
	if _search.is_empty(): return
	var completed := reason in ["area_checked", "search_timeout", "evidence_expired"]
	_search.state = "completed" if completed else "cancelled"
	_emit_search(_search.state, {}, reason)
	for guard_id: String in _search.assignments.keys():
		_release_search_guard(guard_id, reason)
	_search.clear()

func _release_search_guard(guard_id: String, reason: String) -> void:
	var assignment: Dictionary = _search.assignments[guard_id]
	_search.assignments.erase(guard_id)
	assignment.state = "released"
	_emit_search("released", assignment, reason)
	search_assignment_changed.emit(guard_id, assignment.duplicate(true), reason)

func _emit_search(event: String, assignment: Dictionary, reason: String = "") -> void:
	var evidence: Dictionary = _search.evidence
	var position: Vector3 = evidence.position
	var detail := {"incident_id": _search.id, "source_report_id": evidence.id,
		"source_observation_id": evidence.observation_id, "observer_id": evidence.observer_id,
		"position": [position.x, position.y, position.z], "observed_at": evidence.observed_at,
		"expires_at": evidence.expires_at, "deadline": _search.deadline, "state": _search.state, "reason": reason}
	if not assignment.is_empty():
		var destination: Vector3 = assignment.destination
		detail.merge({"guard_id": assignment.guard_id, "role": assignment.role,
			"destination": [destination.x, destination.y, destination.z], "state": assignment.state}, true)
	_emit("security_search_" + event, detail)
