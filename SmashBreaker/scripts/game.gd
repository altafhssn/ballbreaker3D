extends Node3D
## Game scene controller — 3D, portrait.
##
## World plane: XZ. Y is world-up (cosmetic; gameplay is 2-axis).
## Field span: X ∈ [-5.4, +5.4], Z ∈ [-9.6, +9.6]. Paddle near +Z, bricks in -Z.

const BrickScene := preload("res://scenes/brick.tscn")
const BallScene := preload("res://scenes/ball.tscn")
const PaddleScene := preload("res://scenes/paddle.tscn")
const PowerUpScene := preload("res://scenes/powerup.tscn")
const PowerUpScript := preload("res://scripts/powerup.gd")
const HudScene := preload("res://scenes/hud.tscn")
const GameOverScene := preload("res://scenes/game_over.tscn")
const PauseScene := preload("res://scenes/pause_overlay.tscn")
const LevelCompleteScene := preload("res://scenes/level_complete.tscn")
const BrickIntroScene := preload("res://scenes/brick_intro.tscn")
const SpaceTraffic := preload("res://scripts/space_traffic.gd")

# World bounds (must agree with paddle.gd FIELD_HALF_W).
const FIELD_HALF_W := 5.4
const BACK_WALL_Z := -9.6
const KILL_Z := 9.6
const PADDLE_Z := 8.0

# Brick grid — the cell pitch is larger than the mesh size so rows have visible
# gaps between them at the camera's perspective. (Mesh size is set in brick.gd.)
const BRICK_W := 1.3           # X spacing (8 cols × 1.3 = 10.4m fits in 10.8m field)
const BRICK_D := 1.0           # Z spacing (mesh is 0.55 deep → 0.45 gap)
const BRICK_TOP_Z := -6.5

const POWERUP_WEIGHTS := {"wide": 30, "fire": 20, "multiball": 20}
const COMBO_WINDOW := 0.5
const WIDE_DURATION := 20.0
const FIRE_DURATION := 10.0

var POWERUP_TYPE_MAP := {}

var paddle: Node3D = null
var balls: Array = []
var bricks_alive: int = 0
var combo_timer: float = 0.0
var combo_chain: int = 0
var no_death_this_level: bool = true

var wide_timer: float = 0.0
var fire_timer: float = 0.0

# Juice / flow state
var _shake: float = 0.0
var _cam_base_pos: Vector3 = Vector3.ZERO
var _level_start_score: int = 0
var _level_completing: bool = false
var _game_over_shown: bool = false
var _pause_overlay: CanvasLayer = null

# Galaxy conquest state
var _galaxy: Dictionary = {}        # active galaxy config (Galaxies entry)
var _no_drops: bool = false         # sector 20 gauntlet: no power-up drops
var _daily: Dictionary = {}         # daily-challenge level (when daily_mode)
var _intro_queue: Array = []        # brick types awaiting first-contact popups
var _intro_active: bool = false

@onready var _brick_container: Node3D = $Bricks
@onready var _ball_container: Node3D = $Balls
@onready var _powerup_container: Node3D = $PowerUps
@onready var _walls: Node3D = $Walls
@onready var _killzone: Area3D = $KillZone
@onready var _camera: Camera3D = $Camera
@onready var _stadium: Node3D = $Stadium
@onready var _trim: Node3D = $Trim
var _hud: CanvasLayer = null

