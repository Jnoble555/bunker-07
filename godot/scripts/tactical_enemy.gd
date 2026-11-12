extends CharacterBody3D
## Independent operation-only AI. Memory is updated solely by sight, sound or ally contact.
const Visual = preload("res://scripts/tactical_enemy_visual.gd")
var controller: Node
var hp := 3
var id := "tactical"
var role := "tactical_smg"
var is_guard := false
var attack_windup := 0.0
var alert_progress := 0.0
var stagger := 0.0
var state := "patrol"
var last_known_position := Vector3.INF
var magazine := 8
var reserve := 48
var reload_remaining := 0.0
var shots_fired := 0
var moving := false
var spawn_position := Vector3.ZERO
var patrol: Array[Vector3] = []
var _patrol_index := 0
var _max_hp := 3
var _mag_capacity := 8
var _reload_duration := 1.9
var _reaction := 0.45
var _range := 23.0
var _preferred := 7.0
var _speed := 2.5
var _damage := 4
var _shot_interval := 0.13
var _burst_size := 3
var _shot_clock := 0.0
var _burst_left := 0
var _flash := 0.0
var _state_clock := 0.0
var _last_seen_age := 1000.0
var _share_clock := 0.0
var _decision_clock := 0.0
var _search_clock := 0.0
var _path: PackedVector3Array = []
var _path_index := 0
var _path_clock := 0.0
var _goal := Vector3.INF
var _cover := Vector3.INF
var _peek := Vector3.INF
var _cover_holding := 0.0
var _at_peek := false
var _blocked_clock := 0.0
var _yield_clock := 0.0
var _yield_goal := Vector3.INF
var _step_grace := 0.0
var _visual: Node3D
var _collision: CollisionShape3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 4
	collision_mask = 1|2|4
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(48)
	safe_margin = 0.002
	_collision = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.8
	_collision.shape = capsule
	_collision.position.y = 0.9
	add_child(_collision)

func setup(main: Node, spawn: Vector3, spec: Dictionary = {}) -> void:
	controller = main
	spawn_position = spawn
	id = str(spec.get("id","tactical"))
	role = str(spec.get("role","tactical_smg"))
	_max_hp = int(spec.get("hp",4 if role == "tactical_rifle" else 3))
	if role == "tactical_rifle":
		_mag_capacity = 6
		_reload_duration = 2.4
		_reaction = 0.65
		_range = 32.0
		_preferred = 14.0
		_speed = 1.65
		_damage = 7
		_shot_interval = 0.26
		_burst_size = 2
	patrol.clear()
	for point in spec.get("patrol",[spawn]): patrol.append(point)
	if patrol.is_empty(): patrol.append(spawn)
	if not is_node_ready(): await ready
	if is_instance_valid(_visual): _visual.queue_free()
	_visual = Visual.new()
	add_child(_visual)
	_visual.build(role)
	reset_guard()

func reset_guard() -> void:
	global_position = spawn_position
	hp = _max_hp
	magazine = _mag_capacity
	reserve = 30 if role == "tactical_rifle" else 48
	reload_remaining = 0
	attack_windup = 0
	alert_progress = 0
	stagger = 0
	shots_fired = 0
	velocity = Vector3.ZERO
	last_known_position = Vector3.INF
	_last_seen_age = 1000
	_burst_left = 0
	_shot_clock = 0
	_state_clock = 0
	_flash = 0
	_share_clock = 0
	_decision_clock = 0
	_search_clock = 0
	_path_clock = 0
	_blocked_clock = 0
	_yield_clock = 0
	_yield_goal = Vector3.INF
	_step_grace = 0
	_at_peek = false
	_cover_holding = 0
	_path.clear()
	_goal = Vector3.INF
	_cover = Vector3.INF
	_peek = Vector3.INF
	_patrol_index = 0
	collision_layer = 4
	if _collision: _collision.set_deferred("disabled",false)
	if _visual: _visual.show()
	_set_state("patrol")

func receive_hit(damage_amount: int = 1) -> void:
	if hp <= 0 or damage_amount <= 0 or not _playing(): return
	hp = maxi(0,hp-maxi(0,damage_amount))
	stagger = 0.22
	attack_windup = 0
	_burst_left = 0
	_cover = Vector3.INF
	_decision_clock = 0
	_event("tactical_hit",str(damage_amount))
	if hp == 0:
		collision_layer = 0
		_collision.set_deferred("disabled",true)
		_visual.hide()
		velocity = Vector3.ZERO
		_event("bot_disabled","")
	else:
		# A hit is evidence of a threat, not permission to read its hidden location.
		if last_known_position != Vector3.INF: _set_state("search")

