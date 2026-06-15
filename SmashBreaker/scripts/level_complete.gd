extends CanvasLayer
## Level Complete overlay — stars, score, gem reward, NEXT SECTOR.

signal next_requested

@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/V/Title
@onready var _stars_label: Label = $Center/Panel/V/Stars
@onready var _score_line: Label = $Center/Panel/V/ScoreLine
@onready var _gem_line: Label = $Center/Panel/V/GemLine
@onready var _next: Button = $Center/Panel/V/Next
@onready var _menu: Button = $Center/Panel/V/Menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.add_theme_stylebox_override("panel", UiTheme.glass_panel(UiTheme.GOLD))
	UiTheme.style_title(_title, UiTheme.ACCENT_BRIGHT, 64)
	_stars_label.add_theme_font_size_override("font_size", 76)
	UiTheme.style_label(_score_line, UiTheme.TEXT_PRIMARY, 34, true)
	UiTheme.style_label(_gem_line, UiTheme.GOLD, 34, true)
	UiTheme.style_button(_next, UiTheme.ACCENT)
	UiTheme.style_button_ghost(_menu, UiTheme.WARN)
	_next.pressed.connect(func():
		Sfx.play("click")
		next_requested.emit()
		queue_free())
	_menu.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/main.tscn"))
	# Panel scales in.
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.85, 0.85)
	_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)

func setup_daily(stars: int, level_score: int, gems: int) -> void:
	setup(0, stars, level_score, gems, false)
	_title.text = "DAILY COMPLETE"
	_next.text = "RETURN"

func setup(level: int, stars: int, level_score: int, gems: int, is_last: bool = false) -> void:
	_title.text = "SECTOR %02d CLEARED" % level
	if is_last:
		_title.text = "GALAXY CONQUERED"
		_next.text = "RETURN TO STAR CHART"
	var s := ""
	for i in 3:
		s += ("★ " if i < stars else "☆ ")
	_stars_label.text = s.strip_edges()
	_stars_label.add_theme_color_override(
		"font_color", UiTheme.GOLD if stars >= 2 else UiTheme.ACCENT_BRIGHT)
	_score_line.text = "SECTOR SCORE   %d" % level_score
	_gem_line.text = "+%d ◆ COLLECTED" % gems
	# Stars pop in after the panel lands.
	_stars_label.pivot_offset = _stars_label.size * 0.5
	_stars_label.scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_interval(0.15)
	tw.tween_property(_stars_label, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
