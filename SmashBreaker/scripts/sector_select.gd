extends Control
## Sector Select — journey map. The 30 sectors wind upward along a serpentine
## path from the bottom (sector 1) to the galaxy boss at the top. Connector
## segments light up as the player travels; the frontier node pulses.

const NODE_SIZE := 116.0
const SPECIAL_SIZE := 132.0
const BOSS_SIZE := 152.0
const STEP_Y := 165.0          # vertical distance between consecutive sectors
const WAVE_AMP := 265.0        # serpentine horizontal swing
const WAVE_FREQ := 0.82
const TOP_PAD := 180.0
const BOT_PAD := 170.0

@onready var _title: Label = $Title
@onready var _tagline: Label = $Tagline
@onready var _stars: Label = $Stars
@onready var _scroll: ScrollContainer = $Scroll
@onready var _map: Control = $Scroll/MapArea
@onready var _back: Button = $Back

var _galaxy: Dictionary = {}
var _accent: Color = Color.WHITE
var _positions: Array = []     # Vector2 centre of each sector node (index 0 = sector 1)
var _unlocked: int = 1

func _ready() -> void:
	_galaxy = Galaxies.get_by_id(GameState.current_galaxy)
	_accent = Galaxies.color(_galaxy, "accent")
	var accent_bright := Galaxies.color(_galaxy, "accent_bright")
	UiTheme.style_title(_title, accent_bright, 56)
	_title.text = _galaxy["name"]
	UiTheme.style_label(_tagline, UiTheme.TEXT_SECONDARY, 24)
	_tagline.text = _galaxy["tagline"]
	UiTheme.style_label(_stars, UiTheme.GOLD, 36, true)
	_stars.text = "★ %d / %d" % [
		GameState.galaxy_stars_total(_galaxy["id"]),
		Galaxies.SECTORS_PER_GALAXY * 3,
	]
	UiTheme.style_button_ghost(_back, accent_bright)
	_back.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/galaxy_map.tscn"))
	_unlocked = GameState.sector_unlocked(_galaxy["id"])
	_layout_path()
	_build_nodes()
	_map.draw.connect(_draw_path)
	_map.queue_redraw()
	# Scroll to the player's frontier after layout settles.
	await get_tree().process_frame
	var frontier_y: float = _positions[_unlocked - 1].y
	_scroll.scroll_vertical = int(clamp(frontier_y - 900.0, 0.0, _map.custom_minimum_size.y))

func _layout_path() -> void:
	## Serpentine path, sector 1 at the bottom, boss at the top.
	var n := Galaxies.SECTORS_PER_GALAXY
	var total_h: float = TOP_PAD + BOT_PAD + STEP_Y * (n - 1)
	_map.custom_minimum_size = Vector2(1060, total_h)
	_positions.clear()
	for i in range(n):
		var x: float = 530.0 + sin(float(i) * WAVE_FREQ) * WAVE_AMP
		var y: float = total_h - BOT_PAD - STEP_Y * i
		_positions.append(Vector2(x, y))

func _draw_path() -> void:
	## Connector segments between consecutive sectors. Traveled = bright,
	## ahead = dim dashed.
	for i in range(_positions.size() - 1):
		var a: Vector2 = _positions[i]
		var b: Vector2 = _positions[i + 1]
		var traveled: bool = (i + 2) <= _unlocked
		if traveled:
			# Soft glow underlay + bright core.
			_map.draw_line(a, b, Color(_accent.r, _accent.g, _accent.b, 0.18), 14.0)
			_map.draw_line(a, b, Color(_accent.r, _accent.g, _accent.b, 0.9), 4.0)
		else:
			_map.draw_dashed_line(a, b, Color(0.35, 0.42, 0.55, 0.45), 3.0, 14.0)

func _build_nodes() -> void:
	for s in range(1, Galaxies.SECTORS_PER_GALAXY + 1):
		var node := _make_node(s)
		_map.add_child(node)

func _make_node(sector: int) -> Control:
	var unlocked: bool = sector <= _unlocked
	var is_frontier: bool = sector == _unlocked
	var stars: int = GameState.get_sector_stars(_galaxy["id"], sector)
	var is_boss: bool = sector == Galaxies.SECTORS_PER_GALAXY
	var is_special: bool = sector in [10, 20]
	var size: float = BOSS_SIZE if is_boss else (SPECIAL_SIZE if is_special else NODE_SIZE)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(size, size)
	btn.size = Vector2(size, size)
	btn.position = _positions[sector - 1] - Vector2(size, size) * 0.5
	var pips := ""
	if unlocked:
		for i in 3:
			pips += ("★" if i < stars else "·")
	var label := "%d" % sector
	if is_boss:
		label = "⬢"
	btn.text = "%s\n%s" % [label, pips] if unlocked else label
	UiTheme.display(btn)
	btn.add_theme_font_size_override("font_size", 34 if is_boss else 26)

	var sb := StyleBoxFlat.new()
	var radius := int(size / 2.0)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if unlocked:
		sb.bg_color = Color(0.04, 0.07, 0.12, 0.95)
		sb.border_color = _accent if (is_frontier or is_boss or is_special) else Color(_accent.r, _accent.g, _accent.b, 0.55)
		var bw := 3 if is_frontier else 2
		sb.border_width_left = bw
		sb.border_width_right = bw
		sb.border_width_top = bw
		sb.border_width_bottom = bw
		if is_frontier:
			sb.shadow_color = Color(_accent.r, _accent.g, _accent.b, 0.45)
			sb.shadow_size = 18
		btn.add_theme_stylebox_override("normal", sb)
		var hover := sb.duplicate()
		hover.bg_color = Color(_accent.r, _accent.g, _accent.b, 0.20)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		btn.add_theme_stylebox_override("focus", sb)
		btn.add_theme_color_override("font_color",
			UiTheme.GOLD if stars >= 3 else UiTheme.TEXT_PRIMARY)
		btn.add_theme_color_override("font_hover_color", UiTheme.TEXT_PRIMARY)
		btn.pressed.connect(func():
			Sfx.play("click")
			GameState.daily_mode = false
			GameState.pending_sector = sector
			Transition.go("res://scenes/game.tscn"))
		if is_frontier:
			# Breathing pulse marks "you are here".
			btn.pivot_offset = Vector2(size, size) * 0.5
			var tw := btn.create_tween().set_loops()
			tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(btn, "scale", Vector2.ONE, 0.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		btn.disabled = true
		sb.bg_color = Color(0.03, 0.045, 0.075, 0.7)
		sb.border_color = Color(0.14, 0.18, 0.26)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		btn.add_theme_stylebox_override("disabled", sb)
		btn.add_theme_color_override("font_disabled_color", Color(0.32, 0.38, 0.48))
	return btn