func on_noise(at: Vector3) -> void:
	if hp <= 0 or not _playing() or global_position.distance_to(at) > 20.0: return
	if state in ["engage","reload"] and _last_seen_age < 1.0: return
	var new_contact := last_known_position == Vector3.INF or last_known_position.distance_to(at)>1.0
	last_known_position = at
	_search_clock = 6.0
	if state not in ["reload","search","suspicious","withdraw"]: _set_state("suspicious")
	if new_contact: _event("tactical_noise","investigate")

func receive_contact(at: Vector3) -> void:
	if hp <= 0 or not _playing() or (state == "engage" and _last_seen_age < 1.0): return
	last_known_position = at
	_search_clock = 5.0
	if state not in ["reload","search","suspicious","withdraw"]: _set_state("suspicious")

func _physics_process(delta: float) -> void:
	if hp <= 0 or not _playing(): return
	_state_clock += delta
	_last_seen_age += delta
	_share_clock = maxf(0,_share_clock-delta)
	_decision_clock = maxf(0,_decision_clock-delta)
	_path_clock = maxf(0,_path_clock-delta)
	_shot_clock = maxf(0,_shot_clock-delta)
	_flash = maxf(0,_flash-delta)
	stagger = maxf(0,stagger-delta)
	velocity.x = 0
	velocity.z = 0
	var visible := _can_see_player()
	if visible:
		last_known_position = controller.player.global_position
		_last_seen_age = 0
		alert_progress = minf(_reaction,alert_progress+delta)
		if state not in ["reload","withdraw"] and alert_progress >= _reaction and state != "engage":
			_set_state("engage")
			_decision_clock = 0
		_share_contact()
	else:
		alert_progress = maxf(0,alert_progress-delta*0.7)
	if state == "reload":
		attack_windup = 0
		reload_remaining = maxf(0,reload_remaining-delta)
		if reload_remaining == 0:
			var loaded := mini(_mag_capacity,reserve)
			magazine = loaded
			reserve -= loaded
			_shot_clock = 0.35
			_set_state("engage" if visible else "search")
			_search_clock = 5
	elif stagger <= 0:
		match state:
			"patrol": _patrol(delta)
			"suspicious":
				_face(last_known_position,delta)
				if _state_clock >= 0.65: _set_state("search")
			"search": _search(delta)
			"engage": _engage(visible,delta)
			"withdraw": _move_to(spawn_position,_speed*0.75,delta)
	else:
		attack_windup = 0
		_burst_left = 0
	_step_grace = maxf(0,_step_grace-delta)
	floor_snap_length = 0.0 if _step_grace>0 else 0.3
	velocity.y = -0.5 if is_on_floor() or _step_grace>0 else maxf(-30,velocity.y-18*delta)
	_step_up(Vector3(velocity.x,0,velocity.z)*delta)
	var before := global_position
	var intended_speed := Vector2(velocity.x,velocity.z).length()
	move_and_slide()
	moving = Vector2(global_position.x-before.x,global_position.z-before.z).length() > 0.001
	if intended_speed > 0.1 and not moving: _blocked_clock += delta
	else: _blocked_clock = maxf(0,_blocked_clock-delta)
	_visual.animate(delta,moving,state,attack_windup>0,_flash,1.0-reload_remaining/_reload_duration)

func _patrol(delta: float) -> void:
	var destination := patrol[_patrol_index]
	if _horizontal(global_position,destination) < 0.45 and absf(global_position.y-destination.y)<0.5:
		if _state_clock > 1.0:
			_patrol_index = (_patrol_index+1)%patrol.size()
			_state_clock = 0
		return
	_move_to(destination,0.9,delta)

func _search(delta: float) -> void:
	attack_windup = 0
	_burst_left = 0
	if last_known_position == Vector3.INF:
		_set_state("patrol")
		return
	if _horizontal(global_position,last_known_position)>0.65:
		_move_to(last_known_position,_speed*0.75,delta)
		if _path.is_empty() or _state_clock>14: _search_clock -= delta
	else:
		_search_clock -= delta
		rotation.y += sin(_state_clock*1.4)*delta*0.7
	if _search_clock <= 0:
		last_known_position = Vector3.INF
		_cover = Vector3.INF
		_goal = Vector3.INF
		_set_state("patrol")

