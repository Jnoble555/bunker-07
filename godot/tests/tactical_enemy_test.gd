extends SceneTree
const Enemy=preload("res://scripts/tactical_enemy.gd")
class TestPlayer extends Node3D:
	var camera:Camera3D
	func _ready()->void:
		camera=Camera3D.new()
		camera.position.y=1.4
		add_child(camera)
class TestRoom extends Node3D:
	var cover_points:Array[Vector3]=[]
	func tactical_path(_from:Vector3,to:Vector3)->Array[Vector3]: return [Vector3(to.x,0,to.z)]
class TestController extends Node3D:
	var active:=true
	var player:Node3D
	var room:Node3D
	var enemies:Array=[]
	var damage:=0
	var events:Array=[]
	func damage_player(amount:int,_source:Vector3)->void: damage+=amount
	func register_event(event:String,detail:String="",bot_id:String="")->void: events.append([event,detail,bot_id])
	func play_sound(_kind:String,_at:Vector3)->void: pass
var checks:=0
var failures:=0
var controller:TestController
func _initialize()->void: call_deferred("run")
func check(label:String,passed:bool)->void:
	checks+=1
	print(("PASS " if passed else "FAIL ")+label)
	if not passed: failures+=1
func frames(count:int)->void:
	for i in count: await physics_frame
func solid(at:Vector3,size:Vector3)->StaticBody3D:
	var body:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=size
	shape.shape=box
	body.add_child(shape)
	body.position=at
	controller.add_child(body)
	return body
func run()->void:
	controller=TestController.new()
	root.add_child(controller)
	controller.room=TestRoom.new()
	controller.add_child(controller.room)
	controller.player=TestPlayer.new()
	controller.player.position=Vector3(0,0,-8)
	controller.add_child(controller.player)
	solid(Vector3(0,-.2,0),Vector3(50,.4,50))
	var enemy:=Enemy.new()
	controller.add_child(enemy)
	enemy.setup(controller,Vector3.ZERO,{"id":"test_smg","role":"smg"})
	controller.enemies=[enemy]
	await frames(20)
	check("visible threat has readable reaction before damage",controller.damage==0 and enemy.state=="suspicious")
	await frames(100)
	check("armed burst consumes finite magazine and damages",enemy.magazine<enemy.capacity() and controller.damage>0)
	var wall:=solid(Vector3(0,1.5,-4),Vector3(10,3,.3))
	await frames(3)
	var before:=controller.damage
	var remembered:Vector3=enemy.last_known
	controller.player.position.x=6
	await frames(30)
	check("lost sight retains old position instead of tracking through wall",enemy.last_known.distance_to(remembered)<.01 and controller.damage==before)
	check("world occlusion blocks firing-time visibility",not enemy.can_see_player())
	enemy.magazine=0
	enemy.reload_remaining=0
	await frames(2)
	check("empty magazine enters explicit reload",enemy.state=="reload" and enemy.reload_remaining>0)
	var left:float=enemy.reload_remaining
	paused=true
	await create_timer(.1,true).timeout
	check("pause freezes enemy reload",enemy.reload_remaining==left)
	paused=false
	await frames(130)
	check("reload refills bounded magazine",enemy.magazine==enemy.capacity() and enemy.reload_remaining==0)
	await frames(500)
	check("expired memory returns to patrol",enemy.state=="patrol" and enemy.last_known==Vector3.INF)
	enemy.hear_shot(Vector3(1,0,-2))
	check("nearby shot starts finite investigation",enemy.state=="suspicious" and enemy.last_known==Vector3(1,0,-2))
	enemy.receive_hit(100)
	check("death immediately disables collision and subsequent damage",enemy.hp==0 and enemy.collision_layer==0)
	enemy.reset_guard()
	check("retry restores state ammo and health",enemy.hp==4 and enemy.magazine==15 and enemy.state=="patrol" and enemy.last_known==Vector3.INF)
	var rifle:=Enemy.new()
	controller.add_child(rifle)
	rifle.setup(controller,Vector3(2,0,0),{"role":"rifle"})
	controller.enemies.append(rifle)
	check("rifle has distinct magazine and armor",rifle.magazine==9 and rifle.hp==5)
	enemy.set_physics_process(false)
	enemy.state="suspicious"
	enemy.last_known=enemy.global_position+Vector3.UP*1.4
	enemy.memory_remaining=3
	enemy._decide(.016,false)
	check("arrival at remembered eye position starts local search",enemy.state=="search")
	wall.queue_free()
	await frames(3)
	enemy.state="engage"
	enemy.rotation.y=PI/2
	controller.player.position=enemy.global_position+Vector3(0,0,-8)
	enemy._fire()
	var toward: Vector3=(controller.player.camera.global_position-enemy.eye()).normalized()
	check("repositioning enemy faces visible target before firing",-enemy.global_basis.z.dot(toward)>.99)
	controller.queue_free()
	await frames(3)
	print("TACTICAL ENEMY: %d/%d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
