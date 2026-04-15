class_name ShipNames

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