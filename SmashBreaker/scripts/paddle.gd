extends CharacterBody3D
## Paddle — 3D. Capsule on the XZ ground plane. Follows touch / mouse X.
## Coordinate system for the whole game:
##   X = horizontal (left/right). Field spans [-FIELD_HALF_W, +FIELD_HALF_W].
##   Y = world up. Gameplay all happens at Y ≈ 0; meshes have visible height.
##   Z = depth. +Z is toward the camera (= "down" on screen).
##       Paddle sits at +PADDLE_Z, bricks live in negative Z.

const FIELD_HALF_W := 5.4
const DEFAULT_WIDTH_UNITS := 3.24    # 30% of field width (10.8)
const HEIGHT := 0.4
const DEPTH := 0.7
const PADDLE_Z := 8.0
const KEYBOARD_SPEED := 12.0         # m/s for arrow-key control

var base_width: float = DEFAULT_WIDTH_UNITS
var current_width: float = base_width
var wide_scale: float = 1.0
# Skin colours — loaded from the equipped skin in _ready.
var body_color: Color = Color("#23365e")
var glow_color: Color = Color("#4ad0ff")
# Frost Reach mechanic: when true, the paddle has momentum and slides — it
# chases the target instead of snapping to it.
var slide_mode: bool = false
var _slide_target_x: float = 0.0
var _slide_vel: float = 0.0
const SLIDE_SPRING := 38.0     # acceleration toward target
const SLIDE_DAMPING := 4.5     # lower = more slide / overshoot

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shape: CollisionShape3D = $Collision
var _glow_light: OmniLight3D = null
var _pulse_tween: Tween = null

func _ready() -> void:
	add_to_group("paddle")
	collision_layer = 0b000010   # Paddle (2)
	collision_mask  = 0b010000   # Catches PowerUps (5)
	position = Vector3(0.0, 0.0, PADDLE_Z)
	body_color = Skins.body_color(GameState.selected_skin)
	glow_color = Skins.glow_color(GameState.selected_skin)
	# Floor halo — small omni light just below the paddle so the player always
	# sees a glow puddle on the grid where their ship is.
	_glow_light = OmniLight3D.new()
	_glow_light.position = Vector3(0.0, -0.05, 0.0)
	_glow_light.light_color = glow_color
	_glow_light.light_energy = 1.6
	_glow_light.omni_range = 3.0
	_glow_light.omni_attenuation = 1.5
	add_child(_glow_light)
	_apply_width()

func pulse() -> void:
	## Quick squash-and-recover on ball impact. Pure feel, no gameplay effect.
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	scale = Vector3(1.0, 1.0, 1.0)
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "scale", Vector3(1.06, 1.35, 0.92), 0.05) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "scale", Vector3.ONE, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(_dt: float) -> void:
	# Keyboard fallback. Mouse / touch handled in _input so the paddle
	# doesn't snap to wherever the cursor happens to sit before the player
	# has actually engaged.
	if Input.is_action_pressed("ui_left"):
		_set_target(position.x - KEYBOARD_SPEED * _dt)
		if not slide_mode:
			position.x = _slide_target_x
	elif Input.is_action_pressed("ui_right"):
		_set_target(position.x + KEYBOARD_SPEED * _dt)
		if not slide_mode:
			position.x = _slide_target_x
	# Ice physics: spring-damper chase. The paddle drifts past the target a
	# touch and eases back — precision becomes the skill of the galaxy.
	if slide_mode:
		var dt: float = _dt
		_slide_vel += (_slide_target_x - position.x) * SLIDE_SPRING * dt
		_slide_vel *= exp(-SLIDE_DAMPING * dt)
		position.x += _slide_vel * dt
	var half := current_width * 0.5
	position.x = clamp(position.x, -FIELD_HALF_W + half, FIELD_HALF_W - half)

func _set_target(x: float) -> void:
	var half := current_width * 0.5
	_slide_target_x = clamp(x, -FIELD_HALF_W + half, FIELD_HALF_W - half)

func _input(event: InputEvent) -> void:
	var screen_pos := Vector2(-1, -1)
	if event is InputEventScreenDrag:
		screen_pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		screen_pos = event.position
	elif event is InputEventMouseMotion:
		# Desktop: follow on any mouse move.
		screen_pos = event.position
	if screen_pos.x < 0.0:
		return
	# Project the cursor into the world and intersect with the play plane
	# (Y = 0). The paddle's X is then exactly where the cursor points on the
	# court — perspective-correct, so the paddle reaches the walls when the
	# cursor does.
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var origin := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if abs(dir.y) < 0.0001:
		return
	var t := -origin.y / dir.y
	if t < 0.0:
		return
	var hit := origin + dir * t
	_set_target(hit.x)
	if not slide_mode:
		position.x = _slide_target_x

func set_wide(active: bool) -> void:
	wide_scale = 2.0 if active else 1.0
	_apply_width()

func _apply_width() -> void:
	current_width = base_width * wide_scale

	# Body: a capsule lying along X with a slight vertical flatten, so it reads
	# as a stadium-shape interceptor / paddle from above.
	var cap := CapsuleMesh.new()
	cap.radius = DEPTH * 0.5
	cap.height = current_width
	cap.radial_segments = 24
	cap.rings = 6
	_mesh.mesh = cap
	# Rotate so the capsule axis lies along X, then flatten vertically.
	# NOTE: Basis.scaled() is a GLOBAL scale (applied after rotation), so the
	# flatten axis must be world-Y. Scaling world-X here would compress the
	# paddle's *length* and make the visual narrower than the collision box.
	_mesh.transform = Transform3D(
		Basis(Vector3(0, 0, 1), PI * 0.5).scaled(Vector3(1.0, 0.55, 1.0)),
		Vector3.ZERO
	)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body_mat.emission_enabled = true
	body_mat.emission = glow_color
	body_mat.emission_energy_multiplier = 0.7
	body_mat.metallic = 0.75
	body_mat.roughness = 0.3
	_mesh.material_override = body_mat

	# Collision: thin box matching the visible capsule footprint.
	# Visible Y radius after flatten = DEPTH * 0.5 * 0.55 ≈ 0.19.
	# Visible Z extent = capsule diameter = DEPTH.
	var sh := BoxShape3D.new()
	sh.size = Vector3(current_width, DEPTH * 0.5 * 0.55 * 2.0 + 0.04, DEPTH)
	_shape.shape = sh

func get_half_width() -> float:
	return current_width * 0.5

func reflect_velocity(ball_x: float, speed: float) -> Vector3:
	## GDD §1 reflection formula, applied in the XZ plane.
	## After bouncing off the paddle, the ball travels toward -Z (toward bricks).
	var hw := get_half_width()
	var norm: float = clamp((ball_x - position.x) / hw, -1.0, 1.0)
	var angle: float = deg_to_rad(norm * 60.0)
	return Vector3(sin(angle), 0.0, -cos(angle)) * speed
