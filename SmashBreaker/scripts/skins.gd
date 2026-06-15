extends Node
## Skins — autoload. Catalog of paddle skins purchasable with gems.
## `body` = hull albedo, `glow` = emission + floor halo + trim colour.

const CATALOG := {
	"stock": {
		"name": "STOCK INTERCEPTOR", "price": 0,
		"body": "#23365e", "glow": "#4ad0ff",
	},
	"ghost": {
		"name": "GHOST RUNNER", "price": 100,
		"body": "#dfe9f5", "glow": "#ffffff",
	},
	"toxin": {
		"name": "TOXIN", "price": 150,
		"body": "#143a22", "glow": "#52ff7a",
	},
	"ember": {
		"name": "EMBER", "price": 150,
		"body": "#3a1c10", "glow": "#ff8a3d",
	},
	"royal": {
		"name": "ROYAL VANGUARD", "price": 200,
		"body": "#2a1a4a", "glow": "#a06bff",
	},
	"solar": {
		"name": "SOLAR FLARE", "price": 250,
		"body": "#4a3210", "glow": "#ffd24a",
	},
	"crimson": {
		"name": "CRIMSON PROTOCOL", "price": 300,
		"body": "#3a0a1e", "glow": "#ff3d6e",
	},
	"void": {
		"name": "VOID WALKER", "price": 500,
		"body": "#06070d", "glow": "#ff4ad0",
	},
}

func get_skin(id: String) -> Dictionary:
	return CATALOG.get(id, CATALOG["stock"])

func body_color(id: String) -> Color:
	return Color(get_skin(id)["body"])

func glow_color(id: String) -> Color:
	return Color(get_skin(id)["glow"])
