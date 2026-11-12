extends SceneTree
## Deterministic AI fixture. Operation navigation/routes are separately integrated tests.
class Player extends CharacterBody3D:
	var camera: Camera3D
	func _init() -> void:
		collision_layer = 2
		collision_mask = 1
		var collider := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.36
		capsule.height = 1.8
		collider.shape = capsule
		collider.position.y = 0.9
		add_child(collider)
		camera = Camera3D.new()
		camera.position.y = 1.4
		add_child(camera)
class Room extends Node3D:
	var cover_points: Array[Vector3] = []
	func find_path(_from: Vector3,to: Vector3) -> PackedVector3Array:
		return PackedVector3Array([to]) if to.x<20 else PackedVector3Array()
class Controller extends Node3D:
	var active := true
	var player: CharacterBody3D
	var room: Node3D
	var enemies: Array = []
	var damage_count := 0
	var damage_total := 0
	var events: Array = []
	func has_los(from: Vector3,to: Vector3) -> bool:
		return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty()
	func damage_player(amount: int,_source: Vector3) -> void:
		damage_count += 1
		damage_total += amount
	func register_event(kind: String,detail: String="",bot_id: String="") -> void:
		events.append({"event":kind,"detail":detail,"bot_id":bot_id})
	func play_sound(_kind: String,_at: Vector3) -> void: pass

var game: Node3D
var failed := 0
var count := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(label: String,ok: bool) -> void:
	count += 1
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failed += 1
func enemy(at: Vector3,role: String="tactical_smg",id: String="test") -> CharacterBody3D:
	var unit = load("res://scripts/tactical_enemy.gd").new()
	game.add_child(unit)
	unit.setup(game,at,{"id":id,"role":role,"patrol":[at]})
	game.enemies.append(unit)
	return unit
