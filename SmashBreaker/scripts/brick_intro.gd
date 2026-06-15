extends CanvasLayer
## BrickIntro — first-encounter codex popup. Shows a live rotating 3D preview
## of the brick (own_world_3d so its collider never touches the game world),
## a codex name, stat line and behaviour description. Shown once per brick
## type per save; game.gd queues and pauses while these are up.

signal dismissed

const BrickScene := preload("res://scenes/brick.tscn")
const BrickScript := preload("res://scripts/brick.gd")

const CODEX := {
	BrickScript.TYPE_NORMAL: {
		"name": "STANDARD MODULE",
		"desc": "One clean hit and it's gone.",
	},
	BrickScript.TYPE_HARD: {
		"name": "SHIELDED MODULE",
		"desc": "Takes two hits — the shell darkens once it's cracked.",
	},
	BrickScript.TYPE_STEEL: {
		"name": "ARMOURED PLATE",
		"desc": "Three hits of stubborn metal. Fireball burns straight through.",
	},
	BrickScript.TYPE_EXPLOSIVE: {
		"name": "VOLATILE CORE",
		"desc": "Detonates everything around it when destroyed — chains love company.",
	},
	BrickScript.TYPE_GOLD: {
		"name": "SALVAGE CACHE",
		"desc": "Big points, and the best chance of dropping a power-up.",
	},
	BrickScript.TYPE_MAGMA: {
		"name": "MAGMA CELL",
		"desc": "Heals itself if left cracked too long. Finish what you start.",
	},
	BrickScript.TYPE_ICE: {
		"name": "ICE SHELL",
		"desc": "First hit cracks it translucent — the second shatters it.",
	},
}

@onready var _panel: PanelContainer = $Center/Panel
@onready var _tag: Label = $Center/Panel/V/Tag
@onready var _name_label: Label = $Center/Panel/V/Name
@onready var _stats: Label = $Center/Panel/V/Stats
@onready var _desc: Label = $Center/Panel/V/Desc
@onready var _got_it: Button = $Center/Panel/V/GotIt
@onready var _holder: Node3D = $Center/Panel/V/ViewHolder/ViewContainer/View/BrickHolder

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiTheme.style_label(_tag, UiTheme.TEXT_SECONDARY, 24, true)
	UiTheme.style_label(_stats, UiTheme.GOLD, 28, true)
	UiTheme.style_label(_desc, UiTheme.TEXT_PRIMARY, 28)
	_got_it.pressed.connect(func():
		Sfx.play("click")
		dismissed.emit()
		queue_free())

func setup(brick_type: int) -> void:
	var spec: Dictionary = BrickScript.SPECS[brick_type]
	var color := Color(spec["color"])
	var entry: Dictionary = CODEX.get(brick_type, {"name": "UNKNOWN", "desc": ""})
	_panel.add_theme_stylebox_override("panel", UiTheme.glass_panel(color))
	UiTheme.style_title(_name_label, color, 46)
	_name_label.text = entry["name"]
	var hits: int = spec["hp"]
	_stats.text = "%d HIT%s   ·   +%d PTS" % [hits, "S" if hits > 1 else "", spec["points"]]
	_desc.text = entry["desc"]
	UiTheme.style_button(_got_it, color, 36)
	# Live brick in the preview world, tilted for a 3/4 view.
	var brick := BrickScene.instantiate()
	brick.configure(brick_type, Vector2i.ZERO)
	_holder.add_child(brick)
	_holder.rotation.x = 0.42
	# Discovery sting + panel pop-in.
	Sfx.play("powerup", -4.0)
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)

func _process(delta: float) -> void:
	_holder.rotation.y += delta * 0.9
