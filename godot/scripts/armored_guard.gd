extends CharacterBody3D
## Representative armored guard; partial-port scope excludes investigation and reinforcements.
## Distances convert the browser's tiles to meters at exactly 2 meters/tile.

class GuardHitTarget extends Area3D:
	var guard: Node

	func receive_hit() -> void:
		if is_instance_valid(guard):
			guard.call("receive_hit")

const MAX_HP: int = 3
const PATROL_SPEED: float = 0.84
const CHASE_SPEED: float = 1.16
const ATTACK_RANGE: float = 2.3
const ATTACK_WINDUP: float = 0.75
const DETECT_DURATION: float = 1.15
const STAGGER_DURATION: float = 0.12
const PATROL_POINTS: Array[Vector3] = [Vector3(7.0, 0.0, 11.0), Vector3(12.2, 0.0, 11.0)]

var controller: Node
var spawn_position := Vector3(9.0, 0.0, 11.0)
var hp: int = MAX_HP
var attack_windup: float = 0.0
var attack_cooldown: float = 0.8
var stagger: float = 0.0
var facing: float = PI
var alert_progress: float = 0.0
var moving: bool = false
var _patrol_target: int = 0
var _phase: float = 0.0
var _visual: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: MeshInstance3D
var _right_leg: MeshInstance3D
var _visor: StandardMaterial3D
var _collider: CollisionShape3D
var _hit_area: GuardHitTarget


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.15
	_build_model()


func setup(owner_controller: Node, spawn: Vector3) -> void:
	controller = owner_controller
	spawn_position = spawn
	if not is_node_ready():
		await ready
	reset_guard()


func reset_guard() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	hp = MAX_HP
	attack_windup = 0.0
	attack_cooldown = 0.8
	stagger = 0.0
	facing = PI
	alert_progress = 0.0
	moving = false
	_patrol_target = 0
	_phase = 0.0
	collision_layer = 4
	if _hit_area != null:
		_hit_area.collision_layer = 4
	if _visual != null:
		_visual.visible = true
		_update_pose(0.0)


func receive_hit() -> void:
	if hp <= 0 or controller == null or not bool(controller.get("active")) or get_tree().paused:
		return
	hp -= 1
	stagger = STAGGER_DURATION
	attack_windup = 0.0
	controller.call("register_event", "guard_hit", str(hp))
	if hp <= 0:
		moving = false
		velocity = Vector3.ZERO
		alert_progress = 0.0
		# Browser bots stop being hittable immediately when disabled.
		collision_layer = 0
		_hit_area.collision_layer = 0
		_visual.visible = false
		controller.call("register_event", "bot_disabled", "guard_1")
	else:
		_update_pose(0.0)


func _physics_process(delta: float) -> void:
	if controller == null or not bool(controller.get("active")) or hp <= 0:
		return
	var target_player := controller.get("player") as Node3D
	if target_player == null:
		return
	moving = false
	velocity.x = 0.0
	velocity.z = 0.0
	var alarm := bool(controller.get("alarm_triggered"))
	# Patrol precedes combat in the browser. Stagger holds the patrol for its duration.
	if not alarm and stagger <= 0.0:
		var patrol_point: Vector3 = PATROL_POINTS[_patrol_target]
		if _horizontal_distance(global_position, patrol_point) < 0.24:
			_patrol_target = 1 - _patrol_target
			patrol_point = PATROL_POINTS[_patrol_target]
		_set_motion_toward(patrol_point, PATROL_SPEED, delta)
	stagger = maxf(0.0, stagger - delta)
	if stagger > 0.0:
		attack_windup = 0.0
	else:
		_update_combat(target_player, alarm, delta)
	# One slide call/tick keeps movement/collision and gravity in the physics clock.
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	var before := global_position
	move_and_slide()
	moving = _horizontal_distance(before, global_position) > 0.0001
	_update_detection(target_player, delta)
	_update_pose(delta)


