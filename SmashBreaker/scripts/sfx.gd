extends Node
## Sfx — autoload. Pool of AudioStreamPlayers for one-shot sounds.
## Respects GameState.sfx_enabled. Keeps playing while the tree is paused
## (UI clicks during pause menus).

const SOUND_NAMES := [
	"brick_hit", "brick_break", "paddle_hit", "wall_hit", "explosion",
	"powerup", "life_lost", "level_complete", "game_over",
	"click", "purchase", "denied",
]
const POOL_SIZE := 10

var _streams := {}
var _pool: Array = []
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Global volume: -6 dB ≈ 50% amplitude on everything (SFX + music).
	AudioServer.set_bus_volume_db(0, -6.0)
	for n in SOUND_NAMES:
		var path := "res://audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)

func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if GameState.sfx_volume <= 0.0:
		return
	if not _streams.has(sound):
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[sound]
	p.volume_db = volume_db + linear_to_db(GameState.sfx_volume)
	p.pitch_scale = pitch
	p.play()

func play_varied(sound: String, volume_db: float = 0.0) -> void:
	## Slight random pitch so repeated hits don't sound robotic.
	play(sound, volume_db, randf_range(0.92, 1.08))
