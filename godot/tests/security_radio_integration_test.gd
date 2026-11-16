extends SceneTree
var checks:=0
var failures:=0
var game:Node
var sender:Node3D
var recipient:Node3D
const A:=Vector3(24,0,34)
const B:=Vector3(5,0,35)
func _initialize()->void: call_deferred("run")
func check(label:String,ok:bool)->void:
	checks+=1
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures+=1
func frames(count:int)->void:
	for i in count: await physics_frame
func fresh(at:Vector3=A)->void:
	game.new_operation()
	game.deploy_current()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies: enemy.set_physics_process(false)
	sender=game._security_enemy_by_id("security-smg")
	recipient=game._security_enemy_by_id("security-rifle")
	game.player.global_position=at
	game.player.camera.look_at(sender.eye(),Vector3.UP)
	await frames(3)
func start()->int:
	sender._physics_process(.016)
	var pending:Array=game.security_director.get_pending_radio_reports()
	return int(pending[0].id) if not pending.is_empty() else 0
func step(delta:float)->void: game._advance_security_director(delta)
func heard()->Array[Dictionary]: return game.security_director.get_delivered_knowledge_for("security-rifle")
func capture(name:String)->void:
	var folder:=OS.get_environment("BUNKER_RADIO_CAPTURE")
	if folder.is_empty() or DisplayServer.get_name()=="headless": return
	game._update_hud()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run()->void:
	game=load("res://scenes/control_room.tscn").instantiate()
	root.add_child(game)
	await fresh()
	check("authored SECURITY pair uses original spawns and eight-guard map",sender.spawn_position==Vector3(24,0,38) and recipient.spawn_position==Vector3(27,0,30) and game.enemies.size()==8)
	check("scenario A has real sender sight and no recipient sight",sender.can_see_player() and not recipient.can_see_player())
	var report_id:=start()
	var original:Vector3=game.player.camera.global_position
	check("actual sighting starts a delayed report without immediate ally memory",report_id>0 and sender.last_known==original and recipient.last_known==Vector3.INF)
	check("transmission has a local visible indicator",sender._radio_report_id==report_id and sender._visual.radio_label.visible and sender._visual.radio_indicator.visible)
	var voice:AudioStreamPlayer3D=game.audio._voices[-1]
	check("start cue is spatial and short",voice.name=="Sound_radio_start" and voice.global_position.distance_to(sender.global_position+Vector3.UP*1.4)<.01 and voice.stream.get_length()<.2)
	await capture("radio-warning")
	step(1.0)
	check("no radio knowledge or local memory before deadline",heard().is_empty() and recipient.last_known==Vector3.INF)
	step(.4)
	check("scenario A delivers original snapshot into existing investigation",heard().size()==1 and recipient.last_known==original and recipient.state=="suspicious" and is_equal_approx(recipient.memory_remaining,6.6))
	check("successful delivery clears sender indicator",sender._radio_report_id==0 and not sender._visual.radio_label.visible)
	check("success cue uses original spatial sound system",game.audio._voices[-1].name=="Sound_radio_success")
	recipient._decide(.016,false)
	check("recipient executes existing path-based investigation",recipient.velocity.length()>0 and not recipient._path.is_empty())
	var prior_memory:float=recipient.memory_remaining
	step(.2)
	check("report completes once without repeated memory refresh",heard().size()==1 and recipient.memory_remaining==prior_memory)
	await fresh()
	report_id=start()
	step(.7)
	sender.receive_hit(100)
	step(.7)
	check("scenario B death immediately cancels queued report",game.security_director.get_radio_report(report_id).cancellation_reason=="death" and heard().is_empty() and recipient.last_known==Vector3.INF)
	check("interruption cue is distinct and indicator clears",game.audio._voices[-1].name=="Sound_radio_interrupted" and sender._radio_report_id==0)
	await fresh(Vector3(24,0,48.9))
	sender.rotation.y=PI # Test approach from the south, retaining authored spawn positions.
	check("long-range interruption fixture is visible to sender outside partner hearing",sender.can_see_player() and recipient.global_position.distance_to(game.player.camera.global_position)>19)
	report_id=start()
	await frames(2)
	for shot in 5:
		game.cooldown=0 # Explicit .24s steps below honor the unchanged pistol cadence.
		game.shoot()
		step(.24)
	step(.2)
	check("real pistol incapacitation interrupts without granting distant partner knowledge",sender.hp==0 and game.shots==5 and heard().is_empty() and recipient.last_known==Vector3.INF and game.security_director.get_radio_report(report_id).cancellation_reason=="hit_stagger")
	await fresh()
	report_id=start()
	step(.7)
	var hp:int=sender.hp
	sender.receive_hit(1)
	check("real nonfatal hit-stagger interrupts immediately",sender.hp==hp-1 and sender.stagger==.22 and game.security_director.get_pending_radio_reports().is_empty())
	step(.7)
	check("hit-stagger cancellation prevents any recipient knowledge",heard().is_empty() and recipient.last_known==Vector3.INF and game.security_director.get_radio_report(report_id).cancellation_reason=="hit_stagger")
	await fresh()
	report_id=start()
	sender.state="reload"
	sender.reload_remaining=2
	step(1.4)
	check("reload animation does not cancel radio or change magazine mechanics",heard().size()==1 and sender.reload_remaining==2 and sender.magazine==sender.capacity())
	await fresh()
	report_id=start()
	step(.6)
	game.player.global_position=B
	await frames(3)
	check("scenario C relocation is occluded from both authored guards",not sender.can_see_player() and not recipient.can_see_player())
	sender._observe_visibility(false,.016)
	step(.8)
	check("scenario C delivers A rather than hidden B",recipient.last_known==original and heard()[0].position==original and recipient.last_known!=game.player.camera.global_position)
	var health_before:int=game.health
	var magazine:int=recipient.magazine
	recipient._fire()
	check("radio cannot enable firing through real occlusion",game.health==health_before and recipient.magazine==magazine)
	var remembered:Vector3=recipient.last_known
	recipient.receive_hit(1)
	check("hidden hit retains legitimate historical evidence",recipient.last_known==remembered and recipient.stagger==.22)
	await fresh(B)
	var counts:int=game.security_director.get_active_observations().size()
	sender.receive_hit(1)
	check("hidden hit without evidence cannot read live camera",sender.last_known==Vector3.INF and sender.memory_remaining==0 and game.security_director.get_active_observations().size()==counts)
	game.player.global_position=Vector3(6,0,35) # Still behind partition, now inside 19m hearing.
	await frames(2)
	sender.hear_shot(game.player.camera.global_position)
	check("genuine nearby gunshot remains audible after fair hit reaction",not sender.can_see_player() and sender.last_known==game.player.camera.global_position and sender.memory_remaining==7)
	await fresh()
	report_id=start()
	step(.7)
	game.player.global_position=Vector3(27,0,26)
	await frames(3)
	check("recipient fixture obtains a real newer direct sighting",recipient.can_see_player())
	recipient._physics_process(.016)
	var newer:Vector3=recipient.last_known
	step(.7)
	check("older radio cannot overwrite recipient's newer direct knowledge",heard().size()==1 and recipient.last_known==newer and recipient.last_known!=original)
	await fresh()
	report_id=start()
	recipient.receive_hit(100)
	step(1.4)
	check("dead recipient is excluded without reviving memory",heard().is_empty() and recipient.hp==0 and recipient.last_known==Vector3.INF)
	await fresh()
	report_id=start()
	game.enemies.erase(recipient)
	recipient.queue_free()
	await frames(2)
	step(1.4)
	check("removed recipient cannot receive a completed report",heard().is_empty())
	await fresh()
	report_id=start()
	game.guard=null # Remove the legacy HUD alias as well as the fixture actor.
	game.enemies.erase(sender)
	sender.queue_free()
	await frames(2)
	step(1.4)
	check("removed transmitter cannot deliver",heard().is_empty() and game.security_director.get_pending_radio_reports().is_empty())
	await fresh()
	var outsider:Node3D=game.enemies[2]
	var observation:int=game.record_security_observation(outsider,"visual_contact",Vector3.ONE,1,8)
	check("non-SECURITY guards cannot broadcast to squad",game.queue_security_radio(outsider,observation)==0)
	check("sender cannot transmit a partner's actual observation",game.queue_security_radio(sender,observation)==0)
	recipient.global_position=sender.global_position+Vector3(12.1,0,0)
	check("mission controller enforces documented partner range",start()==0)
	await fresh()
	report_id=start()
	game.set_paused(true)
	step(3)
	await create_timer(.05,true).timeout
	check("pause freezes report countdown and delivery",game.security_director.get_simulation_time()==0 and heard().is_empty() and game.security_director.get_pending_radio_reports().size()==1)
	game.set_paused(false)
	step(1.4)
	check("resume completes remaining simulation countdown",heard().size()==1)
	await fresh()
	report_id=start()
	var old:RefCounted=game.security_director
	game.retry_run()
	for enemy in game.enemies: enemy.set_physics_process(false)
	check("retry clears old queue knowledge and indicators",old.get_pending_radio_reports().is_empty() and old.get_delivered_knowledge_for("security-rifle").is_empty() and game.security_director.get_attempt_id()!=old.get_attempt_id() and game.enemies[0]._radio_report_id==0)
	await fresh()
	report_id=start()
	old=game.security_director
	game.show_title()
	check("title exit clears all mission radio data",old.get_pending_radio_reports().is_empty() and old.get_radio_history().is_empty() and old.get_delivered_knowledge_for("security-rifle").is_empty() and game.security_director==null)
	await fresh()
	game.session.preferences.muted=true
	report_id=start()
	step(1.4)
	check("muted audio cannot change report delivery or investigation",heard().size()==1 and recipient.last_known==original and game.audio._voices.is_empty())
	var stale_report:Dictionary=heard()[0]
	game.session.preferences.muted=false
	await fresh()
	check("stale previous-attempt delivery is rejected by the actual recipient",not recipient.receive_radio_report(stale_report,0) and recipient.last_known==Vector3.INF)
	report_id=start()
	var started_at:=Time.get_ticks_usec()
	for i in 1000: step(.001)
	var elapsed_us:=Time.get_ticks_usec()-started_at
	check("eight-actor controller benchmark preserves pending timing and bounds",game.enemies.size()==8 and heard().is_empty() and game.security_director.get_pending_radio_reports().size()==1)
	print("RADIO BENCHMARK: 1000 controller/director updates with eight authored actors: %.2f us/update (not full physics FPS)" % (float(elapsed_us)/1000))
	await fresh()
	report_id=start()
	old=game.security_director
	game.new_campaign()
	game.deploy_current()
	check("campaign switching clears radio and preserves original actors",old.get_pending_radio_reports().is_empty() and game.security_director==null and game.enemies[0].role=="scout")
	await fresh()
	report_id=start()
	old=game.security_director
	game.queue_free()
	await frames(3)
	check("scene teardown clears radio without live references",old.get_pending_radio_reports().is_empty() and old.get_radio_history().is_empty() and old.get_attempt_id()==0)
	game=load("res://scenes/tactical_operation.tscn").instantiate()
	root.add_child(game)
	game.new_campaign()
	game.deploy_current()
	check("Iron Relay keeps separate AI with no radio director",game.security_director==null and game.enemies[0].get_script().resource_path=="res://scripts/tactical_enemy.gd")
	game.queue_free()
	await create_timer(.2,true).timeout
	print("SECURITY RADIO INTEGRATION: %d/%d passed; failures=%d" % [checks-failures,checks,failures])
	quit(1 if failures else 0)