func _engage(visible: bool, delta: float) -> void:
	if _last_seen_age > (6.0 if _cover != Vector3.INF else 3.5):
		_search_clock = 6.0
		attack_windup = 0
		_burst_left = 0
		_cover = Vector3.INF
		_set_state("search")
		return
	_face(last_known_position,delta)
	if magazine <= 0:
		_start_reload()
		return
	var distance := _horizontal(global_position,last_known_position)
	if _decision_clock == 0:
		_decision_clock = 3.5 if role == "tactical_smg" else 4.5
		if role == "tactical_rifle" or distance < 3.0 or hp < _max_hp:
			var selected := choose_cover(last_known_position)
			if selected != Vector3.INF:
				_cover = selected
				_peek = Vector3.INF
				_cover_holding = 0
				_at_peek = false
	if _cover != Vector3.INF:
		var destination := _peek if _at_peek else _cover
		if _horizontal(global_position,destination)>0.4:
			_move_to(destination,_speed,delta)
		else:
			_cover_holding += delta
			if not _at_peek and _cover_holding > 0.5:
				_peek = _peek_from(_cover,last_known_position)
				if _peek != Vector3.INF: _at_peek = true
				else: _cover = Vector3.INF
	elif distance > _preferred+2.0 or distance < 3.0:
		var away := global_position-last_known_position
		away.y = 0
		if away.length()>0.01:
			var desired := last_known_position+away.normalized()*_preferred
			_move_to(desired,_speed,delta)
	if not visible:
		attack_windup = 0
		_burst_left = 0
		return
	if _burst_left > 0:
		if _shot_clock == 0:
			_fire_round()
			_burst_left -= 1
			_shot_clock = _shot_interval if _burst_left>0 else 1.2
			if _burst_left == 0 and _cover != Vector3.INF:
				_at_peek = false
				_cover_holding = 0
	elif attack_windup > 0:
		attack_windup = maxf(0,attack_windup-delta)
		if attack_windup == 0:
			_burst_left = mini(_burst_size,magazine)
	elif _shot_clock == 0 and global_position.distance_to(controller.player.global_position) < _range:
		attack_windup = 0.6 if role == "tactical_rifle" else 0.45
		_event("attack_windup","")
		_sound("attack")

func _start_reload() -> void:
	attack_windup = 0
	_burst_left = 0
	if reserve <= 0:
		_set_state("withdraw")
		return
	reload_remaining = _reload_duration
	_set_state("reload")
	_event("tactical_reload",str(magazine))
	_sound("reload")

func _fire_round() -> bool:
	# Recheck actual world occlusion and friendly bodies at the instant each round fires.
	if hp<=0 or not _playing() or magazine<=0 or not _can_see_player(): return false
	var origin := global_position+Vector3(0,1.4,0)
	var target: Vector3 = controller.player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin,target,1|2|4,[get_rid()])
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider != controller.player:
		return false
	magazine -= 1
	shots_fired += 1
	_flash = 0.07
	_sound("fire" if role == "tactical_rifle" else "smg_fire")
	_event("tactical_shot",role)
	if not hit.is_empty() and hit.collider == controller.player:
		controller.damage_player(_damage,global_position)
	return true

func _can_see_player() -> bool:
	if not controller or not is_instance_valid(controller.player): return false
	var origin := global_position+Vector3(0,1.4,0)
	var target: Vector3 = controller.player.camera.global_position
	var offset := target-origin
	if offset.length() > _range or offset.length()<0.001: return false
	var cone := -0.2 if state in ["engage","reload","search"] else 0.35
	var flat := Vector3(offset.x,0,offset.z).normalized()
	if (-global_basis.z).dot(flat) < cone: return false
	return bool(controller.has_los(origin,target))

func choose_cover(threat: Vector3) -> Vector3:
	if not controller.room or not controller.room.get("cover_points") is Array: return Vector3.INF
	var best := Vector3.INF
	var best_score := -INF
	for point: Vector3 in controller.room.cover_points:
		var travel := global_position.distance_to(point)
		if travel<0.8 or travel>10 or _path_to(point).is_empty(): continue
		if bool(controller.has_los(point+Vector3(0,1.4,0),threat+Vector3(0,1.4,0))): continue
		var separation := _horizontal(point,threat)
		if separation < 3.0: continue
		var score := 20.0-absf(separation-_preferred)-travel*0.5
		if score>best_score:
			best_score=score
			best=point
	return best

func _peek_from(anchor: Vector3, threat: Vector3) -> Vector3:
	var direction := threat-anchor
	direction.y = 0
	if direction.length()<0.01: return Vector3.INF
	var side := Vector3(-direction.z,0,direction.x).normalized()
	for sign_value in [1,-1]:
		var candidate := anchor+side*float(sign_value)*1.0
		if _path_to(candidate).is_empty(): continue
		if bool(controller.has_los(candidate+Vector3(0,1.4,0),threat+Vector3(0,1.4,0))): return candidate
	return Vector3.INF

