extends SceneTree
const Director = preload("res://scripts/security_director.gd")
var checks := 0
var failures := 0
var deliveries: Array = []
func _initialize() -> void: call_deferred("run")
func check(label:String,ok:bool) -> void:
	checks+=1
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures+=1
func actors() -> Dictionary:
	return {"a":{"position":Vector3.ZERO,"alive":true,"interrupted":false},
		"b":{"position":Vector3(8,0,0),"alive":true,"interrupted":false},
		"c":{"position":Vector3(6,0,0),"alive":true,"interrupted":false}}
func fresh() -> RefCounted:
	var d:RefCounted=Director.new()
	d.initialize_for_mission("tactical-operation",11)
	d.sync_radio_actors(actors())
	d.radio_report_delivered.connect(func(id:String,report:Dictionary): deliveries.append([id,report]))
	return d
func visual(d:RefCounted,ttl:float=8.0) -> int:
	return d.record_observation("a","visual_contact",Vector3(1,1.4,4),.9,ttl)
func queue(d:RefCounted,observation:int,recipients:Array[String]=["b"],delay:float=1.4) -> int:
	return d.queue_radio_report("a",observation,recipients,delay)
func replay() -> Dictionary:
	var d:RefCounted=fresh()
	var id:=visual(d)
	queue(d,id,["c","b"])
	d.advance(.4)
	d.advance(1.0)
	return {"report":d.get_radio_report(1),"knowledge":d.get_delivered_knowledge_for("b")}
