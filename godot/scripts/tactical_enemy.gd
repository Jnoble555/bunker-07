extends CharacterBody3D
## Armed operation-only actor. All decisions use observations or remembered positions.
const Visual = preload("res://scripts/tactical_enemy_visual.gd")
var controller: Node
var id := "tactical_1"
var role := "smg"
var is_guard := false
var alert_progress := 0.0
var hp := 4
var attack_windup := 0.0
var stagger := 0.0
var state := "patrol"
var magazine := 12
var reload_remaining := 0.0
var last_known := Vector3.INF
var memory_remaining := 0.0
var spawn_position := Vector3.ZERO
var patrol_points: Array[Vector3] = []
var _spec: Dictionary = {}
var _visual: Node3D
var _reaction := 0.0
var _shot_timer := 0.0
var _flash := 0.0
var _burst_left := 0
var _patrol_index := 0
var _share_timer := 0.0
var _cover := Vector3.INF
var _compromised_cover := Vector3.INF
var _reposition := 0.0
var _path: Array[Vector3] = []
var _path_timer := 0.0
var _path_target := Vector3.INF
var _stuck := 0.0
var _previous := Vector3.ZERO
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_PAUSABLE
	collision_layer=4
	collision_mask=1|2|4
	floor_snap_length=.32
	floor_max_angle=deg_to_rad(48)
	var shape:=CollisionShape3D.new()
	var capsule:=CapsuleShape3D.new()
	capsule.height=1.8
	capsule.radius=.32
	shape.shape=capsule
	shape.position.y=.9
	add_child(shape)
	_visual=Visual.new()
	add_child(_visual)
func setup(owner_controller:Node,spawn:Vector3,spec:Dictionary={}) -> void:
	controller=owner_controller
	spawn_position=spawn
	_spec=spec.duplicate(true)
	id=str(spec.get("id","tactical_1"))
	role=str(spec.get("role","smg"))
	patrol_points.assign(spec.get("patrol",[spawn]))
	if not is_node_ready(): await ready
	_visual.configure(role)
	reset_guard()
func reset_guard() -> void:
	global_position=spawn_position
	_previous=spawn_position
	hp=int(_spec.get("hp",5 if role=="rifle" else 4))
	magazine=capacity()
	reload_remaining=0
	attack_windup=0
	stagger=0
	state="patrol"
	last_known=Vector3.INF
	memory_remaining=0
	_reaction=0
	_shot_timer=.5
	_burst_left=0
	_cover=Vector3.INF
	_compromised_cover=Vector3.INF
	_path.clear()
	_path_timer=0
	_stuck=0
	_patrol_index=0
	collision_layer=4
	velocity=Vector3.ZERO
	rotation.y=float(_spec.get("facing",0.0))
	_visual.pose(state,false,0,true)
func capacity() -> int: return 9 if role=="rifle" else 15
func eye() -> Vector3: return global_position+Vector3.UP*1.45
func visible_point(point:Vector3) -> bool:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye(),point,1)).is_empty()
func _player_eye() -> Vector3: return controller.player.camera.global_position
func can_see_player() -> bool:
	var offset:=_player_eye()-eye()
	if offset.length()> (28.0 if role=="rifle" else 21.0): return false
	if state=="patrol" and offset.length()>3 and -global_basis.z.dot(offset.normalized())<.15: return false
	return visible_point(_player_eye())
func hear_shot(at:Vector3,shared:bool=false) -> void:
	if hp<=0 or global_position.distance_to(at)>(12.0 if shared else 19.0): return
	# Sound supplies a location, never continuous access to the hidden player.
	if state!="engage":
		last_known=at
		memory_remaining=7.0
		_transition("suspicious")
func receive_hit(amount:int=1) -> void:
	if hp<=0 or not controller.active or get_tree().paused: return
	hp=maxi(0,hp-amount)
	stagger=.22
	attack_windup=0
	_burst_left=0
	_compromised_cover=global_position
	_cover=Vector3.INF
	controller.register_event("guard_hit",str(hp),id)
	if hp==0:
		collision_layer=0
		velocity=Vector3.ZERO
		_visual.hide()
		controller.register_event("bot_disabled",id,id)
	else:
		hear_shot(_player_eye())
func _transition(next:String) -> void:
	if state==next: return
	state=next
	controller.register_event("enemy_state",state,id)
func _physics_process(delta:float) -> void:
	if not controller or not controller.active or hp<=0: return
	velocity.x=0
	velocity.z=0
	_flash=maxf(0,_flash-delta)
	stagger=maxf(0,stagger-delta)
	_shot_timer=maxf(0,_shot_timer-delta)
	_share_timer=maxf(0,_share_timer-delta)
	_path_timer=maxf(0,_path_timer-delta)
	_reposition=maxf(0,_reposition-delta)
	var seen:=can_see_player()
	if seen:
		last_known=_player_eye()
		memory_remaining=8
		_reaction+=delta
		if _share_timer==0:
			for ally in controller.enemies:
				if ally!=self and ally.has_method("hear_shot") and global_position.distance_to(ally.global_position)<9:
					ally.hear_shot(last_known,true)
			_share_timer=2.0
	else:
		memory_remaining=maxf(0,memory_remaining-delta)
		_reaction=0
		attack_windup=0
		_burst_left=0
	if reload_remaining>0:
		reload_remaining=maxf(0,reload_remaining-delta)
		if reload_remaining==0:
			magazine=capacity()
			_transition("engage" if seen else "search")
	elif stagger==0:
		_decide(delta,seen)
	velocity.y=-.5 if is_on_floor() else maxf(-25,velocity.y-18*delta)
	_step_up(Vector3(velocity.x,0,velocity.z)*delta)
	move_and_slide()
	_visual.pose(state,_flash>0,attack_windup,hp>0)