func _ready() -> void:
	randomize()
	POWERUP_TYPE_MAP = {
		"wide": PowerUpScript.Type.WIDE,
		"multiball": PowerUpScript.Type.MULTIBALL,
		"fire": PowerUpScript.Type.FIRE,
	}
	if GameState.daily_mode:
		_daily = LevelGen.get_daily(GameState.daily_last_date)
		_galaxy = Galaxies.get_by_id(_daily["galaxy_id"])
	else:
		_galaxy = Galaxies.get_by_id(GameState.current_galaxy)
	_hud = HudScene.instantiate()
	add_child(_hud)
	if _hud.has_signal("pause_requested"):
		_hud.pause_requested.connect(toggle_pause)
	# Portrait framing: steep look-down so the full court depth fills the
	# tall screen; slight forward bias keeps the paddle in the lower third.
	_camera.look_at(Vector3(0.0, 0.0, -0.5))
	_cam_base_pos = _camera.position
	_apply_theme()
	_build_walls()
	_build_killzone()
	_build_stadium()
	_build_starfield()
	_build_court_trim()
	# Ambient comets / ships cruising the void behind the arena.
	var traffic := SpaceTraffic.new()
	traffic.accent = Galaxies.color(_galaxy, "accent")
	add_child(traffic)
	_spawn_paddle()
	if _galaxy.get("mechanic", "none") == "ice":
		paddle.slide_mode = true
	GameState.reset_run()
	GameState.set_level(clamp(GameState.pending_sector, 1, Galaxies.SECTORS_PER_GALAXY))
	_load_level(GameState.level)

func _apply_theme() -> void:
	## Recolour the one game scene to the active galaxy: floor shader, fog,
	## ambient/fill lights. Stadium + trim read _galaxy directly when built.
	var floor_mat: ShaderMaterial = $Court.material_override
	if floor_mat:
		floor_mat.set_shader_parameter("base_color", Galaxies.color(_galaxy, "floor_base"))
		floor_mat.set_shader_parameter("base_color_2", Galaxies.color(_galaxy, "floor_base_2"))
		floor_mat.set_shader_parameter("grid_color", Galaxies.color(_galaxy, "grid_color"))
		floor_mat.set_shader_parameter("hot_color", Galaxies.color(_galaxy, "hot_color"))
	var env: Environment = $WorldEnv.environment
	if env:
		env.background_color = Galaxies.color(_galaxy, "env_bg")
		env.ambient_light_color = Galaxies.color(_galaxy, "ambient")
		env.fog_light_color = Galaxies.color(_galaxy, "env_bg")
	$FillLight.light_color = Galaxies.color(_galaxy, "fill_light")

# --- World setup -----------------------------------------------------------

func _build_walls() -> void:
	# Left, right, back. Bottom is the kill zone Area3D.
	_make_wall(Vector3(-FIELD_HALF_W - 0.2, 0.0, 0.0), Vector3(0.4, 2.0, 22.0))
	_make_wall(Vector3(FIELD_HALF_W + 0.2, 0.0, 0.0), Vector3(0.4, 2.0, 22.0))
	_make_wall(Vector3(0.0, 0.0, BACK_WALL_Z - 0.2), Vector3(FIELD_HALF_W * 2.5, 2.0, 0.4))

func _make_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 0b000100   # Walls (3)
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	_walls.add_child(body)

func _build_killzone() -> void:
	_killzone.collision_layer = 0b100000   # KillZone (6)
	_killzone.collision_mask = 0
	_killzone.monitoring = true
	_killzone.monitorable = true
	_killzone.add_to_group("killzone")
	_killzone.position = Vector3(0.0, 0.0, KILL_Z + 1.0)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(FIELD_HALF_W * 4.0, 4.0, 1.0)
	cs.shape = sh
	_killzone.add_child(cs)

func _spawn_paddle() -> void:
	paddle = PaddleScene.instantiate()
	add_child(paddle)

# --- Stadium dressing ------------------------------------------------------

