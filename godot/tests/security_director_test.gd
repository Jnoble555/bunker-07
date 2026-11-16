extends SceneTree
const Director = preload("res://scripts/security_director.gd")
var checks := 0
var failures := 0
var telemetry: Array = []

func _initialize() -> void: call_deferred("run")
func check(label: String, ok: bool) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func record(d: RefCounted, kind: String = "visual_contact", confidence: float = 1.0, at: Vector3 = Vector3.ONE, ttl: float = 2.0) -> int:
	return d.record_observation("guard-a", kind, at, confidence, ttl)
func replay() -> Array[Dictionary]:
	var d = Director.new()
	d.initialize_for_mission("replay")
	record(d)
	d.advance(.25)
	record(d,"sound_contact",.6,Vector3(2,0,3),1.0)
	d.advance(.5)
	return d.get_active_observations()
func run() -> void:
	var d = Director.new()
	d.telemetry_event.connect(func(event: String, detail: Dictionary): telemetry.append([event,detail]))
	check("uninitialized recorder rejects events",record(d)==0)
	d.initialize_for_mission("deep-signal")
	check("initialize starts empty",d.get_active_observations().is_empty())
	check("clock starts zero",d.get_simulation_time()==0)
	d.advance(.25)
	d.advance(.5)
	check("explicit deltas advance simulation clock",d.get_simulation_time()==.75)
	var t: float = d.get_simulation_time()
	for delta in [-1.0,0.0,INF,NAN]: d.advance(delta)
	check("invalid time updates ignored",d.get_simulation_time()==t)
	check("first observation id is one",record(d)==1)
	check("ids increment",record(d,"sound_contact",.6)==2)
	var observations: Array[Dictionary] = d.get_active_observations()
	check("records contain explicit timestamps and kinds",observations.size()==2 and observations[0].created_at==.75 and observations[0].expires_at==2.75 and observations[1].kind=="sound_contact")
	check("unknown kind rejected",record(d,"omniscient")==0)
	check("invalid confidences rejected",record(d,"visual_contact",-.1)==0 and record(d,"visual_contact",1.1)==0 and record(d,"visual_contact",NAN)==0 and record(d,"visual_contact",INF)==0)
	check("nonfinite positions rejected",record(d,"visual_contact",1,Vector3.INF)==0 and record(d,"visual_contact",1,Vector3(NAN,0,0))==0)
	check("nonpositive or infinite lifetime rejected",record(d,"visual_contact",1,Vector3.ZERO,0)==0 and record(d,"visual_contact",1,Vector3.ZERO,-1)==0 and record(d,"visual_contact",1,Vector3.ZERO,INF)==0)
	check("empty observer rejected",d.record_observation("","visual_contact",Vector3.ZERO,1,1)==0)
	check("invalid inputs do not consume identifiers",record(d,"visual_lost")==3)
	var metadata := {"source":"shot", "count":1}
	check("flat bounded diagnostic metadata accepted",d.record_observation("guard-b","sound_contact",Vector3.ZERO,0,1,"security",metadata)==4)
	metadata.source="tampered"
	var mine: Array[Dictionary] = d.get_observations_for("guard-b")
	mine[0].position=Vector3(999,999,999)
	mine[0].metadata.source="changed"
	mine.clear()
	observations[0].observer_id="changed"
	observations.clear()
	var original: Dictionary = d.get_observations_for("guard-b")[0]
	check("input metadata and both query types are detached",original.position==Vector3.ZERO and original.metadata.source=="shot" and d.get_observations_for("guard-a").size()==3)
	check("unknown observer query is empty",d.get_observations_for("missing").is_empty())
	var object := RefCounted.new()
	check("metadata cannot retain live objects or nested containers",d.record_observation("a","sound_contact",Vector3.ZERO,1,1,"",{"actor":object})==0 and d.record_observation("a","sound_contact",Vector3.ZERO,1,1,"",{"nested":{"actor":object}})==0)
	check("oversized diagnostic fields rejected",d.record_observation("a","sound_contact",Vector3.ZERO,1,1,"",{"message":"x".repeat(129)})==0)
	var oversized := {}
	for index in 9: oversized[str(index)]=index
	check("metadata entry count is bounded",d.record_observation("a","sound_contact",Vector3.ZERO,1,1,"",oversized)==0)
	d.advance(1)
	check("expiry happens at exact deadline",d.get_observations_for("guard-b").is_empty() and d.get_active_observations().size()==3)
	d.advance(1)
	check("all query types exclude expired records",d.get_active_observations().is_empty() and d.get_observations_for("guard-a").is_empty())
	check("expiry telemetry identifies observation and simulation time",telemetry.any(func(row): return row[0]=="security_observation_expired" and row[1].id==4 and row[1].simulation_time==1.75))
	d.clear()
	check("clear resets clock mission and storage",d.get_simulation_time()==0 and d.get_mission_id()=="" and d.get_active_observations().is_empty() and record(d)==0)
	d.initialize_for_mission("bounded")
	for index in 1000: record(d)
	var bounded: Array[Dictionary] = d.get_active_observations()
	check("1000 events retain only newest 128 in insertion order",bounded.size()==128 and bounded[0].id==873 and bounded[-1].id==1000)
	check("capacity eviction emits explicit reason",telemetry.any(func(row): return row[0]=="security_observation_expired" and row[1].get("reason")=="capacity"))
	d.initialize_for_mission("new-mission")
	check("reinitialize clears prior mission and resets ids",d.get_mission_id()=="new-mission" and d.get_simulation_time()==0 and d.get_active_observations().is_empty() and record(d)==1)
	check("equal update/input sequences yield equal records",replay()==replay())
	d.advance(1e30)
	check("unrepresentable positive expiry is rejected",record(d)==0 and d.get_active_observations().is_empty())
	d.initialize_for_mission("")
	check("invalid mission leaves recorder inactive",d.get_mission_id()=="" and record(d)==0)
	d.initialize_for_mission("attempt",99)
	check("explicit mission attempt identity is retained",d.get_attempt_id()==99)
	d.clear()
	check("clear removes radio attempt identity too",d.get_attempt_id()==0 and d.get_pending_radio_reports().is_empty() and d.get_radio_history().is_empty())
	print("SECURITY DIRECTOR: %d/%d passed; failures=%d" % [checks-failures,checks,failures])
	quit(1 if failures else 0)