func run() -> void:
	var probe:RefCounted=Director.new()
	check("radio API is implemented",probe.has_method("queue_radio_report"))
	if not probe.has_method("queue_radio_report"):
		quit(1)
		return
	var d:RefCounted=fresh()
	check("missing observation rejected",queue(d,999)==0)
	var id:=visual(d)
	check("other guard cannot launder observation",d.queue_radio_report("b",id,["c"],1.4)==0)
	var sound:int=d.record_observation("a","sound_contact",Vector3.ONE,.6,7)
	check("sound and visual-loss cannot become sighting reports",queue(d,sound)==0 and queue(d,d.record_observation("a","visual_lost",Vector3.ONE,1,8))==0)
	check("invalid delay rejected",queue(d,id,["b"],0)==0 and queue(d,id,["b"],INF)==0)
	var report_id:=queue(d,id,["c","b","b","a"])
	check("report id and sorted unique nonself recipients",report_id==1 and d.get_pending_radio_reports()[0].recipient_ids==["b","c"])
	check("one pending transmission per sender",queue(d,id)==0)
	check("recipient learns nothing at submission",d.get_delivered_knowledge_for("b").is_empty())
	var copy:Dictionary=d.get_pending_radio_reports()[0]
	copy.position=Vector3(999,0,0)
	copy.recipient_ids.clear()
	d.advance(1.0)
	check("no delivery before completion",d.get_delivered_knowledge_for("b").is_empty())
	d.advance(.4)
	var knowledge:Dictionary=d.get_delivered_knowledge_for("b")[0]
	check("successful report delivers once",knowledge.id==1 and d.get_pending_radio_reports().is_empty())
	check("position timestamp confidence expiry and provenance preserved",knowledge.position==Vector3(1,1.4,4) and knowledge.observed_at==0 and knowledge.confidence==.9 and knowledge.expires_at==8 and knowledge.observer_id=="a" and knowledge.sender_id=="a" and knowledge.observation_id==id and knowledge.attempt_id==11)
	check("submission and scheduled completion are simulation times",knowledge.submitted_at==0 and knowledge.completes_at==1.4 and knowledge.status=="delivered")
	check("duplicate delivered evidence cannot refresh knowledge",queue(d,id)==0)
	knowledge.position=Vector3.ZERO
	check("knowledge queries are detached",d.get_delivered_knowledge_for("b")[0].position==Vector3(1,1.4,4))
	d.advance(1)
	check("completion does not redeliver",d.get_delivered_knowledge_for("b").size()==1)
	d.advance(5.6)
	check("knowledge expires on original deadline",d.get_delivered_knowledge_for("b").is_empty())
	check("expired evidence cannot be submitted",queue(d,id)==0)
	d=fresh()
	id=visual(d,1)
	check("queue rejects evidence expiring before completion",queue(d,id)==0)
	id=visual(d,2)
	report_id=queue(d,id)
	d.advance(2.1)
	check("late tick discards expired in-flight evidence",d.get_radio_report(report_id).cancellation_reason=="evidence_expired" and d.get_delivered_knowledge_for("b").is_empty())
	for reason in ["death","hit_stagger"]:
		d=fresh()
		report_id=queue(d,visual(d))
		check(reason+" cancellation succeeds once",d.cancel_radio_report(report_id,reason) and not d.cancel_radio_report(report_id,reason))
		d.advance(2)
		check(reason+" prevents delivery",d.get_delivered_knowledge_for("b").is_empty() and d.get_radio_report(report_id).status=="cancelled")
	d=fresh()
	report_id=queue(d,visual(d))
	var state:=actors()
	state.a.alive=false
	d.sync_radio_actors(state)
	d.advance(2)
	check("dead sender revalidated from actor snapshots",d.get_radio_report(report_id).cancellation_reason=="sender_unavailable" and d.get_delivered_knowledge_for("b").is_empty())
	d=fresh()
	report_id=queue(d,visual(d),["b","c"])
	state=actors()
	state.erase("b")
	d.sync_radio_actors(state)
	d.advance(1.4)
	check("removed recipient excluded without cancelling living recipient",d.get_delivered_knowledge_for("b").is_empty() and d.get_delivered_knowledge_for("c").size()==1)
	d=fresh()
	report_id=queue(d,visual(d))
	state=actors()
	state.b.alive=false
	d.sync_radio_actors(state)
	d.advance(1.4)
	check("dead recipient does not gain knowledge",d.get_delivered_knowledge_for("b").is_empty() and d.get_radio_report(report_id).status=="cancelled")
	d=fresh()
	state=actors()
	state.b.position=Vector3(12.1,0,0)
	d.sync_radio_actors(state)
	check("submission enforces communication range",queue(d,visual(d))==0)
	d.sync_radio_actors(actors())
	report_id=queue(d,visual(d))
	d.sync_radio_actors(state)
	d.advance(1.4)
	check("delivery enforces communication range",d.get_delivered_knowledge_for("b").is_empty() and d.get_radio_report(report_id).cancellation_reason=="no_recipients")
	d=fresh()
	report_id=queue(d,visual(d))
	state=actors()
	state.a.interrupted=true
	d.sync_radio_actors(state)
	check("stagger snapshot cancels pending report",d.get_pending_radio_reports().is_empty() and d.get_radio_report(report_id).cancellation_reason=="hit_stagger")
	d=fresh()
	queue(d,visual(d))
	d.clear()
	d.advance(4)
	check("clear removes queue history actors knowledge and time",d.get_pending_radio_reports().is_empty() and d.get_delivered_knowledge_for("b").is_empty() and d.get_radio_report(1).is_empty() and d.get_simulation_time()==0)
	d.initialize_for_mission("new",12)
	d.sync_radio_actors(actors())
	check("new attempt does not retain old evidence",d.get_delivered_knowledge_for("b").is_empty() and d.get_pending_radio_reports().is_empty())
	check("ordered replay yields identical reports and knowledge",replay()==replay())
	d=fresh()
	var original_id:=visual(d)
	queue(d,original_id, ["b"],.01)
	d.advance(.01)
	for index in 40:
		queue(d,visual(d),["b"],.01)
		d.advance(.01)
	check("dedup outlives bounded knowledge history while source remains active",d.get_delivered_knowledge_for("b").size()==32 and queue(d,original_id)==0)
	d=fresh()
	var weak_director:WeakRef=weakref(d)
	d.radio_report_changed.connect(func(report:Dictionary):
		if report.status=="delivered": weak_director.get_ref().clear())
	queue(d,visual(d))
	d.advance(1.4)
	check("clear during completion callback cannot repopulate old attempt knowledge",d.get_attempt_id()==0 and d.get_delivered_knowledge_for("b").is_empty() and d.get_radio_history().is_empty())
	d=fresh()
	weak_director=weakref(d)
	queue(d,visual(d))
	var second:int=d.record_observation("c","visual_contact",Vector3.ONE,1,8)
	d.queue_radio_report("c",second,["b"],1.4)
	d.radio_report_changed.connect(func(report:Dictionary):
		if report.id==1 and report.status=="delivered": weak_director.get_ref().cancel_radio_report(2,"hit_stagger"))
	d.advance(1.4)
	check("cancellation during another completion prevents same-tick delivery",d.get_radio_report(2).status=="cancelled" and d.get_delivered_knowledge_for("b").size()==1)
	d=fresh()
	var many:Dictionary={}
	for index in 40:
		many["s%02d" % index]={"position":Vector3.ZERO,"alive":true,"interrupted":false}
	many["target"]={"position":Vector3.ONE,"alive":true,"interrupted":false}
	d.sync_radio_actors(many)
	for index in 40:
		var sender:="s%02d" % index
		var observation:int=d.record_observation(sender,"visual_contact",Vector3.ONE,1,8)
		d.queue_radio_report(sender,observation,["target"],1.4)
	check("pending queue is separately bounded",d.get_pending_radio_reports().size()==Director.MAX_PENDING_REPORTS)
	d.advance(1.4)
	for index in 150:
		var observation:int=d.record_observation("s00","visual_contact",Vector3.ONE,1,8)
		d.queue_radio_report("s00",observation,["target"],.01)
		d.advance(.01)
	check("observations knowledge and terminal history stay bounded",d.get_active_observations().size()<=128 and d.get_delivered_knowledge_for("target").size()<=Director.MAX_KNOWLEDGE_PER_GUARD and d.get_radio_history().size()<=Director.MAX_RADIO_HISTORY)
	print("SECURITY RADIO: %d/%d passed; failures=%d" % [checks-failures,checks,failures])
	quit(1 if failures else 0)