func _share_contact() -> void:
	if _share_clock > 0: return
	_share_clock = 2.5
	for ally in controller.enemies:
		if ally == self or not is_instance_valid(ally) or ally.hp<=0 or not ally.has_method("receive_contact"): continue
		if global_position.distance_to(ally.global_position)<=11 and bool(controller.has_los(global_position+Vector3(0,1.4,0),ally.global_position+Vector3(0,1.4,0))):
			ally.receive_contact(last_known_position)

func _move_to(destination: Vector3, speed: float, delta: float) -> void:
	if destination == Vector3.INF: return
	_yield_clock = maxf(0,_yield_clock-delta)
	if _blocked_clock > 0.8 and _yield_clock == 0:
		var forward := destination-global_position
		forward.y = 0
		if forward.length()>0.01:
			var side := Vector3(-forward.z,0,forward.x).normalized()
			for sign_value in [1,-1]:
				var candidate := global_position+side*float(sign_value)*1.0-forward.normalized()*0.3
				if not _path_to(candidate).is_empty():
					_yield_goal = candidate
					_yield_clock = 0.8+float(abs(id.hash())%5)*0.1
					break
		_blocked_clock = 0
	var actual_goal := _yield_goal if _yield_clock>0 else destination
	if _goal == Vector3.INF or _goal.distance_to(actual_goal)>0.6 or _path_clock==0:
		_path = _path_to(actual_goal)
		_path_index = 0
		_goal = actual_goal
		_path_clock = 0.65
	if _path.is_empty(): return
	while _path_index<_path.size() and _horizontal(global_position,_path[_path_index])<0.35 and absf(global_position.y-_path[_path_index].y)<0.5:
		_path_index += 1
	if _path_index>=_path.size(): return
	var direction := _path[_path_index]-global_position
	direction.y = 0
	if direction.length()<0.001: return
	direction = direction.normalized()
	var avoid := Vector3.ZERO
	for ally in controller.enemies:
		if ally == self or not is_instance_valid(ally) or ally.hp<=0: continue
		var offset: Vector3 = global_position-ally.global_position
		offset.y=0
		if offset.length()>0.01 and offset.length()<1.15: avoid += offset.normalized()*(1.15-offset.length())
	direction = (direction+avoid*1.6).normalized()
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	if state != "engage": _face(global_position+direction,delta)

func _path_to(destination: Vector3) -> PackedVector3Array:
	if not controller.room or not controller.room.has_method("find_path"): return PackedVector3Array()
	return controller.room.find_path(global_position,destination)

func _face(point: Vector3, delta: float) -> void:
	if point == Vector3.INF: return
	var offset := point-global_position
	if Vector2(offset.x,offset.z).length()<0.01: return
	rotation.y = lerp_angle(rotation.y,atan2(-offset.x,-offset.z),minf(1,delta*7))

func _step_up(motion: Vector3) -> void:
	if (not is_on_floor() and _step_grace<=0) or motion.length()<0.0001 or not test_move(global_transform,motion): return
	var raised := global_transform
	if test_move(raised,Vector3.UP*0.26): return
	raised.origin.y += 0.26
	# Slow actors move only ~3 cm/tick. Probe onto the tread, not the capsule's
	# steep riser-corner contact, while still sweeping full head/body clearance.
	var tread_probe := motion.normalized()*maxf(0.22,motion.length())
	if test_move(raised,tread_probe): return
	raised.origin += tread_probe
	var landing := KinematicCollision3D.new()
	if test_move(raised,Vector3.DOWN*0.3,landing) and landing.get_normal().y>0.7:
		var rise := 0.26+landing.get_travel().y
		if rise <= 0.01: return
		global_position.y += rise
		_step_grace = 0.12
		floor_snap_length = 0
		velocity.y = 0

func _set_state(next_state: String) -> void:
	if state == next_state: return
	state = next_state
	_state_clock = 0
	if next_state == "search": _search_clock = maxf(_search_clock,5.0)
	_event("tactical_state",state)

func _playing() -> bool:
	return controller != null and bool(controller.active) and not get_tree().paused

func _event(kind: String, detail: String) -> void:
	if controller and controller.has_method("register_event"):
		controller.register_event(kind,id if detail=="" else id+"|"+detail)

func _sound(kind: String) -> void:
	if controller and controller.has_method("play_sound"): controller.play_sound(kind,global_position)

static func _horizontal(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()
