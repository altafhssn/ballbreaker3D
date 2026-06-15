extends Area3D
## PowerUp — 3D. Small cube that drifts toward the paddle (+Z) and despawns
## past the kill zone.

signal collected(type: String)

enum Type { WIDE, MULTIBALL, FIRE }

const FALL_SPEED := 3.5    # m/s along +Z
const SIZE := 0.6
const SPIN_PER_SEC := 1.5  # radians/s around Y for a bit of life
# Sci-fi palette — paddle/ship buff is cool cyan, multiball is bright sky-cyan,
# fire (overcharge) is the same magenta as the overcharged ball.
const COLORS := {
	Type.WIDE: Color("#4ad0ff"),
	Type.MULTIBALL: Color("#7ee6ff"),
	Type.FIRE: Color("#ff4ad0"),
}

var type: int = Type.WIDE

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _shape: CollisionShape3D = $Collision

func _ready() -> void:
	collision_layer = 0b010000   # PowerUp (5)
	collision_mask  = 0b100010   # Paddle (2), KillZone (6)
	monitoring = true
	monitorable = true
	_build_visual()
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)

func _build_visual() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(SIZE, SIZE, SIZE)
	_mesh.mesh = box
	var c: Color = COLORS[type]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 1.8
	mat.metallic = 0.3
	mat.roughness = 0.3
	_mesh.material_override = mat
	var sh := BoxShape3D.new()
	sh.size = Vector3(SIZE, SIZE, SIZE)
	_shape.shape = sh

func set_type(t: int) -> void:
	type = t
	if is_inside_tree():
		_build_visual()

func _process(delta: float) -> void:
	position.z += FALL_SPEED * delta
	rotate_y(SPIN_PER_SEC * delta)
	if position.z > 11.0:
		queue_free()

func _on_body(b: Node) -> void:
	if b.is_in_group("paddle"):
		_emit_collected()

func _on_area(a: Node) -> void:
	if a.is_in_group("killzone"):
		queue_free()

func _emit_collected() -> void:
	var key := ""
	match type:
		Type.WIDE: key = "wide"
		Type.MULTIBALL: key = "multiball"
		Type.FIRE: key = "fire"
	emit_signal("collected", key)
	queue_free()
