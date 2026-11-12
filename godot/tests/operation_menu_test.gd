extends SceneTree
var failures:=0
func _initialize()->void: call_deferred("run")
func frames(n:int)->void:
	for i in n: await process_frame
func check(id:String,ok:bool)->void:
	print(("PASS " if ok else "FAIL ")+id)
	if not ok: failures+=1
func run()->void:
	var campaign=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(campaign)
	current_scene=campaign
	await frames(4)
	check("title exposes tactical operation",campaign.operation_button.visible and campaign.operation_button.text.contains("Tactical Operation"))
	campaign.operation_button.pressed.emit()
	await frames(8)
	var operation=current_scene
	check("operation menu loads through title entry",operation.has_method("current_objective") and operation.operation_button.text=="Original Campaign")
	operation.campaign_button.pressed.emit()
	operation.deploy_button.pressed.emit()
	await frames(4)
	check("operation deploy button starts operation",operation.active and operation.mission.id=="tactical-operation")
	operation.show_title()
	operation.operation_button.pressed.emit()
	await frames(8)
	campaign=current_scene
	check("original campaign menu remains available",campaign.missions.size()==3 and campaign.campaign_button.text=="Start Campaign")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/godot/campaign-screenshots/operation-campaign-menu.png")
	campaign.campaign_button.pressed.emit()
	campaign.deploy_button.pressed.emit()
	await frames(4)
	check("original campaign still deploys original Breach scout",campaign.active and campaign.mission.id=="breach" and campaign.enemies[0].role=="scout")
	print("MENU CHECKS ",5-failures,"/5 failures=",failures)
	campaign.queue_free()
	await create_timer(.2,true).timeout
	quit(1 if failures else 0)
