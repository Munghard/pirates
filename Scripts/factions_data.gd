class_name FactionsData

enum Faction {PIRATE, MERCHANT, NAVY, SLAVER, CARTOGRAPHER, BOUNTYHUNTER}

const FACTION_NAMES = {
	Faction.PIRATE: "Pirate",
	Faction.MERCHANT: "Merchant",
	Faction.NAVY: "Navy",
	Faction.SLAVER: "Slaver",
	Faction.CARTOGRAPHER: "Cartographer",
	Faction.BOUNTYHUNTER: "Bounty Hunter",
}

const NAMES = [
	"Black Marrow",
	"Crimson Tide",
	"Sea Reaper",
	"Widow’s Wake",
	"The Drowned Queen",
	"Salted Vengeance",
	"Iron Tempest",
	"Broken Compass",
	"Storm Chaser",
	"Dead Man’s Drift",

	"Hollow Siren",
	"Ghost of Brine",
	"The Wailing Hull",
	"Cursebound",
	"Ashen Leviathan",
	"Bonewake",
	"Nocturne Drifter",
	"The Silent Abyss",
	"Gravewater",
	"Revenant Wake",

	"Windknife",
	"Skydancer",
	"Swift Current",
	"Blue Needle",
	"The Gale Fox",
	"Ripple Runner",
	"Drift Sparrow",
	"Cutwater",
	"White Wake",
	"Ember Skiff",

	"Iron Bastion",
	"Kraken’s Fist",
	"The Bulwark",
	"Stormbreaker",
	"Leviathan’s Will",
	"Crownbreaker",
	"Sea Hammer",
	"Obsidian Hull",
	"Titan’s Wake",
	"Bastion of Salt",

	"Rum Before Dawn",
	"The Last Barrel",
	"Slightly Sinking",
	"Probably Not Stolen",
	"The Drunk Seagull",
	"Barnacle Buffet",
	"The Lost Oar",
	"Ship Happens",
	"Floaty McFloatface",
	"The Leaky Bucket"
]

static func get_random_name() -> String:
	return NAMES[randi() % NAMES.size()]

static func get_faction_color(faction: Faction) -> Color:
	var color: Color
	match faction:
		Faction.PIRATE:
			color = Color(1, 0.2, 0)
		Faction.MERCHANT:
			color = Color(0, 1, 0.5)
		Faction.NAVY:
			color = Color(0, 0.5, 1)
		Faction.SLAVER:
			color = Color(0.5, 0.5, 0.5)
		_:
			color = Color(1, 1, 1)
	return color

static func get_faction_icon(faction: Faction) -> Texture:
	var texture: Texture
	match faction:
		Faction.PIRATE:
			texture = preload("res://Textures/pirate-flag.png")
		Faction.MERCHANT:
			texture = preload("res://Textures/scales.png")
		Faction.NAVY:
			texture = preload("res://Textures/anchor.png")
		Faction.SLAVER:
			texture = preload("res://Textures/handcuffs.png")
		_:
			texture = preload("res://Textures/sailboat.png")
	return texture

static func get_faction_stats(faction: Faction) -> FactionStats:
	match faction:
		Faction.PIRATE:
			return FactionStats.new(1.5, 1.0, 4.0, 4, 75.0, 75, 100, 100)
		Faction.MERCHANT:
			return FactionStats.new(0.5, 0.75, 5.0, 1, 10.0, 200, 50, 50)
		Faction.NAVY:
			return FactionStats.new(1.0, 1.5, 3.0, 6, 75.0, 50, 150, 200)
		Faction.SLAVER:
			return FactionStats.new(0.5, 0.5, 3.5, 2, 50.0, 20, 75, 150)
		_:
			return FactionStats.new(0.5, 0.5, 2.5, 0, 50.0, 20, 20, 10)
