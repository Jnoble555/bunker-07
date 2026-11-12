extends SceneTree
var game: Node
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func check(id: String,ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failures += 1
func equip_shotgun() -> void:
	game.weapon_ammo.shotgun={"magazine":4,"reserve":12}
	game.switch_weapon("shotgun")
	game.cooldown=0
func run() -> void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	game.start_run()
	for actor in game.enemies: actor.set_physics_process(false)
	game.player.global_position=Vector3(3,0,17)
	game.player.rotation.y=-PI/2
	game.guard.spawn_position=Vector3(6,0,17)
	game.guard.reset_guard()
	equip_shotgun()
	await frames(3)
	game.shoot()
	check("close shotgun pellets defeat armored target",game.guard.hp==0)
	check("one blast counts one shot and at most one hit",game.shots==1 and game.hits==1)
	var defeats := 0
	for row in game.events:
		if row.event=="bot_disabled": defeats += 1
	check("multi-pellet defeat emits once with current hit count",defeats==1 and game.hits<=game.shots)
	game.guard.reset_guard()
	var cover := StaticBody3D.new()
	cover.position=Vector3(4.5,1.4,17)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(.2,2.8,2)
	shape.shape=box
	cover.add_child(shape)
	game.add_child(cover)
	await frames(3)
	game.cooldown=0
	var before: int=game.hits
	game.shoot()
	check("intervening cover blocks integrated pellet damage",game.guard.hp==3 and game.hits==before)
	cover.queue_free()
	game.mission_index=0
	game.start_run()
	for actor in game.enemies: actor.set_physics_process(false)
	game.enemies[0].spawn_position=Vector3(22.5,0,4)
	game.enemies[0].reset_guard()
	game.player.global_position=Vector3(4,0,4)
	game.player.rotation.y=-PI/2
	equip_shotgun()
	await frames(3)
	game.shoot()
	check("shotgun loses damaging effectiveness beyond falloff",game.enemies[0].hp==2 and game.hits==0 and game.shots==1)
	check("shotgun consumes one shell per blast",game.ammo==3 and game.weapon_ammo.shotgun.magazine==3)
	game.begin_reload()
	await frames(8)
	var ammo: int=game.ammo
	var reserve: int=game.weapon_ammo.shotgun.reserve
	game.switch_weapon("pistol")
	game.switch_weapon("shotgun")
	check("shell reload cancellation preserves both ammo stores",game.ammo==ammo and game.weapon_ammo.shotgun.reserve==reserve and game.reload_remaining==0)
	print("SHOTGUN INTEGRATION ",checks-failures,"/",checks," failures=",failures)
	game.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
