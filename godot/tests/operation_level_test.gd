extends SceneTree
## Isolated level/navigation checks using the actual player collision controller.
class SessionStub extends RefCounted:
	var preferences := {"sensitivity":0.003}
class ControllerStub extends Node3D:
	var active := true
	var reload_remaining := 0.0
	var flash := 0.0
	var elapsed := 0.0
	var session := SessionStub.new()
	func get_weapon_def() -> Dictionary: return {"reload":0.8,"recoil":1.0,"muzzle":Vector3(0,0.055,-0.2)}
	func progress_tutorial(_trigger: String) -> void: pass
var checks := 0
var failures := 0
var level: Node3D
var player: CharacterBody3D
func _initialize() -> void: call_deferred("run")
func check(id: String,ok: bool) -> void:
	checks+=1
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failures+=1
func frames(n: int) -> void:
	for i in n: await physics_frame
func walk_to(at: Vector3) -> bool:
	for frame in 1000:
		var offset := at-player.global_position
		offset.y=0
		if offset.length()<0.16:
			Input.action_release("move_forward")
			return absf(player.global_position.y-at.y)<0.28
		player.rotation.y=atan2(-offset.x,-offset.z)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	print("STUCK wanted ",at," actual ",player.global_position)
	return false
func route(points: Array) -> bool:
	for at: Vector3 in points:
		if not await walk_to(at): return false
	return true
func capture(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/operation-level-"+id+".png")
func run() -> void:
	for action in ["move_forward","move_back","strafe_left","strafe_right","turn_left","turn_right","crouch","sprint","lean_left","lean_right","aim_weapon","fire"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var controller := ControllerStub.new()
	root.add_child(controller)
	level=load("res://scenes/operation_level.tscn").instantiate()
	controller.add_child(level)
	var contract: Dictionary=level.mission_contract()
	player=load("res://scripts/player.gd").new()
	controller.add_child(player)
	player.setup(controller)
	player.global_position=contract.spawn
	player.rotation.y=-PI/2
	await frames(4)
	await capture("entry")
	check("authored level provides three objective stages",contract.objectives.size()==3)
	check("blocked furniture target is rejected",level.find_path(contract.spawn,Vector3(25,0,8)).is_empty())
	check("outside target is rejected",level.find_path(contract.spawn,Vector3(-10,0,8)).is_empty())
	check("physically safe actor can escape conservative cover margin",not level.find_path(Vector3(26.1,0,8),Vector3(28,0,8)).is_empty())
	check("closed gate blocks direct navigation edge",not level._edge_clear(Vector3(32,0,15),Vector3(36,0,15)))
	var valid_spawns := true
	for spec: Dictionary in contract.bots:
		if level.find_path(contract.spawn,spec.position).is_empty():
			print("INVALID SPAWN ",spec.id," at ",spec.position)
			valid_spawns=false
	check("all enemy spawns have reachable capsule-clear paths",valid_spawns)
	var valid_cover := true
	for at: Vector3 in level.cover_points:
		if level.find_path(contract.spawn,at).is_empty():
			print("INVALID COVER ",at)
			valid_cover=false
	check("cover candidates are reachable",valid_cover)
	check("actual player reaches access terminal",await route(contract.route_waypoints.to_access))
	await capture("maintenance")
	level.set_access_granted(true)
	await frames(3)
	check("open gate agrees with navigation",level._edge_clear(Vector3(32,0,15),Vector3(36,0,15)))
	check("main path reaches raised data platform",await route(contract.route_waypoints.main_to_data))
	await capture("archive")
	check("stairs and extraction route are physically traversable",await route(contract.route_waypoints.to_extract))
	await capture("extraction")
	player.global_position=Vector3(12,0,38.5)
	player.velocity=Vector3.ZERO
	await frames(3)
	check("alternate maintenance approach reaches data",await route(contract.route_waypoints.alternate_to_data))
	player.global_position=Vector3(12,0,38.5)
	player.velocity=Vector3.ZERO
	await frames(3)
	check("risk/reward armory approach is traversable",await route(contract.route_waypoints.armory))
	await capture("armory")
	print("LEVEL CHECKS ",checks-failures,"/",checks," failures=",failures)
	controller.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
