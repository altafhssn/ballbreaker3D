extends Node
## LevelGen — autoload. Generates the 30 sectors of each galaxy from a stencil
## library + per-galaxy decorator, with a deterministic seed per (galaxy,
## sector) so every player sees the same layout. Bespoke hand-built layouts
## override generation for sectors 1, 10, 20 and 30.
##
## Brick codes:
##   0 empty · 1 Normal · 2 Hard · 3 Steel · 4 Explosive · 5 Gold
##   6 Magma (regenerates) · 7 Ice (shell cracks, then shatters)

const COLS := 8
const SECTORS := 30

const POINTS := {1: 10, 2: 25, 3: 50, 4: 20, 5: 100, 6: 30, 7: 20}

# --- Stencil library ----------------------------------------------------------
# Shape-only patterns: 1 = brick cell, 0 = empty. The decorator assigns types.

const STENCILS := [
	# Solid band
	[[1,1,1,1,1,1,1,1],
	 [1,1,1,1,1,1,1,1],
	 [1,1,1,1,1,1,1,1]],
	# Checker
	[[1,0,1,0,1,0,1,0],
	 [0,1,0,1,0,1,0,1],
	 [1,0,1,0,1,0,1,0],
	 [0,1,0,1,0,1,0,1]],
	# Pyramid
	[[0,0,0,1,1,0,0,0],
	 [0,0,1,1,1,1,0,0],
	 [0,1,1,1,1,1,1,0],
	 [1,1,1,1,1,1,1,1]],
	# Twin towers
	[[1,1,0,0,0,0,1,1],
	 [1,1,0,0,0,0,1,1],
	 [1,1,0,1,1,0,1,1],
	 [1,1,0,1,1,0,1,1],
	 [1,1,0,0,0,0,1,1]],
	# Diamond
	[[0,0,0,1,1,0,0,0],
	 [0,0,1,1,1,1,0,0],
	 [0,1,1,1,1,1,1,0],
	 [0,0,1,1,1,1,0,0],
	 [0,0,0,1,1,0,0,0]],
	# Cross
	[[0,0,0,1,1,0,0,0],
	 [0,0,0,1,1,0,0,0],
	 [1,1,1,1,1,1,1,1],
	 [0,0,0,1,1,0,0,0],
	 [0,0,0,1,1,0,0,0]],
	# Frame
	[[1,1,1,1,1,1,1,1],
	 [1,0,0,0,0,0,0,1],
	 [1,0,1,1,1,1,0,1],
	 [1,0,0,0,0,0,0,1],
	 [1,1,1,1,1,1,1,1]],
	# Zigzag
	[[1,1,0,0,0,0,0,0],
	 [0,1,1,0,0,0,0,0],
	 [0,0,1,1,0,0,0,0],
	 [0,0,0,1,1,0,0,0],
	 [0,0,0,0,1,1,0,0],
	 [0,0,0,0,0,1,1,1]],
	# Arrow down
	[[1,1,1,1,1,1,1,1],
	 [0,1,1,1,1,1,1,0],
	 [0,0,1,1,1,1,0,0],
	 [0,0,0,1,1,0,0,0]],
	# Rib cage
	[[1,0,1,0,0,1,0,1],
	 [1,0,1,0,0,1,0,1],
	 [1,0,1,1,1,1,0,1],
	 [1,0,0,0,0,0,0,1],
	 [1,1,1,1,1,1,1,1]],
	# Islands
	[[1,1,0,0,1,1,0,0],
	 [1,1,0,0,1,1,0,0],
	 [0,0,1,1,0,0,1,1],
	 [0,0,1,1,0,0,1,1]],
	# Big H
	[[1,1,0,0,0,0,1,1],
	 [1,1,0,0,0,0,1,1],
	 [1,1,1,1,1,1,1,1],
	 [1,1,0,0,0,0,1,1],
	 [1,1,0,0,0,0,1,1]],
	# Staircase pair
	[[1,1,1,0,0,0,0,0],
	 [0,1,1,1,0,0,0,0],
	 [0,0,1,1,1,0,0,0],
	 [0,0,0,1,1,1,0,0],
	 [0,0,0,0,1,1,1,0],
	 [0,0,0,0,0,1,1,1]],
	# Honeycomb
	[[0,1,1,0,0,1,1,0],
	 [1,1,1,1,1,1,1,1],
	 [0,1,1,0,0,1,1,0],
	 [1,1,1,1,1,1,1,1],
	 [0,1,1,0,0,1,1,0]],
	# Gate
	[[1,1,1,1,1,1,1,1],
	 [1,1,0,0,0,0,1,1],
	 [1,1,0,0,0,0,1,1],
	 [1,1,0,0,0,0,1,1]],
	# Wings
	[[1,0,0,0,0,0,0,1],
	 [1,1,0,0,0,0,1,1],
	 [1,1,1,0,0,1,1,1],
	 [1,1,1,1,1,1,1,1],
	 [0,0,1,1,1,1,0,0]],
]