func _update_combat(target_player: Node3D, alarm: bool, delta: float) -> void:
	var separation: float = _horizontal_distance(global_position, target_player.global_position)
	var visible: bool = separation > 0.0 and separation <= 14.0 and _can_see(target_player)
	if attack_windup > 0.0:
		if not visible or separation >= ATTACK_RANGE:
			attack_windup = 0.0
			return
		attack_windup = maxf(0.0, attack_windup - delta)
		if attack_windup <= 0.0:
			controller.call("damage_player", 18, global_position)
		# Cooldown deliberately does not tick during windup, matching the reference.
		return
	if alarm and visible and separation > 1.6:
		_set_motion_toward(target_player.global_position, CHASE_SPEED, delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if alarm and visible and separation < ATTACK_RANGE and attack_cooldown <= 0.0:
		attack_cooldown = 1.0
		attack_windup = ATTACK_WINDUP
		controller.call("register_event", "attack_windup", "guard_1")


func _update_detection(target_player: Node3D, delta: float) -> void:
	if bool(controller.get("alarm_triggered")) or bool(controller.get("panel_disabled")):
		alert_progress = 0.0
		return
	var offset := target_player.global_position - global_position
	offset.y = 0.0
	var separation := offset.length()
	var forward := Vector3(cos(facing), 0.0, sin(facing))
	var visible: bool = separation > 0.0 and separation <= 14.0 and forward.dot(offset / separation) > 0.55 and _can_see(target_player)
	alert_progress = alert_progress + delta if visible else 0.0
	if alert_progress >= DETECT_DURATION:
		controller.call("trigger_alarm")


func _can_see(target_player: Node3D) -> bool:
	return bool(controller.call("has_los", global_position + Vector3(0.0, 1.4, 0.0), target_player.global_position + Vector3(0.0, 1.4, 0.0)))


func _set_motion_toward(target: Vector3, speed: float, delta: float) -> void:
	var offset := target - global_position
	offset.y = 0.0
	var separation := offset.length()
	if separation <= 0.08:
		return
	var direction := offset / separation
	var travel_speed := minf(speed, separation / maxf(delta, 0.00001))
	velocity.x = direction.x * travel_speed
	velocity.z = direction.z * travel_speed
	facing = atan2(direction.z, direction.x)


func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _build_model() -> void:
	if _visual != null:
		return
	_collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	_collider.shape = capsule
	_collider.position.y = 0.9
	add_child(_collider)
	# Movement stays at the reference .18-tile radius; hitscan uses its wider
	# .28-tile horizontal aiming tolerance, independently of physical movement.
	_hit_area = GuardHitTarget.new()
	_hit_area.name = "HitTarget"
	_hit_area.guard = self
	_hit_area.collision_layer = 4
	_hit_area.collision_mask = 0
	_hit_area.monitoring = false
	var hit_shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.56
	cylinder.height = 1.8
	hit_shape.shape = cylinder
	hit_shape.position.y = 0.9
	_hit_area.add_child(hit_shape)
	add_child(_hit_area)
	_visual = Node3D.new()
	_visual.name = "ArmorModel"
	add_child(_visual)
	var armor := _material(Color("526246"))
	var dark := _material(Color("202f27"))
	var trim := _material(Color("b3a26b"))
	_visor = _material(Color("f1b563"), true)
	# Model faces +X. Rotation below maps browser-facing angles onto Godot's X/Z plane.
	_box(_visual, Vector3(0.48, 0.6, 0.72), Vector3(0.0, 1.15, 0.0), armor)
	_box(_visual, Vector3(0.12, 0.28, 0.55), Vector3(0.29, 1.2, 0.0), dark)
	_box(_visual, Vector3(0.13, 0.07, 0.51), Vector3(0.3, 1.36, 0.0), trim)
	_box(_visual, Vector3(0.38, 0.4, 0.43), Vector3(0.0, 1.66, 0.0), armor)
	_box(_visual, Vector3(0.04, 0.09, 0.32), Vector3(0.211, 1.69, 0.0), _visor)
	_left_leg = _box(_visual, Vector3(0.31, 0.64, 0.25), Vector3(0.0, 0.43, -0.23), dark)
	_right_leg = _box(_visual, Vector3(0.31, 0.64, 0.25), Vector3(0.0, 0.43, 0.23), dark)
	_box(_left_leg, Vector3(0.38, 0.13, 0.28), Vector3(0.05, -0.28, 0.0), dark)
	_box(_right_leg, Vector3(0.38, 0.13, 0.28), Vector3(0.05, -0.28, 0.0), dark)
	_left_arm = Node3D.new()
	_left_arm.position = Vector3(0.0, 1.35, -0.48)
	_visual.add_child(_left_arm)
	_right_arm = Node3D.new()
	_right_arm.position = Vector3(0.0, 1.35, 0.48)
	_visual.add_child(_right_arm)
	for arm: Node3D in [_left_arm, _right_arm]:
		_box(arm, Vector3(0.26, 0.57, 0.25), Vector3(0.0, -0.21, 0.0), armor)
		_box(arm, Vector3(0.29, 0.14, 0.27), Vector3(0.0, -0.49, 0.0), trim)
	_box(_right_arm, Vector3(0.42, 0.13, 0.18), Vector3(0.17, -0.41, 0.0), dark)


func _update_pose(delta: float) -> void:
	if _visual == null:
		return
	_phase += delta
	_visual.rotation.y = -facing
	_visual.position.y = sin(_phase * 2.0) * 0.012
	_visual.rotation.z = -0.1 if stagger > 0.0 else 0.0
	var stride := sin(_phase * 8.0) * 0.14 if moving else 0.0
	_left_leg.position.x = stride
	_right_leg.position.x = -stride
	_left_arm.rotation.z = PI * 0.45 if attack_windup > 0.0 else 0.0
	_right_arm.rotation.z = PI * 0.45 if attack_windup > 0.0 else 0.0
	_visor.albedo_color = Color("ff503b") if attack_windup > 0.0 else Color("fff0c0") if stagger > 0.0 else Color("f1b563")
	_visor.emission = _visor.albedo_color


func _material(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.emission_enabled = emissive
	if emissive:
		material.emission = color
		material.emission_energy_multiplier = 1.5
	return material


func _box(parent: Node3D, size: Vector3, center: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.position = center
	instance.material_override = material
	parent.add_child(instance)
	return instance