func _build_stadium() -> void:
	# Hangar walls: vertical dark slabs alternating with thinner cyan light
	# panels. Reads as the interior of a ship hangar.
	const PANELS := 10
	const COURT_DEPTH := 28.0
	const FIRST_DIST := 0.25
	const PANEL_WIDTH := 0.5
	const PANEL_HEIGHT := 6.5
	var hull: Color = Galaxies.color(_galaxy, "wall_hull")
	var hull_dark: Color = hull.darkened(0.45)
	var glow: Color = Galaxies.color(_galaxy, "wall_glow")
	var hull_emit: Color = hull.lightened(0.2)

	for side in [-1.0, 1.0]:
		for p in range(PANELS):
			var x: float = side * (FIELD_HALF_W + FIRST_DIST + p * PANEL_WIDTH + PANEL_WIDTH * 0.5)
			var is_light: bool = (p % 3 == 1)
			# Light panels are slightly shorter and recessed; hull panels rise.
			var ph: float = PANEL_HEIGHT * (0.35 if is_light else 0.55 + 0.05 * float(p))
			var box := BoxMesh.new()
			box.size = Vector3(PANEL_WIDTH * (0.6 if is_light else 1.0), ph, COURT_DEPTH)
			var mesh := MeshInstance3D.new()
			mesh.mesh = box
			mesh.position = Vector3(x, ph * 0.5 - 0.3, -1.0)
			var mat := StandardMaterial3D.new()
			if is_light:
				mat.albedo_color = glow
				mat.emission_enabled = true
				mat.emission = glow
				mat.emission_energy_multiplier = 2.2
				mat.metallic = 0.0
				mat.roughness = 0.25
			else:
				mat.albedo_color = hull if (p % 2 == 0) else hull_dark
				# Subtle blue emission so the dark hull reads against the void.
				mat.emission_enabled = true
				mat.emission = hull_emit
				mat.emission_energy_multiplier = 0.25
				mat.metallic = 0.6
				mat.roughness = 0.4
			mesh.material_override = mat
			_stadium.add_child(mesh)

	# Back bulkhead — a dark metal slab with a thin glowing seam, occluding
	# the void behind the brick wall.
	var back_h: float = PANEL_HEIGHT * 0.55
	var back_box := BoxMesh.new()
	back_box.size = Vector3(FIELD_HALF_W * 4.0, back_h, 1.2)
	var back_mesh := MeshInstance3D.new()
	back_mesh.mesh = back_box
	back_mesh.position = Vector3(0.0, back_h * 0.5 - 0.3, BACK_WALL_Z - 0.6)
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.05, 0.07, 0.11)
	back_mat.metallic = 0.7
	back_mat.roughness = 0.35
	back_mesh.material_override = back_mat
	_stadium.add_child(back_mesh)

	# Cyan seam across the top of the bulkhead for atmosphere.
	var seam_box := BoxMesh.new()
	seam_box.size = Vector3(FIELD_HALF_W * 3.5, 0.06, 0.2)
	var seam_mesh := MeshInstance3D.new()
	seam_mesh.mesh = seam_box
	seam_mesh.position = Vector3(0.0, back_h - 0.5, BACK_WALL_Z + 0.0)
	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = glow
	seam_mat.emission_enabled = true
	seam_mat.emission = glow
	seam_mat.emission_energy_multiplier = 3.0
	seam_mesh.material_override = seam_mat
	_stadium.add_child(seam_mesh)

