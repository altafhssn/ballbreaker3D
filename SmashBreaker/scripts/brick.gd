extends StaticBody3D
## Brick — 3D. Box mesh on the play floor with emissive colour for the neon look.

signal destroyed(brick: Node, was_explosive: bool)

const TYPE_NORMAL := 1
const TYPE_HARD := 2
const TYPE_STEEL := 3
const TYPE_EXPLOSIVE := 4
const TYPE_GOLD := 5
const TYPE_MAGMA := 6     # Ember Nebula: regenerates HP if left alone
const TYPE_ICE := 7       # Frost Reach: shell cracks, then shatters

const MAGMA_REGEN_DELAY := 9.0   # seconds without a hit before regrowing 1 HP

# Sci-fi palette: ship-bay cargo crates / energy modules.
#  Normal     → cool teal (standard module)
#  Hard       → cyan (shielded module)
#  Steel      → gunmetal (armoured plate)
#  Explosive  → magenta (volatile core — warning colour)
#  Gold       → amber (high-value salvage)
const SPECS := {
	TYPE_NORMAL:    {"hp": 1, "points": 10,  "color": "#2a8aa6", "drop_pct": 5,  "emission": 1.0},
	TYPE_HARD:      {"hp": 2, "points": 25,  "color": "#4ad0ff", "drop_pct": 8,  "emission": 1.6},
	TYPE_STEEL:     {"hp": 3, "points": 50,  "color": "#56607a", "drop_pct": 10, "emission": 0.4},
	TYPE_EXPLOSIVE: {"hp": 1, "points": 20,  "color": "#ff4ad0", "drop_pct": 0,  "emission": 2.0},
	TYPE_GOLD:      {"hp": 1, "points": 100, "color": "#ffb84a", "drop_pct": 20, "emission": 1.8},
	TYPE_MAGMA:     {"hp": 2, "points": 30,  "color": "#ff5a26", "drop_pct": 8,  "emission": 2.2},
	TYPE_ICE:       {"hp": 2, "points": 20,  "color": "#bfeaff", "drop_pct": 6,  "emission": 1.2},
}

# Mesh dimensions (smaller than the grid pitch in game.gd so rows have gaps).
const BRICK_W := 1.22
const BRICK_H := 0.5
const BRICK_D := 0.55

var brick_type: int = TYPE_NORMAL
var hp: int = 1
var max_hp: int = 1
var points: int = 10
var color: Color = Color("#2a8aa6")   # default = Normal-type colour; configure() overwrites
var drop_pct: int = 5
var emission_strength: float = 1.0
var grid_pos: Vector2i = Vector2i.ZERO
var _regen_timer: float = 0.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shape: CollisionShape3D = $Collision

func _ready() -> void:
	add_to_group("brick")
	collision_layer = 0b001000   # Bricks (4)
	collision_mask = 0
	_build_visual()

func _process(delta: float) -> void:
	# Magma regeneration: heal 1 HP after MAGMA_REGEN_DELAY without a hit.
	if brick_type != TYPE_MAGMA or hp <= 0 or hp >= max_hp:
		return
	_regen_timer += delta
	if _regen_timer >= MAGMA_REGEN_DELAY:
		_regen_timer = 0.0
		hp += 1
		_refresh_material()
		_regen_flash()

func _regen_flash() -> void:
	# Quick scale pulse so the heal is readable.
	var tw := create_tween()
	scale = Vector3.ONE
	tw.tween_property(self, "scale", Vector3(1.12, 1.25, 1.12), 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE, 0.15) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func configure(t: int, gpos: Vector2i) -> void:
	brick_type = t
	grid_pos = gpos
	var s = SPECS[t]
	hp = s.hp
	max_hp = s.hp
	points = s.points
	color = Color(s.color)
	drop_pct = s.drop_pct
	emission_strength = s.emission
	if is_inside_tree():
		_refresh_material()

func _build_visual() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(BRICK_W, BRICK_H, BRICK_D)
	_mesh.mesh = box
	_refresh_material()
	var sh := BoxShape3D.new()
	sh.size = Vector3(BRICK_W, BRICK_H, BRICK_D)
	_shape.shape = sh

func _refresh_material() -> void:
	var mat := StandardMaterial3D.new()
	var c: Color = color
	var f: float = float(max(hp, 0)) / float(max_hp)
	if brick_type == TYPE_ICE and f < 1.0:
		# Cracked ice goes translucent-white rather than darker.
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		c = Color(0.95, 0.99, 1.0, 0.45)
	elif f < 1.0:
		# Darken slightly as HP decreases (Hard/Steel feedback).
		c = c.darkened(0.3 * (1.0 - f))
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = Color(c.r, c.g, c.b)
	mat.emission_energy_multiplier = emission_strength * max(f, 0.4)
	mat.metallic = 0.0
	mat.roughness = 0.4
	_mesh.material_override = mat

func hit(fireball: bool) -> bool:
	# Guard: already destroyed, awaiting queue_free. Prevents double-counting
	# if the ball collides with this brick again before it leaves the tree.
	if hp <= 0:
		return false
	_regen_timer = 0.0   # magma: any hit resets the heal countdown
	if fireball:
		hp = 0
	elif brick_type in [TYPE_STEEL, TYPE_HARD, TYPE_MAGMA, TYPE_ICE]:
		hp -= 1
	else:
		hp = 0
	_refresh_material()
	if hp <= 0:
		emit_signal("destroyed", self, brick_type == TYPE_EXPLOSIVE)
		call_deferred("queue_free")
		return true
	return false
