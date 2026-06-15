extends Node
## Music — autoload. Loops the BGM track across every scene (autoloads
## persist through scene changes, so the music never restarts on navigation).
## Volume comes from GameState.music_volume (0..1); 0 pauses the stream.

const BGM_PATH := "res://audio/bgm_main.wav"
const BASE_DB := -12.0       # sit under the SFX at full slider
const FADE_TIME := 0.4

var _player: AudioStreamPlayer = null
var _fade_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep playing while paused
	if not ResourceLoader.exists(BGM_PATH):
		return
	# Looping is requested at import time (edit/loop_mode=1 in the .import
	# file), but as a guarantee we also restart on `finished` — if the import
	# loop metadata holds, `finished` never fires; if it doesn't (some export
	# paths drop it), this keeps the track going. The generated WAV's tail is
	# crossfaded into its head, so a restart is inaudible.
	var stream = load(BGM_PATH)
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.bus = "Master"
	add_child(_player)
	_player.finished.connect(func(): _player.play())
	_player.play()
	_apply_volume(GameState.music_volume, true)

func set_volume(v: float) -> void:
	## Called live from the settings slider.
	_apply_volume(v, false)

func _apply_volume(v: float, instant: bool) -> void:
	if _player == null:
		return
	if v <= 0.0:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		if instant:
			_player.volume_db = -60.0
			_player.stream_paused = true
		else:
			_fade_tween = create_tween()
			_fade_tween.tween_property(_player, "volume_db", -60.0, FADE_TIME)
			_fade_tween.tween_callback(func(): _player.stream_paused = true)
		return
	_player.stream_paused = false
	var target_db: float = BASE_DB + linear_to_db(clamp(v, 0.01, 1.0))
	if instant:
		_player.volume_db = target_db
	else:
		if _fade_tween and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", target_db, FADE_TIME)

func set_enabled(on: bool) -> void:
	## Back-compat shim (old toggle API).
	set_volume(GameState.music_volume if on else 0.0)
