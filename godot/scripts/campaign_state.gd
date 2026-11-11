extends RefCounted
## Native preferences persist; campaign consequences and analytics remain session-scoped.
const DEFAULTS := {"volume":0.65,"muted":false,"sensitivity":0.003}
var preferences: Dictionary = DEFAULTS.duplicate()
var tutorial_seen: bool = false
var decisions: Dictionary = {}
var summaries: Dictionary = {}
var retries: Dictionary = {}
var journal: Array[String] = []
var committed_journal: Array[String] = []

func _init() -> void:
	load_preferences()
	new_campaign()

func new_campaign() -> void:
	decisions = {"security_disabled":false,"alarm_raised":false,"intel":false,"secret":false}
	summaries.clear()
	retries = {"breach":0,"control-room":0,"blackout":0}
	journal.clear()
	committed_journal.clear()

func begin_attempt() -> void:
	journal = committed_journal.duplicate()

func note(text: String) -> void:
	if not journal.has(text): journal.append(text)

func rank_for(mission: Dictionary, state: Dictionary) -> Dictionary:
	var accuracy: int = roundi(float(state.hits) / state.shots * 100) if state.shots > 0 else 100
	var clean: bool = not state.alarm_triggered if mission.id == "control-room" else state.health == 100
	var points: int = (2 if clean else 0) + (1 if state.elapsed < 120 else 0) + (1 if accuracy >= 60 else 0) + (1 if state.intel else 0) + (1 if state.secret else 0)
	return {"grade":"S" if points >= 5 else "A" if points >= 4 else "B" if points >= 2 else "C", "accuracy":accuracy,"stealth":clean}

func commit(mission: Dictionary, state: Dictionary, won: bool) -> Dictionary:
	if not won: return {}
	var result: Dictionary = {"time":state.elapsed,"accuracy":rank_for(mission,state).accuracy,"rank":rank_for(mission,state),"intel":state.intel,"secret":state.secret,"retries":retries.get(mission.id,0)}
	summaries[mission.id] = result
	for entry in journal:
		if not committed_journal.has(entry): committed_journal.append(entry)
	if mission.id == "control-room":
		decisions = {"security_disabled":state.panel_disabled and not state.alarm_triggered,"alarm_raised":state.alarm_triggered,"intel":state.intel,"secret":state.secret}
	return result

func load_preferences() -> void:
	var config := ConfigFile.new()
	preferences = DEFAULTS.duplicate()
	if config.load("user://bunker07-preferences.cfg") != OK: return
	for key in ["volume","sensitivity"]:
		var value: Variant = config.get_value("preferences",key,DEFAULTS[key])
		if (value is float or value is int) and is_finite(float(value)):
			preferences[key] = clampf(float(value),0.0 if key=="volume" else 0.0005,1.0 if key=="volume" else 0.01)
	var mute: Variant = config.get_value("preferences","muted",false)
	preferences.muted = mute if mute is bool else false
	tutorial_seen = bool(config.get_value("onboarding","seen",false))

func save_preferences() -> Error:
	var config := ConfigFile.new()
	for key in preferences: config.set_value("preferences",key,preferences[key])
	config.set_value("onboarding","seen",tutorial_seen)
	return config.save("user://bunker07-preferences.cfg")

func csv_text(events: Array) -> String:
	var rows: PackedStringArray = ["run,elapsed_seconds,event,bot_id,health,ammo,shots,hits,detail,mission_id"]
	for event: Dictionary in events:
		var fields: PackedStringArray = []
		for key in ["run","elapsed_seconds","event","bot_id","health","ammo","shots","hits","detail","mission_id"]:
			var value := str(event.get(key,""))
			if value.contains(",") or value.contains('"') or value.contains("\n") or value.contains("\r"):
				value = '"' + value.replace('"','""') + '"'
			fields.append(value)
		rows.append(",".join(fields))
	return "\r\n".join(rows)