func _build_starfield() -> void:
	# Distant stars above / behind the hangar. Every star twinkles on its own
	# rhythm: emission breathes continuously, and a random few do an
	# occasional sharp glint.
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.05
	star_mesh.height = 0.1
	star_mesh.radial_segments = 6
	star_mesh.rings = 3
	for i in 70:
		var m := MeshInstance3D.new()
		m.mesh = star_mesh
		m.position = Vector3(
			randf_range(-24.0, 24.0),
			randf_range(3.0, 16.0),
			randf_range(-34.0, -12.0),
		)
		var mat := StandardMaterial3D.new()
		var tint := randf_range(0.72, 1.0)
		var c := Color(tint, tint, 1.0)
		mat.albedo_color = c
		mat.emission_enabled = true
		mat.emission = c
		var base_energy := randf_range(0.7, 2.2)
		mat.emission_energy_multiplier = base_energy
		m.material_override = mat
		m.scale = Vector3.ONE * randf_range(0.5, 1.6)
		_stadium.add_child(m)
		# Twinkle: dim and brighten on a per-star period and phase.
		var lo := base_energy * randf_range(0.25, 0.5)
		var hi := base_energy * randf_range(1.2, 1.8)
		var half_period := randf_range(0.5, 2.2)
		var tw := m.create_tween().set_loops()
		tw.tween_interval(randf_range(0.0, 2.0))   # desync phases
		tw.tween_property(mat, "emission_energy_multiplier", lo, half_period) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(mat, "emission_energy_multiplier", hi, half_period) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# ~1 in 5 stars also glints: a sharp bright spike every few seconds.
		if randi() % 5 == 0:
			var glint := m.create_tween().set_loops()
			glint.tween_interval(randf_range(3.0, 9.0))
			glint.tween_property(mat, "emission_energy_multiplier", hi * 2.6, 0.10) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			glint.tween_property(mat, "emission_energy_multiplier", base_energy, 0.35) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _build_court_trim() -> void:
	# Glowing strip in the galaxy accent colour running around the perimeter.
	var accent: Color = Galaxies.color(_galaxy, "accent")
	var neon := StandardMaterial3D.new()
	neon.albedo_color = accent
	neon.emission_enabled = true
	neon.emission = accent
	neon.emission_energy_multiplier = 3.5
	neon.roughness = 0.2
	neon.metallic = 0.0

	var trim_h := 0.08
	var trim_y := -0.22
	var rail_thick := 0.06

	# Two long rails along the X edges (left and right of court).
	for side in [-1.0, 1.0]:
		var box := BoxMesh.new()
		box.size = Vector3(rail_thick, trim_h, 19.2)
		var m := MeshInstance3D.new()
		m.mesh = box
		m.position = Vector3(side * (FIELD_HALF_W + 0.05), trim_y, -0.6)
		m.material_override = neon
		_trim.add_child(m)

	# Back rail (behind brick wall).
	var back_rail := BoxMesh.new()
	back_rail.size = Vector3(FIELD_HALF_W * 2.0 + 0.2, trim_h, rail_thick)
	var br := MeshInstance3D.new()
	br.mesh = back_rail
	br.position = Vector3(0.0, trim_y, BACK_WALL_Z + 0.05)
	br.material_override = neon
	_trim.add_child(br)

	# Front rail (just behind paddle, gives the player baseline a glow).
	var front_rail := BoxMesh.new()
	front_rail.size = Vector3(FIELD_HALF_W * 2.0 + 0.2, trim_h, rail_thick)
	var fr := MeshInstance3D.new()
	fr.mesh = front_rail
	fr.position = Vector3(0.0, trim_y, KILL_Z - 0.6)
	fr.material_override = neon
	_trim.add_child(fr)

# --- Level lifecycle -------------------------------------------------------

func _load_level(n: int) -> void:
	_clear_level()
	no_death_this_level = true
	_level_completing = false
	_level_start_score = GameState.score
	var lvl: Dictionary = _daily if GameState.daily_mode else LevelGen.get_level(_galaxy["id"], n)
	var layout: Array = lvl["layout"]
	_no_drops = lvl["no_drops"]
	var grid_w: float = LevelGen.COLS * BRICK_W
	var x_start: float = -grid_w * 0.5 + BRICK_W * 0.5
	for r in range(layout.size()):
		for c in range(layout[r].size()):
			var code: int = layout[r][c]
			if code == 0:
				continue
			var b := BrickScene.instantiate()
			b.configure(code, Vector2i(c, r))
			b.position = Vector3(x_start + c * BRICK_W, 0.0, BRICK_TOP_Z + r * BRICK_D)
			_brick_container.add_child(b)
			bricks_alive += 1
	_spawn_ball_on_paddle()
	_check_brick_intros(layout)

# --- Brick codex (first-contact popups) ----------------------------------------

func _check_brick_intros(layout: Array) -> void:
	## Queue a one-time intro popup for every brick type in this layout the
	## player has never met. Pauses the game until all are dismissed.
	var present := {}
	for row in layout:
		for code in row:
			if code != 0:
				present[code] = true
	var new_types: Array = []
	for t in present.keys():
		if not GameState.is_brick_seen(t):
			new_types.append(t)
	if new_types.is_empty():
		return
	new_types.sort()
	_intro_queue = new_types
	_intro_active = true
	get_tree().paused = true
	_show_next_intro()

