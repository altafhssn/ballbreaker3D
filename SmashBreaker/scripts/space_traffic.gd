extends Node3D
## SpaceTraffic — ambient life in the void behind the arena: greebled patrol
## ships with engine exhaust and blinking nav strobes, and cargo freighters
## with running lights. Pure set-dressing; everything lives behind the back
## bulkhead and despawns offscreen.

var accent: Color = Color("#4ad0ff")

const SPAWN_MIN := 4.0
const SPAWN_MAX := 9.0
const KILL_X := 34.0

var _spawn_timer: float = 2.0
var _movers: Array = []   # { node, velocity }

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(SPAWN_MIN, SPAWN_MAX)
		if randf() < 0.65:
			_spawn_ship()
		else:
			_spawn_freighter()
	for m in _movers.duplicate():
		var node: Node3D = m["node"]
		if not is_instance_valid(node):
			_movers.erase(m)
			continue
		node.position += m["velocity"] * delta
		if abs(node.position.x) > KILL_X:
			node.queue_free()
			_movers.erase(m)

# --- Shared builders -----------------------------------------------------------

func _register(node: Node3D, velocity: Vector3) -> void:
	add_child(node)
	_movers.append({"node": node, "velocity": velocity})

func _emissive_mat(c: Color, energy: float, metallic: float = 0.0, rough: float = 0.4) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(c.r, c.g, c.b)
		mat.emission_energy_multiplier = energy
	mat.metallic = metallic
	mat.roughness = rough
	return mat

func _box(size: Vector3, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	return mi

func _sphere(radius: float, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 8
	sm.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	return mi

func _strobe(parent: Node3D, pos: Vector3, c: Color, period: float) -> void:
	## Blinking navigation light: tween the emission energy up and down.
	var mat := _emissive_mat(c, 0.2)
	var light := _sphere(0.045, mat, pos)
	parent.add_child(light)
	var tw := light.create_tween().set_loops()
	tw.tween_property(mat, "emission_energy_multiplier", 4.0, 0.08)
	tw.tween_property(mat, "emission_energy_multiplier", 0.2, 0.25)
	tw.tween_interval(period)

func _exhaust(parent: Node3D, pos: Vector3, c: Color, size: float, dir: Vector3) -> void:
	## Engine exhaust: short additive cone of particles blowing backwards.
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = 14
	p.lifetime = 0.35
	p.local_coords = true
	p.emitting = true
	p.direction = dir
	p.spread = 8.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 3.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.1))
	p.scale_amount_curve = curve
	var sm := SphereMesh.new()
	sm.radius = size
	sm.height = size * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.vertex_color_use_as_albedo = true
	sm.material = pm
	p.mesh = sm
	var grad := Gradient.new()
	grad.set_color(0, Color(c.r, c.g, c.b, 0.6))
	grad.set_color(1, Color(c.r, c.g, c.b, 0.0))
	p.color_ramp = grad
	parent.add_child(p)

func _bob(body: Node3D, amp: float, period: float) -> void:
	## Gentle vertical float so ships don't feel rail-mounted.
	var tw := body.create_tween().set_loops()
	tw.tween_property(body, "position:y", amp, period) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(body, "position:y", -amp, period) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# --- Patrol ship ------------------------------------------------------------------