func box(at: Vector3,size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	game.add_child(body)
	return body
func run() -> void:
	game = Controller.new()
	root.add_child(game)
	game.room = Room.new()
	game.add_child(game.room)
	game.player = Player.new()
	game.add_child(game.player)
	game.player.position = Vector3(0,0,-8)
	box(Vector3(0,-0.2,0),Vector3(80,0.4,80))
	var unit = enemy(Vector3.ZERO)
	await frames(18)
	check("visible threat has readable initial reaction",unit.shots_fired==0 and game.damage_count==0)
	await frames(18)
	check("enemy enters engage and telegraphs preparation",unit.state=="engage" and unit.attack_windup>0 and unit.shots_fired==0)
	var barrier := box(Vector3(0,1.5,-4),Vector3(20,3,0.4))
	await frames(45)
	check("new wall cancels prepared attack before firing",unit.shots_fired==0 and game.damage_count==0)
	var memory: Vector3 = unit.last_known_position
	game.player.position = Vector3(5,0,-8)
	await frames(30)
	check("hidden movement does not update remembered location",unit.last_known_position.distance_to(memory)<0.01)
	await frames(170)
	check("lost sight transitions to search",unit.state=="search")
	unit.set_physics_process(false)
	barrier.queue_free()
	await frames(3)
	game.player.position = Vector3(0,0,-8)
	unit.reset_guard()
	unit.last_known_position = game.player.position
	unit.alert_progress = unit._reaction
	unit.state = "engage"
	unit.magazine = 1
	await frames(3)
	check("clear ray consumes round and damages player",unit._fire_round() and unit.magazine==0 and game.damage_count==1)
	unit.set_physics_process(true)
	await frames(2)
	check("empty magazine starts finite reload",unit.state=="reload" and unit.reload_remaining>0)
	paused = true
	var reload_left: float = unit.reload_remaining
	await create_timer(0.15,true).timeout
	check("pause freezes enemy reload timer",unit.reload_remaining==reload_left)
	paused = false
	await frames(118)
	check("enemy reload transfers finite reserve",unit.magazine==8 and unit.reserve==40)
	unit.set_physics_process(false)
	unit.velocity = Vector3.ZERO
	unit._goal = Vector3.INF
	unit._path_clock = 0
	unit._move_to(Vector3(30,0,-8),2.5,0.016)
	check("unreachable navigation has no direct-motion fallback",Vector2(unit.velocity.x,unit.velocity.z).length()==0)
	var cover_wall := box(Vector3(2,1.5,-5),Vector3(1.4,3,1))
	game.room.cover_points.assign([Vector3(4,0,-2),Vector3(25,0,-2)])
	await frames(3)
	check("cover selection requires reachable world occlusion",unit.choose_cover(game.player.position).distance_to(Vector3(4,0,-2))<0.01)
	cover_wall.queue_free()
	await frames(3)
	var ally = enemy(Vector3(6,0,0),"tactical_smg","ally")
	var distant = enemy(Vector3(25,0,0),"tactical_rifle","distant")
	ally.set_physics_process(false)
	distant.set_physics_process(false)
	unit.last_known_position = game.player.position
	unit._share_clock = 0
	unit._share_contact()
	check("nearby ally receives bounded last-known contact",ally.state=="suspicious" and ally.last_known_position==game.player.position)
	check("distant ally receives no contact",distant.last_known_position==Vector3.INF)
	ally.global_position = Vector3(0,0,-4)
	unit.global_position = Vector3.ZERO
	unit.rotation.y = 0
	unit.magazine = 8
	await frames(3)
	var ammo_before: int = unit.magazine
	var damage_before: int = game.damage_count
	check("friendly body blocks enemy fire",not unit._fire_round() and unit.magazine==ammo_before and game.damage_count==damage_before)
	var collision = unit.move_and_collide(Vector3(0,0,-5))
	check("enemy bodies prevent stacking",collision!=null and unit.global_position.distance_to(ally.global_position)>=0.65)
	# Hold a mover against an immovable wall: slide zeros velocity, but intention must accumulate.
	unit.global_position = Vector3(0,0,-3.1)
	ally.global_position = Vector3(6,0,0)
	var blocked_wall := box(Vector3(0,1.5,-3.6),Vector3(10,3,0.3))
	unit._reaction = 1000
	unit.alert_progress = 0
	unit.state = "search"
	unit.last_known_position = Vector3(0,0,-8)
	unit._search_clock = 6
	unit._goal = Vector3.INF
	unit._path_clock = 0
	unit._blocked_clock = 0
	unit._yield_clock = 0
	unit.set_physics_process(true)
	await frames(32)
	check("blocked intention accumulates despite slide zeroing velocity",unit._blocked_clock>0.2)
	await frames(35)
	check("blocked passage starts yielding or lateral escape",unit._yield_clock>0 or absf(unit.global_position.x)>0.15)
	unit.set_physics_process(false)
	blocked_wall.queue_free()
	unit.attack_windup = 0.4
	unit.receive_hit(1)
	check("hit stagger cancels preparation",unit.attack_windup==0 and unit.stagger>0)
	unit.receive_hit(99)
	await frames(3)
	check("disabled enemy remains registered but cannot fire or collide",is_instance_valid(unit) and unit.hp==0 and unit.collision_layer==0 and not unit._fire_round())
	check("rifle role has slower pace and longer preferred range",distant._speed<ally._speed and distant._preferred>ally._preferred and distant._reload_duration>ally._reload_duration)
	game.queue_free()
	await frames(3)
	game = Controller.new()
	root.add_child(game)
	game.room = load("res://scenes/operation_level.tscn").instantiate()
	game.add_child(game.room)
	game.player = Player.new()
	game.player.position = Vector3(100,0,100)
	game.add_child(game.player)
	unit = enemy(Vector3(40,0,30),"tactical_smg","ramp_mover")
	unit.state = "search"
	unit.last_known_position = Vector3(39.8,1.2,41)
	unit._search_clock = 8
	await frames(3)
	for i in 1000:
		if Vector2(unit.global_position.x-39.8,unit.global_position.z-41).length()<0.7 and unit.global_position.y>1.0: break
		await physics_frame
	check("actual operation graph carries enemy up archive ramp",Vector2(unit.global_position.x-39.8,unit.global_position.z-41).length()<0.7 and unit.global_position.y>1.0)
	unit.set_physics_process(false)
	unit.global_position = Vector3(49.8,0.2,41.5)
	unit.velocity = Vector3.ZERO
	unit.last_known_position = Vector3(44,1.2,42.5)
	unit.state = "search"
	unit._state_clock = 0
	unit._search_clock = 8
	unit._goal = Vector3.INF
	unit._path_clock = 0
	unit._blocked_clock = 0
	unit._yield_clock = 0
	unit.set_physics_process(true)
	for i in 700:
		if Vector2(unit.global_position.x-44,unit.global_position.z-42.5).length()<0.7 and unit.global_position.y>1.0: break
		await physics_frame
	if Vector2(unit.global_position.x-44,unit.global_position.z-42.5).length()>=0.7 or unit.global_position.y<=1.0:
		print("STAIR PATH FAILURE actual=",unit.global_position," state=",unit.state," path=",unit._path," index=",unit._path_index," goal=",unit._goal)
	check("actual operation graph carries enemy up archive stairs",Vector2(unit.global_position.x-44,unit.global_position.z-42.5).length()<0.7 and unit.global_position.y>1.0)
	print("TACTICAL ENEMIES: ",count-failed,"/",count," passed; failures=",failed)
	game.queue_free()
	await create_timer(0.2,true).timeout
	quit(1 if failed else 0)
