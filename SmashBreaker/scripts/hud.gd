extends CanvasLayer
## HUD — chip-styled overlay. Sector top-left, lives+score centre chip,
## pause top-right, power-up chips below centre.

signal pause_requested

@onready var _level_chip: PanelContainer = $LevelChip
@onready var _center_chip: PanelContainer = $CenterChip
@onready var _score_label: Label = $CenterChip/H/Score
@onready var _lives_label: Label = $CenterChip/H/Lives
@onready var _sep_label: Label = $CenterChip/H/Sep
@onready var _level_label: Label = $LevelChip/Level
@onready var _powerups: HBoxContainer = $PowerUps
@onready var _pause_button: Button = $Pause

var _displayed_score: int = 0
var _score_tween: Tween = null
var _powerup_chips: Dictionary = {}   # key -> {panel, label}

func _ready() -> void:
	GameState.score_changed.connect(_on_score)
	GameState.lives_changed.connect(_on_lives)
	GameState.level_changed.connect(_on_level)
	_level_chip.add_theme_stylebox_override("panel", UiTheme.chip(UiTheme.ACCENT))
	_center_chip.add_theme_stylebox_override("panel", UiTheme.chip(UiTheme.ACCENT))
	UiTheme.style_label(_level_label, UiTheme.ACCENT_BRIGHT, 30, true)
	UiTheme.style_label(_lives_label, Color("#ff6a9e"), 30, true)
	UiTheme.style_label(_sep_label, UiTheme.TEXT_SECONDARY, 30)
	_score_label.add_theme_font_size_override("font_size", 38)
	_score_label.add_theme_color_override("font_color", UiTheme.TEXT_PRIMARY)
	UiTheme.display(_score_label)
	UiTheme.display(_pause_button)
	_pause_button.add_theme_font_size_override("font_size", 34)
	_pause_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_pause_button.add_theme_color_override("font_hover_color", UiTheme.ACCENT_BRIGHT)
	_pause_button.pressed.connect(func(): pause_requested.emit())
	_pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_displayed_score = GameState.score
	_score_label.text = "%d" % _displayed_score
	_on_lives(GameState.lives)
	_on_level(GameState.level)

func _on_score(v: int) -> void:
	# Count-up tween: the number rolls toward the new value instead of jumping.
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.tween_method(_set_displayed_score, _displayed_score, v, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_displayed_score(v: int) -> void:
	_displayed_score = v
	_score_label.text = "%d" % v

func _on_lives(v: int) -> void:
	var dots := ""
	for i in v:
		dots += "● "
	_lives_label.text = dots.strip_edges()

func _on_level(v: int) -> void:
	if GameState.daily_mode:
		_level_label.text = "DAILY CHALLENGE"
		return
	var gname: String = Galaxies.get_by_id(GameState.current_galaxy)["name"]
	_level_label.text = "%s · %02d" % [gname, v]

func set_active_powerups(text: String) -> void:
	## Receives "WIDE 18s · FIRE 6s" style text from game.gd; renders one
	## coloured chip per active power-up.
	var wanted: Dictionary = {}
	if text.length() > 0:
		for part in text.split("·"):
			var p := part.strip_edges()
			if p.is_empty():
				continue
			var key := p.split(" ")[0]
			wanted[key] = p
	# Remove chips no longer active.
	for key in _powerup_chips.keys().duplicate():
		if not wanted.has(key):
			_powerup_chips[key]["panel"].queue_free()
			_powerup_chips.erase(key)
	# Add / update chips.
	for key in wanted.keys():
		if not _powerup_chips.has(key):
			var accent: Color = UiTheme.ACCENT
			match key:
				"WIDE": accent = UiTheme.ACCENT
				"FIRE": accent = UiTheme.WARN
			var panel := PanelContainer.new()
			panel.add_theme_stylebox_override("panel", UiTheme.chip(accent))
			var label := Label.new()
			UiTheme.style_label(label, accent, 24, true)
			panel.add_child(label)
			_powerups.add_child(panel)
			_powerup_chips[key] = {"panel": panel, "label": label}
		_powerup_chips[key]["label"].text = wanted[key]