func _spawn_ship() -> void:
	var dir: float = 1.0 if randi() % 2 == 0 else -1.0
	var root := Node3D.new()
	root.position = Vector3(
		-dir * randf_range(24.0, 30.0),
		randf_range(4.0, 10.0),
		randf_range(-24.0, -13.0),
	)
	var body := Node3D.new()
	root.add_child(body)

	var hull := _emissive_mat(Color(0.10, 0.13, 0.20), 0.18, 0.7, 0.35)
	var hull_dark := _emissive_mat(Color(0.06, 0.08, 0.13), 0.12, 0.7, 0.4)
	var panel := _emissive_mat(accent.darkened(0.35), 0.8)

	# Spine + nose taper (stepped boxes read as a hull silhouette).
	body.add_child(_box(Vector3(1.30, 0.16, 0.34), hull))
	body.add_child(_box(Vector3(0.45, 0.12, 0.26), hull, Vector3(0.80, 0.0, 0.0)))
	body.add_child(_box(Vector3(0.22, 0.08, 0.16), hull_dark, Vector3(1.10, 0.0, 0.0)))
	# Cockpit canopy: glowing slit window.
	body.add_child(_box(Vector3(0.30, 0.06, 0.18), _emissive_mat(Color(0.75, 0.92, 1.0), 1.6),
		Vector3(0.55, 0.11, 0.0)))
	# Dorsal fin + underslung pod.
	body.add_child(_box(Vector3(0.30, 0.26, 0.04), hull_dark, Vector3(-0.45, 0.18, 0.0)))
	body.add_child(_box(Vector3(0.50, 0.10, 0.16), hull_dark, Vector3(0.0, -0.12, 0.0)))
	# Swept wings with accent edge strips.
	for zdir in [-1.0, 1.0]:
		body.add_child(_box(Vector3(0.55, 0.04, 0.55), hull, Vector3(-0.30, 0.0, zdir * 0.42)))
		body.add_child(_box(Vector3(0.50, 0.05, 0.05), panel, Vector3(-0.32, 0.0, zdir * 0.70)))
	# Twin engines + exhaust.
	for zoff in [-0.14, 0.14]:
		body.add_child(_box(Vector3(0.16, 0.12, 0.12), hull_dark, Vector3(-0.72, 0.0, zoff)))
		body.add_child(_box(Vector3(0.06, 0.09, 0.09), _emissive_mat(accent, 3.0),
			Vector3(-0.82, 0.0, zoff)))
		_exhaust(body, Vector3(-0.90, 0.0, zoff), accent, 0.05, Vector3(-1, 0, 0))
	# Nav strobes: red port, green starboard (aviation convention).
	_strobe(body, Vector3(-0.32, 0.02, -0.72), Color(1.0, 0.25, 0.25), 1.2)
	_strobe(body, Vector3(-0.32, 0.02, 0.72), Color(0.3, 1.0, 0.4), 1.2)
	_strobe(body, Vector3(-0.45, 0.34, 0.0), Color(1.0, 1.0, 1.0), 2.0)

	if dir < 0.0:
		root.rotate_y(PI)
	root.rotation.z = dir * randf_range(-0.05, 0.05)
	_bob(body, 0.07, randf_range(1.6, 2.4))
	_register(root, Vector3(dir * randf_range(2.0, 4.0), 0.0, 0.0))

# --- Freighter ---------------------------------------------------------------------

func _spawn_freighter() -> void:
	var dir: float = 1.0 if randi() % 2 == 0 else -1.0
	var root := Node3D.new()
	root.position = Vector3(
		-dir * randf_range(26.0, 32.0),
		randf_range(6.0, 12.0),
		randf_range(-28.0, -18.0),
	)
	var body := Node3D.new()
	root.add_child(body)

	var hull := _emissive_mat(Color(0.08, 0.10, 0.16), 0.12, 0.7, 0.4)
	var hull_lit := _emissive_mat(Color(0.14, 0.18, 0.27), 0.25, 0.4, 0.5)
	var cargo_a := _emissive_mat(Color(0.16, 0.20, 0.30), 0.25, 0.3, 0.5)
	var cargo_b := _emissive_mat(accent.darkened(0.5), 0.5, 0.3, 0.5)

	# Keel, spine and nose.
	body.add_child(_box(Vector3(3.4, 0.30, 0.55), hull))
	body.add_child(_box(Vector3(0.5, 0.22, 0.40), hull_lit, Vector3(1.85, 0.0, 0.0)))
	# Bridge tower at the stern with a lit window strip.
	body.add_child(_box(Vector3(0.40, 0.5, 0.40), hull_lit, Vector3(-1.45, 0.40, 0.0)))
	body.add_child(_box(Vector3(0.42, 0.07, 0.30), _emissive_mat(Color(0.85, 0.95, 1.0), 1.4),
		Vector3(-1.45, 0.52, 0.0)))
	# Cargo containers with accent-lit seams.
	for i in 4:
		var mat: StandardMaterial3D = cargo_a if i % 2 == 0 else cargo_b
		var cx: float = -0.85 + i * 0.72
		body.add_child(_box(Vector3(0.60, 0.32, 0.50), mat, Vector3(cx, 0.30, 0.0)))
		body.add_child(_box(Vector3(0.62, 0.03, 0.52), _emissive_mat(accent, 1.2),
			Vector3(cx, 0.135, 0.0)))
	# Running lights down the hull flank.
	for i in 5:
		_strobe(body, Vector3(-1.4 + i * 0.7, -0.10, 0.30), Color(0.9, 0.95, 1.0), 2.6 + i * 0.3)
	# Twin engines + exhaust.
	for zoff in [-0.18, 0.18]:
		body.add_child(_box(Vector3(0.18, 0.14, 0.16), hull_lit, Vector3(-1.80, -0.02, zoff)))
		body.add_child(_box(Vector3(0.07, 0.11, 0.12), _emissive_mat(accent, 2.6),
			Vector3(-1.92, -0.02, zoff)))
		_exhaust(body, Vector3(-2.02, -0.02, zoff), accent, 0.06, Vector3(-1, 0, 0))

	if dir < 0.0:
		root.rotate_y(PI)
	_bob(body, 0.05, randf_range(2.5, 3.5))
	_register(root, Vector3(dir * randf_range(1.0, 1.8), 0.0, 0.0))
