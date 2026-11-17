extends "res://scripts/campaign_main.gd"
## Playable opt-in art benchmark. Core encounter/controller remains the campaign's.
const Art = preload("res://scripts/control_room_art.gd")
var baseline := false
var art: Node3D

func _ready() -> void:
	baseline = "--benchmark-baseline" in OS.get_cmdline_user_args()
	operation_mode = true
	missions = [OperationData.definition()]
	mission_index = 0
	session.retries["tactical-operation"] = 0
	super._ready()
	if not baseline:
		_style_hud()
		if RenderingServer.get_current_rendering_method() == "forward_plus":
			get_viewport().msaa_3d = Viewport.MSAA_2X
			player.get_node("WeaponViewport").msaa_3d = Viewport.MSAA_2X
	start_run()
	tutorial_active = false
	announce("DEEP SIGNAL / VISUAL BENCHMARK / F5 retry / P pause")

func _load_mission() -> void:
	art = null
	super._load_mission()
	if operation_mode and not baseline:
		art = Art.new()
		art.name = "ControlRoomArt"
		room.add_child(art)
		art.apply(room)

func new_campaign() -> void:
	new_operation()

func show_title() -> void:
	super.show_title()
	campaign_button.text = "Restart visual benchmark"
	operation_button.hide()
	deep_signal_button.hide()

func _update_hud() -> void:
	super._update_hud()
	if not hud or not operation_mode or baseline: return
	hud.text = "DEEP SIGNAL     |     HEALTH %03d     |     %s  %02d / %02d   +%d" % [health,get_weapon_def().name,ammo,get_weapon_def().capacity,weapon_ammo.get(weapon_id,{}).get("reserve",0)]
	tutorial_text.hide()

func _style_hud() -> void:
	hud.position = Vector2(24,664)
	hud.add_theme_font_size_override("font_size",18)
	status.position = Vector2(24,24)
	status.add_theme_font_size_override("font_size",17)
	feedback.position = Vector2(24,624)
	feedback.add_theme_font_size_override("font_size",17)
