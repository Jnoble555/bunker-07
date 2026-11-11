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
	weapon = Node3D.new()
	camera.add_child(weapon)
	weapon.position = Vector3(0.18, -0.25, -0.43)
	_add_weapon_box(Vector3(0.14, 0.17, 0.38), Vector3.ZERO, Color("4d5a44"))
	_add_weapon_box(Vector3(0.07, 0.08, 0.28), Vector3(0, 0.055, -0.19), Color("9a9d7b"))
	_add_weapon_box(Vector3(0.045, 0.09, 0.035), Vector3(0, 0.10, -0.27), Color("202d25"))
	_add_weapon_box(Vector3(0.08, 0.17, 0.10), Vector3(0, -0.14, 0.08), Color("202d25"))
	_add_weapon_box(Vector3(0.09, 0.10, 0.20), Vector3(-0.12, -0.08, 0.12), Color("737457"))
	muzzle = _add_weapon_box(Vector3(0.10, 0.10, 0.06), Vector3(0, 0.055, -0.36), Color("ffce72"))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffe0a0")
	glow.emission_enabled = true
	glow.emission = Color("ffc564")
	glow.emission_energy_multiplier = 3.0
	glow.no_depth_test = true
	glow.render_priority = 100
	muzzle.material_override = glow
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0, 0.055, -0.35)
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
	material.no_depth_test = true
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
		weapon.position = Vector3(0.18, -0.25, -0.43)
		muzzle.visible = false
		muzzle_light.light_energy = 0

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
	# A .8s reload lowers then restores the weapon; pause freezes this pose.
	var reload_offset: float = 0.0
	if controller.reload_remaining > 0:
		var progress: float = 1.0 - controller.reload_remaining / 0.8
		reload_offset = (progress / 0.25 if progress < 0.25 else (1.0 - progress) / 0.75) * 0.24
	var sway: float = sin(controller.elapsed * 10) * 0.012 if input.length() > 0 else 0.0
	weapon.position = Vector3(0.18 + sway, -0.25 - reload_offset, -0.43 + controller.flash * 0.8)
	muzzle.visible = controller.flash > 0
	muzzle_light.light_energy = 1.3 if controller.flash > 0 else 0.0
