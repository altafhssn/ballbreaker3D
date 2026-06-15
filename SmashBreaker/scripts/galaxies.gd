extends Node
## Galaxies — autoload. Registry of the 10 conquest galaxies: theme palettes,
## signature mechanics, unlock rules. Phase A ships galaxies 0-2 playable;
## the rest appear on the map as COMING SOON.

const SECTORS_PER_GALAXY := 30
const STARS_TO_UNLOCK := 45     # stars needed in previous galaxy

const GALAXIES := [
	{
		"id": "cyanis", "name": "CYANIS", "playable": true,
		"tagline": "WHERE IT BEGINS",
		"mechanic": "none",
		"accent": "#4ad0ff", "accent_bright": "#7ee6ff",
		"floor_base": "#0d1422", "floor_base_2": "#06090f",
		"grid_color": "#33d9ff", "hot_color": "#f24dcc",
		"wall_hull": "#2e3852", "wall_glow": "#33d9ff",
		"env_bg": "#01030a", "ambient": "#4d80b3",
		"fill_light": "#f259d9",
		"brick_mix": {},     # defaults
	},
	{
		"id": "ember", "name": "EMBER NEBULA", "playable": true,
		"tagline": "THE BURNING SHOALS",
		"mechanic": "magma",
		"accent": "#ff8a3d", "accent_bright": "#ffc24a",
		"floor_base": "#1c0e08", "floor_base_2": "#0d0503",
		"grid_color": "#ff7a33", "hot_color": "#ffd24a",
		"wall_hull": "#4a2418", "wall_glow": "#ff8a3d",
		"env_bg": "#0a0302", "ambient": "#b3664d",
		"fill_light": "#ffae33",
		"brick_mix": {"magma_pct": 0.22},
	},
	{
		"id": "frost", "name": "FROST REACH", "playable": true,
		"tagline": "THE SLIPPING DARK",
		"mechanic": "ice",
		"accent": "#9bd7ff", "accent_bright": "#e6f7ff",
		"floor_base": "#0e1a26", "floor_base_2": "#060d14",
		"grid_color": "#bfeaff", "hot_color": "#7a8cff",
		"wall_hull": "#33495e", "wall_glow": "#bfeaff",
		"env_bg": "#020609", "ambient": "#7099b3",
		"fill_light": "#8c99ff",
		"brick_mix": {"ice_pct": 0.28},
	},
	{
		"id": "verdant", "name": "VERDANT CLUSTER", "playable": false,
		"tagline": "THE LIVING WALL", "mechanic": "roots",
		"accent": "#52ff7a", "accent_bright": "#b3ffc6",
		"floor_base": "#0a1a0e", "floor_base_2": "#040d06",
		"grid_color": "#52ff7a", "hot_color": "#ffd24a",
		"wall_hull": "#1e3a26", "wall_glow": "#52ff7a",
		"env_bg": "#020903", "ambient": "#5db377",
		"fill_light": "#a3ff52", "brick_mix": {},
	},
	{
		"id": "aurum", "name": "AURUM BELT", "playable": false,
		"tagline": "THE GOLDEN CURRENT", "mechanic": "conveyor",
		"accent": "#ffd24a", "accent_bright": "#ffe9a3",
		"floor_base": "#1a1408", "floor_base_2": "#0d0a04",
		"grid_color": "#ffd24a", "hot_color": "#ff8a3d",
		"wall_hull": "#4a3d18", "wall_glow": "#ffd24a",
		"env_bg": "#090702", "ambient": "#b39a4d",
		"fill_light": "#ffae33", "brick_mix": {},
	},
	{
		"id": "void", "name": "VIOLET VOID", "playable": false,
		"tagline": "WHERE LIGHT BENDS", "mechanic": "gravity",
		"accent": "#a06bff", "accent_bright": "#d0b3ff",
		"floor_base": "#140e26", "floor_base_2": "#0a0614",
		"grid_color": "#a06bff", "hot_color": "#ff4ad0",
		"wall_hull": "#332652", "wall_glow": "#a06bff",
		"env_bg": "#050209", "ambient": "#8066b3",
		"fill_light": "#f24dcc", "brick_mix": {},
	},
	{
		"id": "forge", "name": "CRIMSON FORGE", "playable": false,
		"tagline": "THE ADVANCING WALL", "mechanic": "advance",
		"accent": "#ff3d6e", "accent_bright": "#ff9eb8",
		"floor_base": "#260d12", "floor_base_2": "#140609",
		"grid_color": "#ff3d6e", "hot_color": "#ffd24a",
		"wall_hull": "#521f2b", "wall_glow": "#ff3d6e",
		"env_bg": "#090204", "ambient": "#b35e6e",
		"fill_light": "#ff8a3d", "brick_mix": {},
	},
	{
		"id": "ghost", "name": "GHOST EXPANSE", "playable": false,
		"tagline": "THE PHASE RHYTHM", "mechanic": "phase",
		"accent": "#cfd8e6", "accent_bright": "#ffffff",
		"floor_base": "#141821", "floor_base_2": "#0a0d12",
		"grid_color": "#cfd8e6", "hot_color": "#7a8cff",
		"wall_hull": "#3d4452", "wall_glow": "#cfd8e6",
		"env_bg": "#040507", "ambient": "#8c99b3",
		"fill_light": "#b3bfff", "brick_mix": {},
	},
	{
		"id": "storm", "name": "STORM DRIFT", "playable": false,
		"tagline": "THE CHARGED WINDS", "mechanic": "lightning",
		"accent": "#f2e64d", "accent_bright": "#fff9b3",
		"floor_base": "#1a1a08", "floor_base_2": "#0d0d04",
		"grid_color": "#f2e64d", "hot_color": "#33d9ff",
		"wall_hull": "#4a4a18", "wall_glow": "#f2e64d",
		"env_bg": "#080902", "ambient": "#b3b34d",
		"fill_light": "#33d9ff", "brick_mix": {},
	},
	{
		"id": "obsidian", "name": "OBSIDIAN CORE", "playable": false,
		"tagline": "THE FINAL REMIX", "mechanic": "boss",
		"accent": "#ff4ad0", "accent_bright": "#ff9ee6",
		"floor_base": "#0d060d", "floor_base_2": "#060306",
		"grid_color": "#ff4ad0", "hot_color": "#33d9ff",
		"wall_hull": "#33152e", "wall_glow": "#ff4ad0",
		"env_bg": "#030103", "ambient": "#80668c",
		"fill_light": "#33d9ff", "brick_mix": {},
	},
]

func count() -> int:
	return GALAXIES.size()

func get_galaxy(index: int) -> Dictionary:
	return GALAXIES[clamp(index, 0, GALAXIES.size() - 1)]

func get_by_id(id: String) -> Dictionary:
	for g in GALAXIES:
		if g["id"] == id:
			return g
	return GALAXIES[0]

func index_of(id: String) -> int:
	for i in GALAXIES.size():
		if GALAXIES[i]["id"] == id:
			return i
	return 0

func color(g: Dictionary, key: String) -> Color:
	return Color(g[key])
