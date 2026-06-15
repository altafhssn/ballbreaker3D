extends CharacterBody3D
## Ball — 3D. Sphere on the XZ play plane (Y constant). Constant-speed reflect.
## All ball motion lives in the XZ plane; Y is held at BALL_Y for a clean
## camera-perspective look without true vertical bouncing.

signal hit_brick(brick: Node)
signal lost

const RADIUS := 0.18
const BALL_Y := 0.0
const BASE_SPEED := 9.0           # m/s (tuned for 1080×1920 portrait camera)
const SPEED_PER_LEVEL := 0.45
const SPEED_CAP_BONUS := 5.4
const LAUNCH_DELAY := 2.0
const FIRE_PUSH := 0.45           # m to push ball past brick in fireball mode
const STUCK_RATIO := 6.0
const STUCK_NUDGE_TIME := 1.2
const STUCK_NUDGE_2 := 2.5
const STUCK_AUTO_LOSE := 5.0
# Cyan plasma core; magenta-shift when overcharged (fire power-up).
const NORMAL_COLOR := Color("#9be7ff")
const FIRE_COLOR := Color("#ff4ad0")

var speed: float = BASE_SPEED
var launched: bool = false
var fire_active: bool = false
var _launch_timer: float = 0.0
var _stuck_timer: float = 0.0
var _stuck_nudged_once: bool = false
var _paddle: Node3D = null

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shape: CollisionShape3D = $Collision
var _glow_light: OmniLight3D = null
var _trail: CPUParticles3D = null

func _ready() -> void:
	add_to_group("ball")
	collision_layer = 0b000001   # Ball (1)
	collision_mask  = 0b101110   # Paddle (2), Walls (3), Bricks (4), KillZone (6)
	_build_visual()
	# Halo so the ball is always findable, even if it clips somewhere it
	# shouldn't be.
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = NORMAL_COLOR
	_glow_light.light_energy = 1.8
	_glow_light.omni_range = 2.5
	_glow_light.omni_attenuation = 1.4
	add_child(_glow_light)
	_build_trail()
	speed = BASE_SPEED + SPEED_PER_LEVEL * (GameState.level - 1)
	speed = min(speed, BASE_SPEED + SPEED_CAP_BONUS)

func _build_trail() -> void:
	# Soft plasma wake: additive, emissive, shrinking as it fades — reads as
	# a light streak rather than a chain of beads.
	_trail = CPUParticles3D.new()
	_trail.amount = 24
	_trail.lifetime = 0.22
	_trail.local_coords = false
	_trail.emitting = true
	_trail.spread = 0.0
	_trail.gravity = Vector3.ZERO
	_trail.initial_velocity_min = 0.0
	_trail.initial_velocity_max = 0.0
	# Shrink over lifetime.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.05))
	_trail.scale_amount_curve = curve
	_trail.scale_amount_min = 0.9
	_trail.scale_amount_max = 0.9
	var sm := SphereMesh.new()
	sm.radius = RADIUS * 0.8
	sm.height = RADIUS * 1.6
	sm.radial_segments = 8
	sm.rings = 4
	# Additive emissive material driven by the particle vertex colour — this
	# is what was missing before (particles rendered as unlit grey beads).
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.vertex_color_use_as_albedo = true
	sm.material = mat
	_trail.mesh = sm
	_refresh_trail_color()
	add_child(_trail)

func _refresh_trail_color() -> void:
	if not _trail:
		return
	var c = FIRE_COLOR if fire_active else NORMAL_COLOR
	var grad := Gradient.new()
	grad.set_color(0, Color(c.r, c.g, c.b, 0.5))
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	_trail.color_ramp = grad

func _build_visual() -> void:
	var sm := SphereMesh.new()
	sm.radius = RADIUS
	sm.height = RADIUS * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	_mesh.mesh = sm
	_apply_material()
	var s := SphereShape3D.new()
	s.radius = RADIUS
	_shape.shape = s

func _apply_material() -> void:
	var mat := StandardMaterial3D.new()
	var c = FIRE_COLOR if fire_active else NORMAL_COLOR
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	# Strong glow — gives the plasma-streaking-through-space look.
	mat.emission_energy_multiplier = 3.0 if fire_active else 2.2
	mat.metallic = 0.0
	mat.roughness = 0.35
	_mesh.material_override = mat
	if _glow_light:
		_glow_light.light_color = c

