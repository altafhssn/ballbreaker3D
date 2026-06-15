extends Node
## GameState — autoloaded singleton. Run-scope state (score, lives, sector)
## plus persistent state (high score, gems, skins, per-galaxy conquest
## progress) in user://save.cfg.

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal level_changed(new_level: int)
signal gems_changed(new_gems: int)

const SAVE_PATH := "user://save.cfg"
const MAX_LIVES := 5
const LIFE_GAIN_INTERVAL := 10_000  # +1 life per 10k points

# Run-scope
var score: int = 0
var lives: int = 3
var level: int = 1                  # current sector within current_galaxy
var run_gems: int = 0
var pending_sector: int = 1         # sector to start at when game.tscn loads
var _last_life_gain_threshold: int = 0

# Persistent
var high_score: int = 0
var total_bricks_broken: int = 0
var gems: int = 0
var owned_skins: Array = ["stock"]
var selected_skin: String = "stock"
var seen_bricks: Array = []           # brick type ids the codex has introduced
var all_unlocked: bool = false        # "open all sectors" option
var sfx_enabled: bool = true          # legacy flag; volume 0 now means "off"
var music_enabled: bool = true
var sfx_volume: float = 1.0           # 0..1 linear
var music_volume: float = 1.0
# Daily challenge
var daily_mode: bool = false          # runtime: current run is the daily
var daily_last_date: String = ""      # persisted: last date an attempt was used
var daily_best: int = 0
var current_galaxy: String = "cyanis"
# galaxy_progress[id] = {"unlocked": int (highest reachable sector),
#                        "stars": {sector_string: int}}
var galaxy_progress: Dictionary = {}

func _ready() -> void:
	load_save()

func reset_run() -> void:
	score = 0
	lives = 3
	run_gems = 0
	_last_life_gain_threshold = 0
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func add_score(amount: int) -> void:
	score += amount
	emit_signal("score_changed", score)
	while score >= _last_life_gain_threshold + LIFE_GAIN_INTERVAL:
		_last_life_gain_threshold += LIFE_GAIN_INTERVAL
		if lives < MAX_LIVES:
			lives += 1
			emit_signal("lives_changed", lives)

func lose_life() -> bool:
	lives -= 1
	emit_signal("lives_changed", lives)
	return lives > 0

func set_level(n: int) -> void:
	level = n
	emit_signal("level_changed", level)

func on_game_over() -> void:
	if score > high_score:
		high_score = score
	save()

func brick_broken() -> void:
	total_bricks_broken += 1

# --- Galaxy progress ----------------------------------------------------------

func _progress(galaxy_id: String) -> Dictionary:
	if not galaxy_progress.has(galaxy_id):
		galaxy_progress[galaxy_id] = {"unlocked": 1, "stars": {}}
	return galaxy_progress[galaxy_id]

func sector_unlocked(galaxy_id: String) -> int:
	if all_unlocked:
		return Galaxies.SECTORS_PER_GALAXY
	return int(_progress(galaxy_id).get("unlocked", 1))

func get_sector_stars(galaxy_id: String, sector: int) -> int:
	return int(_progress(galaxy_id)["stars"].get(str(sector), 0))

func galaxy_stars_total(galaxy_id: String) -> int:
	var total := 0
	for v in _progress(galaxy_id)["stars"].values():
		total += int(v)
	return total

func record_sector_result(galaxy_id: String, sector: int, stars: int) -> void:
	var p := _progress(galaxy_id)
	var key := str(sector)
	if stars > int(p["stars"].get(key, 0)):
		p["stars"][key] = stars
	if sector >= int(p["unlocked"]) and sector < Galaxies.SECTORS_PER_GALAXY:
		p["unlocked"] = sector + 1
	if score > high_score:
		high_score = score
	save()

func is_galaxy_unlocked(index: int) -> bool:
	if not Galaxies.get_galaxy(index)["playable"]:
		return false
	if index == 0 or all_unlocked:
		return true
	var prev: Dictionary = Galaxies.get_galaxy(index - 1)
	return galaxy_stars_total(prev["id"]) >= Galaxies.STARS_TO_UNLOCK

func unlock_all() -> void:
	all_unlocked = true
	save()

func reset_progress() -> void:
	## Full wipe: conquest, economy, codex, daily, records. Keeps audio
	## settings — players resetting a game don't expect their volume to reset.
	high_score = 0
	total_bricks_broken = 0
	gems = 0
	run_gems = 0
	owned_skins = ["stock"]
	selected_skin = "stock"
	galaxy_progress = {}
	seen_bricks = []
	daily_last_date = ""
	daily_best = 0
	all_unlocked = false
	current_galaxy = "cyanis"
	emit_signal("gems_changed", gems)
	save()

func total_stars() -> int:
	var total := 0
	for id in galaxy_progress.keys():
		total += galaxy_stars_total(id)
	return total

# --- Gems & skins ------------------------------------------------------------

