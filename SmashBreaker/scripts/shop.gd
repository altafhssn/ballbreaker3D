extends Control
## Shop — paddle skin cards. Buy with gems, equip owned skins.

@onready var _title: Label = $Title
@onready var _gems_label: Label = $Gems
@onready var _grid: GridContainer = $Scroll/Grid
@onready var _back: Button = $Back

func _ready() -> void:
	UiTheme.style_title(_title, UiTheme.ACCENT_BRIGHT, 60)
	UiTheme.style_label(_gems_label, UiTheme.GOLD, 46, true)
	UiTheme.style_button_ghost(_back, UiTheme.ACCENT_BRIGHT)
	_back.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/main.tscn"))
	GameState.gems_changed.connect(func(_g): _refresh())
	_refresh()

func _refresh() -> void:
	_gems_label.text = "◆ %d" % GameState.gems
	for child in _grid.get_children():
		child.queue_free()
	for id in Skins.CATALOG.keys():
		_grid.add_child(_make_card(id))

func _make_card(id: String) -> Control:
	var skin: Dictionary = Skins.get_skin(id)
	var body := Color(skin["body"])
	var glow := Color(skin["glow"])
	var owned: bool = GameState.owned_skins.has(id)
	var equipped: bool = GameState.selected_skin == id

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.08, 0.13)
	sb.border_color = glow if equipped else Color(0.15, 0.22, 0.33)
	var bw := 3 if equipped else 1
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(360, 300)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	# Swatch: paddle silhouette — body bar with glow underline.
	var swatch_holder := CenterContainer.new()
	swatch_holder.custom_minimum_size = Vector2(0, 110)
	var swatch := VBoxContainer.new()
	swatch.add_theme_constant_override("separation", 6)
	var body_rect := ColorRect.new()
	body_rect.color = body
	body_rect.custom_minimum_size = Vector2(220, 56)
	var glow_rect := ColorRect.new()
	glow_rect.color = glow
	glow_rect.custom_minimum_size = Vector2(220, 10)
	swatch.add_child(body_rect)
	swatch.add_child(glow_rect)
	swatch_holder.add_child(swatch)
	v.add_child(swatch_holder)

	var name_label := Label.new()
	name_label.text = skin["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.style_label(name_label, UiTheme.TEXT_PRIMARY, 26, true)
	v.add_child(name_label)

	var action := Button.new()
	if equipped:
		action.text = "EQUIPPED"
		UiTheme.style_button_ghost(action, glow, 28)
		action.disabled = true
	elif owned:
		action.text = "EQUIP"
		UiTheme.style_button(action, glow, 28)
		action.pressed.connect(func():
			Sfx.play("click")
			GameState.equip_skin(id)
			_refresh())
	else:
		action.text = "◆ %d" % skin["price"]
		var affordable: bool = GameState.gems >= int(skin["price"])
		if affordable:
			UiTheme.style_button(action, Color("#ffb84a"), 28)
		else:
			UiTheme.style_button_ghost(action, Color("#6a7da0"), 28)
		action.pressed.connect(func():
			if GameState.buy_skin(id):
				Sfx.play("purchase")
				GameState.equip_skin(id)
			else:
				Sfx.play("denied")
			_refresh())
	action.custom_minimum_size = Vector2(0, 64)
	v.add_child(action)
	return panel