func attach_to_paddle(paddle: Node3D) -> void:
	_paddle = paddle
	launched = false
	_launch_timer = 0.0
	position = Vector3(paddle.position.x, BALL_Y, paddle.position.z - 0.6)

func launch_with_velocity(v: Vector3) -> void:
	## For Multiball spawn. Caller supplies a direction; we normalize × speed.
	var d := v
	d.y = 0.0
	if d.length() < 0.01:
		d = Vector3(0, 0, -1)
	velocity = d.normalized() * speed
	launched = true

func set_fire(active: bool) -> void:
	fire_active = active
	_apply_material()
	_refresh_trail_color()

func _physics_process(delta: float) -> void:
	position.y = BALL_Y
	# Safety bounds. If the ball has somehow tunneled through a wall, recover
	# by treating it as lost — better than leaving an invisible ball in play.
	if abs(position.x) > 7.0 or position.z < -12.0 or position.z > 12.0:
		emit_signal("lost")
		return
	if not launched:
		_launch_timer += delta
		if _paddle:
			position.x = _paddle.position.x
			position.z = _paddle.position.z - 0.6
		if _launch_timer >= LAUNCH_DELAY:
			# Auto-launch: 15° off straight-toward-bricks (-Z), randomised L/R.
			var dir: float = 1.0 if randi() % 2 == 0 else -1.0
			var a := deg_to_rad(15.0) * dir
			velocity = Vector3(sin(a), 0.0, -cos(a)) * speed
			launched = true
		return

	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		var normal := collision.get_normal()
		# Project normal to XZ (just in case).
		normal.y = 0.0
		if normal.length() < 0.01:
			normal = Vector3(0, 0, 1)
		else:
			normal = normal.normalized()
		if collider.is_in_group("paddle"):
			velocity = collider.reflect_velocity(position.x, speed)
			Sfx.play_varied("paddle_hit")
			if collider.has_method("pulse"):
				collider.pulse()
		elif collider.is_in_group("brick"):
			emit_signal("hit_brick", collider)
			if not fire_active:
				velocity = velocity.bounce(normal)
			else:
				# Fireball: pass through. Push the ball just past the brick so
				# we don't re-collide on the next physics tick before queue_free
				# has actually removed the destroyed brick from the tree.
				# Clamp inside the field so an edge-column brick can't shove
				# the ball into / past a side or back wall.
				if velocity.length() > 0.01:
					position += velocity.normalized() * FIRE_PUSH
					position.x = clamp(position.x, -5.4 + RADIUS, 5.4 - RADIUS)
					position.z = clamp(position.z, -9.6 + RADIUS, 9.6 - RADIUS)
		elif collider.is_in_group("killzone"):
			emit_signal("lost")
			return
		else:
			velocity = velocity.bounce(normal)
			Sfx.play_varied("wall_hit", -6.0)
		velocity.y = 0.0
		velocity = velocity.normalized() * speed
	_apply_anti_stuck(delta)

func _apply_anti_stuck(delta: float) -> void:
	# We want a healthy Z component (forward/back motion). If the ball goes
	# almost purely sideways, nudge it.
	if abs(velocity.z) < 0.001:
		_stuck_timer += delta
	else:
		var ratio: float = abs(velocity.x) / max(abs(velocity.z), 0.001)
		if ratio > STUCK_RATIO:
			_stuck_timer += delta
		else:
			_stuck_timer = 0.0
			_stuck_nudged_once = false

	if _stuck_timer >= STUCK_AUTO_LOSE:
		emit_signal("lost")
		return
	if _stuck_timer >= STUCK_NUDGE_2 and _stuck_nudged_once:
		velocity = velocity.rotated(Vector3.UP, deg_to_rad(30.0))
	elif _stuck_timer >= STUCK_NUDGE_TIME and not _stuck_nudged_once:
		velocity = velocity.rotated(Vector3.UP, deg_to_rad(15.0))
		_stuck_nudged_once = true
