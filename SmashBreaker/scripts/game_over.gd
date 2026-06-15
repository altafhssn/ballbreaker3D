extends CanvasLayer
## Game Over overlay. Shown when lives reach 0.

@onready var _panel: PanelContainer = $Center/Panel
@onready var _title: Label = $Center/Panel/V/Title
@onready var _score: Label = $Center/Panel/V/Score
@onready var _high: Label = $Center/Panel/V/High
@onready var _retry: Button = $Center/Panel/V/Retry
@onready var _menu: Button = $Center/Panel/V/Menu

func _ready() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.add_theme_stylebox_override("panel", UiTheme.glass_panel(UiTheme.WARN))
	UiTheme.style_title(_title, UiTheme.WARN, 80)
	_score.text = "SCORE  %d" % GameState.score
	UiTheme.style_label(_score, UiTheme.TEXT_PRIMARY, 44, true)
	var high_text := "BEST  %d" % GameState.high_score
	if GameState.run_gems > 0:
		high_text += "      +%d ◆" % GameState.run_gems
	_high.text = high_text
	UiTheme.style_label(_high, UiTheme.GOLD, 32, true)
	UiTheme.style_button(_retry, UiTheme.ACCENT)
	UiTheme.style_button_ghost(_menu, UiTheme.ACCENT_BRIGHT)
	if GameState.daily_mode:
		# Daily challenge: one attempt — no retry.
		_retry.visible = false
	_retry.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/game.tscn"))
	_menu.pressed.connect(func():
		Sfx.play("click")
		Transition.go("res://scenes/main.tscn"))
	# Panel drops in.
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(1.1, 1.1)
	_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.25)
