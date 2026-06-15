extends Control
## Galaxy Map — the star chart. One card per galaxy: conquered glow, star
## count, locked / coming-soon states. Click an unlocked galaxy → sector grid.

@onready var _title: Label = $Title
@onready var _stars: Label = $Stars
@onready var _grid: GridContainer = $Scroll/Grid
@onready var _back: Button = $Back

func _ready() -> void:
	UiTheme.style_title(_title, UiTheme.ACCENT_BRIGHT, 64)
	UiTheme.style_label(_stars, UiTheme.GOLD, 44, true)
	_stars.text = "★ %d" % GameState.total_stars()
	UiTheme.style_button_ghost(_back, UiTheme.ACCENT_BRIGHT)
	_back.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/main.tscn"))
	for i in Galaxies.count():
		_grid.add_child(_make_card(i))

func _make_card(index: int) -> Control:
	var g: Dictionary = Galaxies.get_galaxy(index)
	var accent := Galaxies.color(g, "accent")
	var unlocked: bool = GameState.is_galaxy_unlocked(index)
	var playable: bool = g["playable"]
	var stars: int = GameState.galaxy_stars_total(g["id"])
	var max_stars: int = Galaxies.SECTORS_PER_GALAXY * 3
	var conquered: bool = GameState.sector_unlocked(g["id"]) >= Galaxies.SECTORS_PER_GALAXY \
		and GameState.get_sector_stars(g["id"], Galaxies.SECTORS_PER_GALAXY) > 0

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.11, 0.92)
	var border := accent if unlocked else Color(0.16, 0.20, 0.30)
	sb.border_color = border
	var bw := 2 if conquered else 1
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	if unlocked:
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
		sb.shadow_size = 10
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(430, 340)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)

	# Galaxy orb — a coloured circle approximated with a rounded panel.
	var orb_holder := CenterContainer.new()
	orb_holder.custom_minimum_size = Vector2(0, 110)
	var orb := PanelContainer.new()
	var orb_sb := StyleBoxFlat.new()
	var orb_color := accent if unlocked else Color(0.22, 0.26, 0.34)
	orb_sb.bg_color = orb_color
	orb_sb.corner_radius_top_left = 50
	orb_sb.corner_radius_top_right = 50
	orb_sb.corner_radius_bottom_left = 50
	orb_sb.corner_radius_bottom_right = 50
	if unlocked:
		orb_sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
		orb_sb.shadow_size = 18
	orb.add_theme_stylebox_override("panel", orb_sb)
	orb.custom_minimum_size = Vector2(96, 96)
	orb_holder.add_child(orb)
	v.add_child(orb_holder)

	var name_l := Label.new()
	name_l.text = g["name"]
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.display(name_l)
	name_l.add_theme_font_size_override("font_size", 26)
	name_l.add_theme_color_override("font_color",
		UiTheme.TEXT_PRIMARY if unlocked else UiTheme.TEXT_SECONDARY)
	v.add_child(name_l)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.style_label(sub, UiTheme.TEXT_SECONDARY, 20)
	if not playable:
		sub.text = "COMING SOON"
	elif not unlocked:
		var prev: Dictionary = Galaxies.get_galaxy(index - 1)
		var need: int = Galaxies.STARS_TO_UNLOCK
		var have: int = GameState.galaxy_stars_total(prev["id"])
		sub.text = "LOCKED  ·  %d/%d ★ IN %s" % [have, need, prev["name"]]
	else:
		sub.text = g["tagline"]
	v.add_child(sub)

	var star_l := Label.new()
	star_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.style_label(star_l, UiTheme.GOLD if stars > 0 else UiTheme.TEXT_SECONDARY, 24, true)
	star_l.text = "★ %d / %d" % [stars, max_stars]
	v.add_child(star_l)

	if unlocked:
		var enter := Button.new()
		enter.text = "CONQUERED ✦" if conquered else "ENTER"
		UiTheme.style_button(enter, accent, 26)
		enter.custom_minimum_size = Vector2(0, 56)
		enter.pressed.connect(func():
			Sfx.play("click")
			GameState.current_galaxy = g["id"]
			GameState.save()
			Transition.go("res://scenes/sector_select.tscn"))
		v.add_child(enter)
	return panel
