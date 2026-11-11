extends CharacterBody3D
## Flat movement and yaw-only aim intentionally match the browser reference.

const SPEED: float = 5.3
var controller: Node
var camera: Camera3D
var weapon: Node3D
var muzzle: MeshInstance3D
var muzzle_light: OmniLight3D

func setup(owner_controller: Node) -> void:
	controller = owner_controller
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	safe_margin = 0.002
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.4
	camera.fov = rad_to_deg(2 * atan(0.68))
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.near = 0.04
	camera.current = true
	add_child(camera)
	weapon = preload("res://scenes/security_sidearm.tscn").instantiate()
	_make_weapon_view(weapon)
	weapon.scale = Vector3.ONE * 0.65
	weapon.position = Vector3(0.14, -0.07, -0.65)
	muzzle = _add_weapon_box(Vector3(0.10, 0.10, 0.06), Vector3(0, 0.055, -0.20), Color("ffce72"))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffe0a0")
	glow.emission_enabled = true
	glow.emission = Color("ffc564")
	glow.emission_energy_multiplier = 3.0
	glow.no_depth_test = false
	glow.render_priority = 100
	muzzle.material_override = glow
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0, 0.055, -0.20)
	muzzle_light.light_color = Color("ffc577")
	muzzle_light.omni_range = 3.5
	muzzle_light.light_energy = 0
	weapon.add_child(muzzle_light)
	muzzle.visible = false
	reset_player()

func _add_weapon_box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	# Viewmodel overlays the world like the reference weapon; it is never a collider.
	material.no_depth_test = false
	material.render_priority = 100
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	weapon.add_child(instance)
	return instance

func reset_player() -> void:
	position = Vector3(3, 0, 17)
	rotation = Vector3(0, -PI / 2, 0)
	velocity = Vector3.ZERO
	if weapon:
		weapon.position = Vector3(0.14, -0.07, -0.65)
		muzzle.visible = false
		muzzle_light.light_energy = 0
		weapon.pose(0, 0)

func _unhandled_input(event: InputEvent) -> void:
	if not controller or not controller.active or get_tree().paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * float(controller.session.preferences.sensitivity))
		if event.relative.x != 0: controller.progress_tutorial("aim")

func _physics_process(delta: float) -> void:
	if not controller or not controller.active:
		velocity = Vector3.ZERO
		return
	rotate_y((Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")) * 2.1 * delta)
	var input := Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	var direction := global_basis * Vector3(input.x, 0, input.y)
	velocity = direction * SPEED
	move_and_slide()
	# Raise the sidearm during the existing .8s reload so the magazine stays visible.
	var reload_offset: float = 0.0
	if controller.reload_remaining > 0:
		var progress: float = 1.0 - controller.reload_remaining / 0.8
		reload_offset = (progress / 0.25 if progress < 0.25 else (1.0 - progress) / 0.75) * -0.07
	var sway: float = sin(controller.elapsed * 10) * 0.012 if input.length() > 0 else 0.0
	weapon.position = Vector3(0.14 + sway, -0.07 - reload_offset, -0.65 + controller.flash * 0.8)
	weapon.pose(controller.flash, controller.reload_remaining)
	muzzle.visible = controller.flash > 0
	muzzle_light.light_energy = 1.3 if controller.flash > 0 else 0.0

func _make_weapon_view(model: Node3D) -> void:
	# Separate depth buffer prevents world-wall clipping without breaking self-occlusion.
	var viewport := SubViewport.new()
	viewport.name = "WeaponViewport"
	viewport.size = Vector2i(1280, 720)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var view_camera := Camera3D.new()
	view_camera.fov = camera.fov
	view_camera.keep_aspect = camera.keep_aspect
	view_camera.near = 0.02
	viewport.add_child(view_camera)
	view_camera.current = true
	view_camera.add_child(model)
	var environment := WorldEnvironment.new()
	var lighting := Environment.new()
	lighting.background_mode = Environment.BG_CLEAR_COLOR
	lighting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.ambient_light_color = Color("c0c7c2")
	lighting.ambient_light_energy = 0.65
	environment.environment = lighting
	viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 0.85
	viewport.add_child(key)
	var overlay := CanvasLayer.new()
	overlay.layer = 0
	add_child(overlay)
	var image := TextureRect.new()
	image.texture = viewport.get_texture()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.add_child(image)