func add_gems(n: int) -> void:
	gems += n
	run_gems += n
	emit_signal("gems_changed", gems)

func buy_skin(id: String) -> bool:
	if owned_skins.has(id):
		return false
	var price: int = Skins.get_skin(id)["price"]
	if gems < price:
		return false
	gems -= price
	owned_skins.append(id)
	emit_signal("gems_changed", gems)
	save()
	return true

func equip_skin(id: String) -> void:
	if owned_skins.has(id):
		selected_skin = id
		save()

# --- Settings ------------------------------------------------------------------

func set_sfx_enabled(on: bool) -> void:
	sfx_enabled = on
	save()

func set_music_enabled(on: bool) -> void:
	music_enabled = on
	save()

func set_sfx_volume(v: float, persist: bool = true) -> void:
	sfx_volume = clamp(v, 0.0, 1.0)
	sfx_enabled = sfx_volume > 0.0
	if persist:
		save()

func set_music_volume(v: float, persist: bool = true) -> void:
	music_volume = clamp(v, 0.0, 1.0)
	music_enabled = music_volume > 0.0
	if persist:
		save()

# --- Brick codex -----------------------------------------------------------------

func is_brick_seen(t: int) -> bool:
	return seen_bricks.has(t)

func mark_brick_seen(t: int, persist: bool = false) -> void:
	if not seen_bricks.has(t):
		seen_bricks.append(t)
	if persist:
		save()

# --- Daily challenge -----------------------------------------------------------

func _today() -> String:
	return Time.get_date_string_from_system(true)   # UTC — same day worldwide

func daily_available() -> bool:
	return daily_last_date != _today()

func start_daily() -> void:
	## Marks the attempt as used the moment the run launches — quitting or
	## dying still consumes the day, per "one attempt per day".
	daily_last_date = _today()
	daily_mode = true
	save()

func complete_daily(final_score: int) -> void:
	if final_score > daily_best:
		daily_best = final_score
	save()

# --- Persistence -----------------------------------------------------------

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "high_score", high_score)
	cfg.set_value("player", "total_bricks_broken", total_bricks_broken)
	cfg.set_value("player", "current_galaxy", current_galaxy)
	cfg.set_value("player", "seen_bricks", seen_bricks)
	cfg.set_value("player", "all_unlocked", all_unlocked)
	cfg.set_value("progress", "galaxy_progress", galaxy_progress)
	cfg.set_value("shop", "gems", gems)
	cfg.set_value("shop", "owned_skins", owned_skins)
	cfg.set_value("shop", "selected_skin", selected_skin)
	cfg.set_value("settings", "sfx_enabled", sfx_enabled)
	cfg.set_value("settings", "music_enabled", music_enabled)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("daily", "last_date", daily_last_date)
	cfg.set_value("daily", "best", daily_best)
	cfg.save(SAVE_PATH)

func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = cfg.get_value("player", "high_score", 0)
	total_bricks_broken = cfg.get_value("player", "total_bricks_broken", 0)
	current_galaxy = cfg.get_value("player", "current_galaxy", "cyanis")
	seen_bricks = cfg.get_value("player", "seen_bricks", [])
	all_unlocked = cfg.get_value("player", "all_unlocked", false)
	galaxy_progress = cfg.get_value("progress", "galaxy_progress", {})
	gems = cfg.get_value("shop", "gems", 0)
	owned_skins = cfg.get_value("shop", "owned_skins", ["stock"])
	selected_skin = cfg.get_value("shop", "selected_skin", "stock")
	sfx_enabled = cfg.get_value("settings", "sfx_enabled", true)
	music_enabled = cfg.get_value("settings", "music_enabled", true)
	# Volumes: migrate from the old on/off flags if absent.
	sfx_volume = cfg.get_value("settings", "sfx_volume", 1.0 if sfx_enabled else 0.0)
	music_volume = cfg.get_value("settings", "music_volume", 1.0 if music_enabled else 0.0)
	daily_last_date = cfg.get_value("daily", "last_date", "")
	daily_best = cfg.get_value("daily", "best", 0)
	if not owned_skins.has("stock"):
		owned_skins.append("stock")
	if not owned_skins.has(selected_skin):
		selected_skin = "stock"
	_migrate_legacy(cfg)

func _migrate_legacy(cfg: ConfigFile) -> void:
	## Pre-galaxy saves stored a flat level_unlocked + stars dict. Map them
	## onto Cyanis so nobody loses progress.
	if galaxy_progress.has("cyanis"):
		return
	var legacy_unlocked: int = cfg.get_value("player", "level_unlocked", 0)
	var legacy_stars: Dictionary = cfg.get_value("player", "stars", {})
	if legacy_unlocked <= 0 and legacy_stars.is_empty():
		return
	galaxy_progress["cyanis"] = {
		"unlocked": clamp(legacy_unlocked, 1, Galaxies.SECTORS_PER_GALAXY),
		"stars": legacy_stars.duplicate(),
	}
	save()