func _show_next_intro() -> void:
	if _intro_queue.is_empty():
		_intro_active = false
		get_tree().paused = false
		GameState.save()
		return
	var t: int = _intro_queue.pop_front()
	GameState.mark_brick_seen(t)
	var popup := BrickIntroScene.instantiate()
	add_child(popup)
	popup.setup(t)
	popup.dismissed.connect(_show_next_intro)

func _clear_level() -> void:
	for child in _brick_container.get_children():
		child.queue_free()
	for child in _ball_container.get_children():
		child.queue_free()
	for child in _powerup_container.get_children():
		child.queue_free()
	balls.clear()
	bricks_alive = 0
	wide_timer = 0.0
	fire_timer = 0.0
	if paddle and paddle.has_method("set_wide"):
		paddle.set_wide(false)
	_update_hud_powerups()

func _spawn_ball_on_paddle() -> void:
	var ball := BallScene.instantiate()
	_ball_container.add_child(ball)
	ball.attach_to_paddle(paddle)
	ball.hit_brick.connect(_on_ball_hit_brick)
	ball.lost.connect(_on_ball_lost.bind(ball))
	balls.append(ball)

# --- Per-frame -------------------------------------------------------------

func _process(delta: float) -> void:
	if wide_timer > 0.0:
		wide_timer -= delta
		if wide_timer <= 0.0:
			paddle.set_wide(false)
		_update_hud_powerups()
	if fire_timer > 0.0:
		fire_timer -= delta
		if fire_timer <= 0.0:
			for b in balls:
				if is_instance_valid(b):
					b.set_fire(false)
		_update_hud_powerups()
	if combo_chain > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_chain = 0

	# Camera shake — random offset that decays linearly.
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 1.8)
		_camera.position = _cam_base_pos + Vector3(
			randf_range(-1, 1) * _shake,
			randf_range(-1, 1) * _shake * 0.6,
			0.0,
		)
	else:
		_camera.position = _cam_base_pos

	if Input.is_action_just_pressed("ui_pause"):
		toggle_pause()

func shake(strength: float) -> void:
	_shake = max(_shake, strength)

func toggle_pause() -> void:
	# Don't allow pausing over game-over / level-complete / codex overlays.
	if _game_over_shown or _level_completing or _intro_active:
		return
	if _pause_overlay and is_instance_valid(_pause_overlay):
		_pause_overlay.queue_free()
		_pause_overlay = null
		get_tree().paused = false
	else:
		Sfx.play("click")
		_pause_overlay = PauseScene.instantiate()
		add_child(_pause_overlay)
		_pause_overlay.resume_requested.connect(toggle_pause)
		get_tree().paused = true

# --- Signal handlers -------------------------------------------------------

func _on_ball_hit_brick(brick: Node) -> void:
	var brick_color: Color = brick.color
	var brick_pos: Vector3 = brick.position
	var destroyed: bool = brick.hit(fire_timer > 0.0)
	if destroyed:
		Sfx.play_varied("brick_break")
		shake(0.08)
		_spawn_burst(brick_pos, brick_color)
		_score_popup(brick_pos, "+%d" % brick.points, brick_color)
		GameState.add_score(brick.points)
		GameState.brick_broken()
		bricks_alive -= 1
		combo_chain += 1
		combo_timer = COMBO_WINDOW
		if combo_chain > 1:
			GameState.add_score(5 * (combo_chain - 1))
		if combo_chain >= 3:
			_score_popup(brick_pos + Vector3(0, 0.6, 0), "x%d COMBO" % combo_chain, Color("#ffb84a"), 1.4)
		var roll: int = randi() % 100
		if roll < brick.drop_pct and not _no_drops:
			_spawn_powerup(brick_pos)
		if brick.brick_type == brick.TYPE_EXPLOSIVE:
			_explode_around(brick.grid_pos)
		if bricks_alive <= 0:
			call_deferred("_on_level_complete")
	else:
		Sfx.play_varied("brick_hit", -4.0)
		shake(0.03)