# --- Bespoke specials ---------------------------------------------------------
# Hand-built layouts (full brick codes) for the landmark sectors.

const BESPOKE := {
	"cyanis": {
		1: [[1,1,1,1,1,1,1,1],
			[1,1,1,1,1,1,1,1],
			[1,1,1,1,1,1,1,1]],
		10: [[2,2,0,5,5,0,2,2],
			[2,1,1,1,1,1,1,2],
			[0,1,4,1,1,4,1,0],
			[2,1,1,1,1,1,1,2],
			[2,2,0,5,5,0,2,2]],
		20: [[3,1,1,3,3,1,1,3],
			[1,2,1,1,1,1,2,1],
			[1,1,5,1,1,5,1,1],
			[1,2,1,1,1,1,2,1],
			[3,1,1,3,3,1,1,3]],
		30: [[3,3,3,3,3,3,3,3],
			[3,4,2,5,5,2,4,3],
			[3,2,1,1,1,1,2,3],
			[3,5,1,2,2,1,5,3],
			[3,5,1,2,2,1,5,3],
			[3,2,1,1,1,1,2,3],
			[3,4,2,5,5,2,4,3],
			[3,3,3,3,3,3,3,3]],
	},
	"ember": {
		1: [[1,1,1,1,1,1,1,1],
			[1,1,6,6,6,6,1,1],
			[1,1,1,1,1,1,1,1]],
		10: [[6,6,0,4,4,0,6,6],
			[6,1,1,1,1,1,1,6],
			[0,1,5,2,2,5,1,0],
			[6,1,1,1,1,1,1,6],
			[6,6,0,4,4,0,6,6]],
		20: [[6,2,6,2,2,6,2,6],
			[2,6,2,6,6,2,6,2],
			[6,2,6,2,2,6,2,6],
			[2,6,2,6,6,2,6,2]],
		30: [[3,6,6,3,3,6,6,3],
			[6,4,2,5,5,2,4,6],
			[6,2,6,1,1,6,2,6],
			[3,5,1,6,6,1,5,3],
			[3,5,1,6,6,1,5,3],
			[6,2,6,1,1,6,2,6],
			[6,4,2,5,5,2,4,6],
			[3,6,6,3,3,6,6,3]],
	},
	"frost": {
		1: [[1,1,1,1,1,1,1,1],
			[1,7,7,1,1,7,7,1],
			[1,1,1,1,1,1,1,1]],
		10: [[7,7,0,5,5,0,7,7],
			[7,1,1,2,2,1,1,7],
			[0,1,4,1,1,4,1,0],
			[7,1,1,2,2,1,1,7],
			[7,7,0,5,5,0,7,7]],
		20: [[7,7,7,7,7,7,7,7],
			[7,3,1,1,1,1,3,7],
			[7,1,5,1,1,5,1,7],
			[7,3,1,1,1,1,3,7],
			[7,7,7,7,7,7,7,7]],
		30: [[3,7,7,3,3,7,7,3],
			[7,4,2,5,5,2,4,7],
			[7,2,7,1,1,7,2,7],
			[3,5,1,7,7,1,5,3],
			[3,5,1,7,7,1,5,3],
			[7,2,7,1,1,7,2,7],
			[7,4,2,5,5,2,4,7],
			[3,7,7,3,3,7,7,3]],
	},
}