func _decide(delta:float,seen:bool) -> void:
	if magazine<=0:
		_transition("reload")
		reload_remaining=2.4 if role=="rifle" else 1.9
		attack_windup=0
		controller.play_sound("reload",global_position)
		return
	if seen:
		_transition("engage" if _reaction>=.65 else "suspicious")
		_face(last_known)
		var distance:=global_position.distance_to(last_known)
		if role=="rifle" and (_cover==Vector3.INF or _reposition==0):
			_cover=_choose_cover()
			_reposition=5.0
		var target:=_cover if role=="rifle" and _cover!=Vector3.INF else last_known
		var preferred:=13.0 if role=="rifle" else 7.5
		if (role=="rifle" and _cover!=Vector3.INF and global_position.distance_to(_cover)>.6) or distance>preferred:
			_move_toward(target,delta)
		if _reaction<.65: return
		if _shot_timer==0:
			if _burst_left==0 and attack_windup==0:
				attack_windup=.65 if role=="rifle" else .48
			attack_windup=maxf(0,attack_windup-delta)
			if attack_windup==0:
				if _burst_left==0: _burst_left=2 if role=="rifle" else 3
				_fire()
		return
	if last_known!=Vector3.INF and memory_remaining>0:
		_transition("search" if state!="suspicious" else "suspicious")
		_move_toward(last_known,delta)
		if Vector2(global_position.x,global_position.z).distance_to(Vector2(last_known.x,last_known.z))<1.2:
			_transition("search")
			rotate_y(delta*.8)
		return
	last_known=Vector3.INF
	_cover=Vector3.INF
	_transition("patrol")
	if not patrol_points.is_empty():
		if global_position.distance_to(patrol_points[_patrol_index])<.65: _patrol_index=(_patrol_index+1)%patrol_points.size()
		_move_toward(patrol_points[_patrol_index],delta)
func _fire() -> void:
	# Both eye and physical muzzle must clear world geometry; allies also block fire.
	if not can_see_player(): return
	_face(_player_eye())
	var at:=eye()+(-global_basis.z*.7)
	if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(eye(),at,1)).is_empty(): return
	var target:=_player_eye()
	var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,target,1|4,[get_rid()]))
	if not hit.is_empty():
		_shot_timer=.25
		return
	magazine-=1
	_burst_left-=1
	_flash=.07
	controller.play_sound("smg_fire" if role=="smg" else "rifle_fire",global_position)
	controller.register_event("enemy_shot",role,id)
	# Bursts have a deliberate miss; damage is bounded and reaction remains avoidable.
	if magazine%3!=0: controller.damage_player(5 if role=="smg" else 8,global_position)
	_shot_timer=(.13 if role=="smg" else .22) if _burst_left>0 else (1.05 if role=="smg" else 1.3)
func _face(at:Vector3) -> void:
	var flat:=Vector3(at.x,global_position.y,at.z)
	if global_position.distance_to(flat)>.05: look_at(flat,Vector3.UP)
func _move_toward(target:Vector3,delta:float) -> void:
	if _path_timer==0 or _path_target.distance_to(target)>1:
		_path=controller.room.tactical_path(global_position,target)
		_path_target=target
		_path_timer=.6
	while not _path.is_empty() and global_position.distance_to(_path[0])<.55: _path.pop_front()
	if _path.is_empty(): return
	var direction:=_path[0]-global_position
	direction.y=0
	if direction.length()<.05: return
	direction=direction.normalized()
	var separation:=Vector3.ZERO
	for ally in controller.enemies:
		if ally==self or ally.hp<=0: continue
		var apart:Vector3=global_position-ally.global_position
		apart.y=0
		if apart.length()>.01 and apart.length()<1.0: separation+=apart.normalized()*(1-apart.length())
	direction=(direction+separation*1.8).normalized()
	var speed:=1.65 if role=="rifle" else 2.5
	if state=="patrol": speed*=.55
	velocity.x=direction.x*speed
	velocity.z=direction.z*speed
	_face(global_position+direction)
	if global_position.distance_to(_previous)<.01: _stuck+=delta
	else: _stuck=0
	_previous=global_position
	if _stuck>1.2:
		# Yield sideways to another actor rather than continually push a doorway.
		velocity.x=-direction.z*speed
		velocity.z=direction.x*speed
		_path_timer=0
		if _stuck>2.0: _stuck=0
func _choose_cover() -> Vector3:
	var best:=Vector3.INF
	var score:=INF
	for point in controller.room.cover_points:
		if _compromised_cover!=Vector3.INF and point.distance_to(_compromised_cover)<2.5: continue
		if point.distance_to(last_known)<5 or point.distance_to(last_known)>23: continue
		var occupied:=false
		for ally in controller.enemies:
			if ally!=self and ally.hp>0 and ally.global_position.distance_to(point)<1.2: occupied=true
		if occupied: continue
		var path:Array[Vector3]=controller.room.tactical_path(global_position,point)
		if path.is_empty(): continue
		var value:float=global_position.distance_to(point)
		if not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.8,last_known,1)).is_empty(): value-=5
		if value<score:
			score=value
			best=point
	return best
func _step_up(motion:Vector3) -> void:
	if not is_on_floor() or motion.length()<.0001 or not test_move(global_transform,motion): return
	var raised:=global_transform
	if test_move(raised,Vector3.UP*.26): return
	raised.origin.y+=.26
	if test_move(raised,motion): return
	raised.origin+=motion
	var landing:=KinematicCollision3D.new()
	if test_move(raised,Vector3.DOWN*.3,landing) and landing.get_normal().y>.7: global_position.y+=.26+landing.get_travel().y