func _explode_around(gpos: Vector2i, depth: int = 0) -> void:
	# Chain-explode bricks in the 3×3 around gpos. If a chained brick is itself
	# explosive, recurse — capped by depth to prevent runaway chains.
	const MAX_DEPTH := 4
	if depth > MAX_DEPTH:
		return
	var to_kill: Array = []
	for b in _brick_container.get_children():
		if not is_instance_valid(b) or b.hp <= 0:
			continue
		var dx: int = abs(b.grid_pos.x - gpos.x)
		var dy: int = abs(b.grid_pos.y - gpos.y)
		if dx <= 1 and dy <= 1 and b.grid_pos != gpos:
			to_kill.append(b)
	# Cap per blast at 12 to keep frame cost predictable.
	to_kill = to_kill.slice(0, 12)
	if not to_kill.is_empty():
		Sfx.play("explosion", 0.0, randf_range(0.9, 1.1))
		shake(0.35)
	var nested: Array = []
	for b in to_kill:
		GameState.add_score(b.points)
		GameState.brick_broken()
		bricks_alive -= 1
		_spawn_burst(b.position, b.color)
		if b.brick_type == b.TYPE_EXPLOSIVE:
			nested.append(b.grid_pos)
		b.queue_free()
	for ngpos in nested:
		_explode_around(ngpos, depth + 1)
	if bricks_alive <= 0:
		call_deferred("_on_level_complete")

func _on_ball_lost(ball: Node) -> void:
	if is_instance_valid(ball):
		ball.queue_free()
	balls.erase(ball)
	if balls.is_empty():
		no_death_this_level = false
		Sfx.play("life_lost")
		shake(0.3)
		var alive := GameState.lose_life()
		if alive:
			_spawn_ball_on_paddle()
		else:
			_show_game_over()

# --- FX helpers --------------------------------------------------------------

func _spawn_burst(at: Vector3, color: Color) -> void:
	## One-shot particle burst in the brick's colour.
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = 18
	p.lifetime = 0.55
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.spread = 180.0
	p.gravity = Vector3(0, -2.0, 0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 0.12)
	p.mesh = bm
	var grad := Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = grad
	add_child(p)
	get_tree().create_timer(0.9).timeout.connect(p.queue_free)

func _score_popup(at: Vector3, text: String, color: Color, scale_mult: float = 1.0) -> void:
	## Floating 3D text that rises and fades.
	var label := Label3D.new()
	label.text = text
	label.font_size = int(96 * scale_mult)
	label.modulate = color
	label.outline_size = 14
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = at + Vector3(0, 0.6, 0)
	add_child(label)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y + 1.4, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)

func _spawn_powerup(at: Vector3) -> void:
	var total := 0
	for w in POWERUP_WEIGHTS.values():
		total += w
	var roll := randi() % total
	var chosen := "wide"
	var acc := 0
	for k in POWERUP_WEIGHTS.keys():
		acc += POWERUP_WEIGHTS[k]
		if roll < acc:
			chosen = k
			break
	var pu := PowerUpScene.instantiate()
	pu.set_type(POWERUP_TYPE_MAP[chosen])
	pu.position = at
	pu.collected.connect(_on_powerup_collected)
	_powerup_container.add_child(pu)

func _on_powerup_collected(key: String) -> void:
	match key:
		"wide":
			wide_timer = WIDE_DURATION
			paddle.set_wide(true)
		"fire":
			fire_timer = FIRE_DURATION
			for b in balls:
				if is_instance_valid(b):
					b.set_fire(true)
		"multiball":
			_split_multiball()
	Sfx.play("powerup")
	GameState.add_score(50)
	_update_hud_powerups()

