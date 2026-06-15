extends Control
## Main menu — animated shader backdrop, hero title, launch / daily / hangar,
## volume sliders.

@onready var _title: Label = $Center/V/Title
@onready var _tagline: Label = $Center/V/Tagline
@onready var _high: Label = $Center/V/HighScore
@onready var _play: Button = $Center/V/Play
@onready var _daily: Button = $Center/V/Daily
@onready var _shop: Button = $Center/V/Shop
@onready var _quit: Button = $Center/V/Quit
@onready var _sfx_label: Label = $Center/V/SfxRow/SfxLabel
@onready var _sfx_slider: HSlider = $Center/V/SfxRow/SfxSlider
@onready var _music_label: Label = $Center/V/MusicRow/MusicLabel
@onready var _music_slider: HSlider = $Center/V/MusicRow/MusicSlider
@onready var _gems: Label = $Gems
@onready var _version: Label = $Version
@onready var _v: VBoxContainer = $Center/V
@onready var _unlock_all: Button = $Center/V/OptionsRow/UnlockAll
@onready var _reset: Button = $Center/V/OptionsRow/Reset

func _ready() -> void:
	_apply_portrait_layout()
	UiTheme.style_title(_title, UiTheme.ACCENT_BRIGHT, 82)
	UiTheme.style_label(_tagline, UiTheme.TEXT_SECONDARY, 30)
	# Neon rule between tagline and stats.
	var rule := UiTheme.accent_rule(360.0, UiTheme.ACCENT)
	_v.add_child(rule)
	_v.move_child(rule, _tagline.get_index() + 1)
	_high.text = "HIGH SCORE  %d    ·    ★ %d" % [GameState.high_score, GameState.total_stars()]
	UiTheme.style_label(_high, UiTheme.TEXT_SECONDARY, 30, true)
	_gems.text = "◆ %d" % GameState.gems
	UiTheme.style_label(_gems, UiTheme.GOLD, 38, true)
	UiTheme.style_label(_version, UiTheme.TEXT_SECONDARY, 22)
	UiTheme.style_button(_play, UiTheme.ACCENT, 42)
	UiTheme.style_button(_shop, UiTheme.GOLD, 38)
	UiTheme.style_button_ghost(_quit, UiTheme.WARN, 32)
	_setup_daily_button()
	_setup_volume_sliders()
	_setup_option_buttons()
	_play.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/galaxy_map.tscn"))
	_shop.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/shop.tscn"))
	_quit.pressed.connect(func(): get_tree().quit())
	# Slow breathing pulse on the title glow. Uses self_modulate so it doesn't
	# fight the entrance cascade (which animates modulate).
	var tw := create_tween().set_loops()
	tw.tween_property(_title, "self_modulate:a", 0.72, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_title, "self_modulate:a", 1.0, 1.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Entrance: menu items cascade in.
	var idx := 0
	for child in _v.get_children():
		if child is Control:
			child.modulate.a = 0.0
			var ct := create_tween()
			ct.tween_interval(0.05 * idx)
			ct.tween_property(child, "modulate:a", 1.0, 0.3) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			idx += 1

func _setup_daily_button() -> void:
	if GameState.daily_available():
		UiTheme.style_button(_daily, UiTheme.WARN, 34)
		_daily.text = "DAILY CHALLENGE"
		_daily.pressed.connect(func():
			Sfx.play("click")
			GameState.start_daily()
			Transition.go("res://scenes/game.tscn"))
	else:
		UiTheme.style_button_ghost(_daily, UiTheme.TEXT_SECONDARY, 30)
		_daily.text = "DAILY DONE — BACK TOMORROW"
		_daily.disabled = true

func _setup_volume_sliders() -> void:
	UiTheme.style_label(_sfx_label, UiTheme.TEXT_SECONDARY, 26, true)
	UiTheme.style_label(_music_label, UiTheme.TEXT_SECONDARY, 26, true)
	_sfx_slider.value = GameState.sfx_volume
	_music_slider.value = GameState.music_volume
	# Live apply while dragging (no save), persist on release.
	_sfx_slider.value_changed.connect(func(v: float):
		GameState.set_sfx_volume(v, false))
	_sfx_slider.drag_ended.connect(func(_changed: bool):
		GameState.set_sfx_volume(_sfx_slider.value)
		Sfx.play("click"))   # audible preview at the new level
	_music_slider.value_changed.connect(func(v: float):
		GameState.set_music_volume(v, false)
		Music.set_volume(v))
	_music_slider.drag_ended.connect(func(_changed: bool):
		GameState.set_music_volume(_music_slider.value))

func _setup_option_buttons() -> void:
	UiTheme.style_button_ghost(_unlock_all, UiTheme.TEXT_SECONDARY, 24)
	UiTheme.style_button_ghost(_reset, UiTheme.WARN, 24)
	for b in [_unlock_all, _reset]:
		b.custom_minimum_size = Vector2(280, 60)
	if GameState.all_unlocked:
		_unlock_all.text = "ALL UNLOCKED ✓"
		_unlock_all.disabled = true
	_unlock_all.pressed.connect(func():
		Sfx.play("click")
		_confirm("Open every sector in all available galaxies?\nStar gates will be bypassed.",
			func():
				GameState.unlock_all()
				Sfx.play("purchase")
				Transition.go("res://scenes/main.tscn")))
	_reset.pressed.connect(func():
		Sfx.play("click")
		_confirm("Erase ALL progress?\nScores, stars, gems, skins and daily history will be wiped.\nThis cannot be undone.",
			func():
				GameState.reset_progress()
				Sfx.play("denied")
				Transition.go("res://scenes/main.tscn")))

func _confirm(message: String, on_yes: Callable) -> void:
	## Small modal confirm built in code: glass panel, CONFIRM / CANCEL.
	var layer := CanvasLayer.new()
	layer.layer = 40
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.glass_panel(UiTheme.WARN))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(560, 0)
	v.add_theme_constant_override("separation", 28)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, 0)
	UiTheme.style_label(label, UiTheme.TEXT_PRIMARY, 30)
	v.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	v.add_child(row)
	var yes := Button.new()
	yes.text = "CONFIRM"
	UiTheme.style_button(yes, UiTheme.WARN, 30)
	yes.custom_minimum_size = Vector2(240, 70)
	yes.pressed.connect(func():
		layer.queue_free()
		on_yes.call())
	row.add_child(yes)
	var no := Button.new()
	no.text = "CANCEL"
	UiTheme.style_button_ghost(no, UiTheme.ACCENT_BRIGHT, 30)
	no.custom_minimum_size = Vector2(240, 70)
	no.pressed.connect(func():
		Sfx.play("click")
		layer.queue_free())
	row.add_child(no)
	add_child(layer)

func _apply_portrait_layout() -> void:
	_v.custom_minimum_size = Vector2(720, 720)
	_gems.offset_left = -320.0
	_gems.offset_top = 72.0
	_gems.offset_right = -64.0
	_gems.offset_bottom = 130.0
	for control in [_play, _daily, _shop, _quit]:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
