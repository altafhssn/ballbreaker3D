extends CanvasLayer
## Pause overlay — glass panel with RESUME / RESTART / QUIT TO MENU.

signal resume_requested

@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/V/Title
@onready var _stats: Label = $Center/Panel/V/Stats
@onready var _resume: Button = $Center/Panel/V/Resume
@onready var _restart: Button = $Center/Panel/V/Restart
@onready var _menu: Button = $Center/Panel/V/Menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.add_theme_stylebox_override("panel", UiTheme.glass_panel(UiTheme.ACCENT))
	UiTheme.style_title(_title, UiTheme.ACCENT_BRIGHT, 72)
	_stats.text = "SECTOR %02d   ·   SCORE %d" % [GameState.level, GameState.score]
	UiTheme.style_label(_stats, UiTheme.TEXT_SECONDARY, 30, true)
	UiTheme.style_button(_resume, UiTheme.ACCENT)
	UiTheme.style_button_ghost(_restart, UiTheme.ACCENT_BRIGHT)
	UiTheme.style_button_ghost(_menu, UiTheme.WARN)
	if GameState.daily_mode:
		# Daily challenge: restarting would grant a second attempt.
		_restart.visible = false
	_resume.pressed.connect(func():
		Sfx.play("click")
		resume_requested.emit())
	_restart.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/game.tscn"))
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