func _split_multiball() -> void:
	if balls.is_empty():
		return
	var seed_ball = balls[0]
	if not seed_ball.launched:
		seed_ball.launch_with_velocity(Vector3(0, 0, -1))
	var base_v: Vector3 = seed_ball.velocity
	if base_v.length() < 0.1:
		base_v = Vector3(0, 0, -1)
	for ang in [-30.0, 30.0]:
		var nb = BallScene.instantiate()
		_ball_container.add_child(nb)
		nb.position = seed_ball.position
		nb.hit_brick.connect(_on_ball_hit_brick)
		nb.lost.connect(_on_ball_lost.bind(nb))
		nb.launch_with_velocity(base_v.rotated(Vector3.UP, deg_to_rad(ang)))
		if fire_timer > 0.0:
			nb.set_fire(true)
		balls.append(nb)

func _update_hud_powerups() -> void:
	var parts: Array = []
	if wide_timer > 0.0:
		parts.append("WIDE %0.0fs" % wide_timer)
	if fire_timer > 0.0:
		parts.append("FIRE %0.0fs" % fire_timer)
	if _hud and _hud.has_method("set_active_powerups"):
		_hud.set_active_powerups(" · ".join(parts))

# --- Win / lose ------------------------------------------------------------

func _on_level_complete() -> void:
	if _level_completing:
		return
	_level_completing = true
	if no_death_this_level:
		GameState.add_score(200)
	if GameState.daily_mode:
		_on_daily_complete()
		return
	# Stars: 1 = clear, 2 = score threshold, 3 = threshold + no death (GDD §6).
	var lvl: Dictionary = LevelGen.get_level(_galaxy["id"], GameState.level)
	var base: int = LevelGen.sum_brick_score(lvl["layout"])
	var level_score: int = GameState.score - _level_start_score
	var threshold: int = int(base * 1.1)
	var earned_stars := 1
	if level_score >= threshold:
		earned_stars = 3 if no_death_this_level else 2
	# Gems scale with galaxy depth: later galaxies pay more.
	var gi: int = Galaxies.index_of(_galaxy["id"])
	var earned_gems: int = (5 + 5 * earned_stars) * (1 + gi)
	GameState.add_gems(earned_gems)
	GameState.record_sector_result(_galaxy["id"], GameState.level, earned_stars)
	Sfx.play("level_complete")
	var lc := LevelCompleteScene.instantiate()
	add_child(lc)
	var is_last: bool = GameState.level >= Galaxies.SECTORS_PER_GALAXY
	lc.setup(GameState.level, earned_stars, level_score, earned_gems, is_last)
	lc.next_requested.connect(_on_next_level)
	get_tree().paused = true

func _on_daily_complete() -> void:
	## Daily cleared: bigger gem payout, record the score, back to the menu.
	var base: int = LevelGen.sum_brick_score(_daily["layout"])
	var level_score: int = GameState.score - _level_start_score
	var threshold: int = int(base * 1.1)
	var earned_stars := 1
	if level_score >= threshold:
		earned_stars = 3 if no_death_this_level else 2
	var earned_gems: int = 30 + 10 * earned_stars
	GameState.add_gems(earned_gems)
	GameState.complete_daily(GameState.score)
	GameState.daily_mode = false
	Sfx.play("level_complete")
	var lc := LevelCompleteScene.instantiate()
	add_child(lc)
	lc.setup_daily(earned_stars, level_score, earned_gems)
	lc.next_requested.connect(func(): Transition.go("res://scenes/main.tscn"))
	get_tree().paused = true

func _on_next_level() -> void:
	get_tree().paused = false
	if GameState.level >= Galaxies.SECTORS_PER_GALAXY:
		# Galaxy conquered — back to the star chart.
		Transition.go("res://scenes/galaxy_map.tscn")
		return
	var next := GameState.level + 1
	GameState.set_level(next)
	_load_level(next)

func _show_game_over() -> void:
	_game_over_shown = true
	Sfx.play("game_over")
	GameState.on_game_over()
	var go := GameOverScene.instantiate()
	add_child(go)   # overlay _ready reads daily_mode (hides RETRY for dailies)
	if GameState.daily_mode:
		GameState.daily_mode = false   # attempt was consumed at launch