# --- Generation ---------------------------------------------------------------

func get_level(galaxy_id: String, sector: int) -> Dictionary:
	## Returns { "layout": Array, "no_drops": bool }.
	sector = clamp(sector, 1, SECTORS)
	var no_drops := (sector == 20)   # sector 20 = gauntlet, pure skill
	if BESPOKE.has(galaxy_id) and BESPOKE[galaxy_id].has(sector):
		return {"layout": BESPOKE[galaxy_id][sector], "no_drops": no_drops}
	var g: Dictionary = Galaxies.get_by_id(galaxy_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [galaxy_id, sector])
	# Pick a stencil; later sectors draw from the whole library, early ones
	# from the simpler half.
	var max_idx: int = STENCILS.size() if sector > 8 else STENCILS.size() / 2
	var stencil: Array = STENCILS[rng.randi() % max_idx]
	var mirrored: bool = rng.randf() < 0.5
	var layout: Array = []
	for row in stencil:
		var out_row: Array = []
		for c in range(COLS):
			var src: int = row[COLS - 1 - c] if mirrored else row[c]
			out_row.append(_decorate_cell(src, sector, g, rng))
		layout.append(out_row)
	return {"layout": layout, "no_drops": no_drops}

func _decorate_cell(filled: int, sector: int, g: Dictionary, rng: RandomNumberGenerator) -> int:
	if filled == 0:
		return 0
	var t: float = float(sector) / float(SECTORS)   # difficulty 0..1
	var mix: Dictionary = g.get("brick_mix", {})
	var roll := rng.randf()
	# Galaxy-signature bricks claim their share first.
	var magma_pct: float = mix.get("magma_pct", 0.0) * (0.5 + t)
	var ice_pct: float = mix.get("ice_pct", 0.0) * (0.5 + t)
	if roll < magma_pct:
		return 6
	roll -= magma_pct
	if roll < ice_pct:
		return 7
	roll -= ice_pct
	# Standard difficulty curve.
	var steel_pct: float = lerp(0.0, 0.14, t) if sector > 6 else 0.0
	var hard_pct: float = lerp(0.05, 0.30, t)
	var explosive_pct: float = 0.06 if sector > 4 else 0.0
	var gold_pct := 0.08
	if roll < steel_pct:
		return 3
	roll -= steel_pct
	if roll < hard_pct:
		return 2
	roll -= hard_pct
	if roll < explosive_pct:
		return 4
	roll -= explosive_pct
	if roll < gold_pct:
		return 5
	return 1

func get_daily(date_str: String) -> Dictionary:
	## Daily challenge: one seeded level per UTC date, identical for every
	## player. Rotates through the playable galaxies (so the daily can land
	## on magma or ice days), difficulty pinned to the spicy mid-range.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("daily:%s" % date_str)
	var playable: Array = []
	for g in Galaxies.GALAXIES:
		if g["playable"]:
			playable.append(g)
	var g: Dictionary = playable[rng.randi() % playable.size()]
	var sector_difficulty: int = 12 + (rng.randi() % 14)   # 12..25 of 30
	var stencil: Array = STENCILS[rng.randi() % STENCILS.size()]
	var mirrored: bool = rng.randf() < 0.5
	var layout: Array = []
	for row in stencil:
		var out_row: Array = []
		for c in range(COLS):
			var src: int = row[COLS - 1 - c] if mirrored else row[c]
			out_row.append(_decorate_cell(src, sector_difficulty, g, rng))
		layout.append(out_row)
	return {"layout": layout, "no_drops": false, "galaxy_id": g["id"]}

func sum_brick_score(layout: Array) -> int:
	var total := 0
	for row in layout:
		for code in row:
			if POINTS.has(code):
				total += POINTS[code]
	return total
