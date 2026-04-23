class_name FactionsData

enum Faction {PIRATE, MERCHANT, NAVY, SLAVER, CARTOGRAPHER, BOUNTYHUNTER, VIKING}

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

static var enemy_factions := {
	FactionsData.Faction.NAVY: [FactionsData.Faction.PIRATE, FactionsData.Faction.SLAVER],
	FactionsData.Faction.PIRATE: [FactionsData.Faction.NAVY, FactionsData.Faction.MERCHANT, FactionsData.Faction.BOUNTYHUNTER],
	FactionsData.Faction.MERCHANT: [FactionsData.Faction.PIRATE],
	FactionsData.Faction.SLAVER: [FactionsData.Faction.NAVY],
	FactionsData.Faction.BOUNTYHUNTER: [FactionsData.Faction.PIRATE],
}

static func is_enemy(f1, f2) -> bool:
	return enemy_factions.get(f1, []).has(f2)

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
			var attack = randf_range(0.5, 2.5)
			var defense = randf_range(0.5, 2.0)
			var max_speed = randf_range(3, 5)
			var guns = randi_range(2, 6)
			var max_hp = randi_range(50, 100)
			var gold = randi_range(0, 100)
			var supplies = randi_range(50, 200)
			var max_crew = randi_range(25, 100)
			return FactionStats.new(attack, defense, max_speed, guns, max_hp, gold, supplies, max_crew)
		Faction.MERCHANT:
			var attack = randf_range(0.5, 1.0)
			var defense = randf_range(0.5, 3.0)
			var max_speed = randf_range(3, 5)
			var guns = randi_range(0, 2)
			var max_hp = randi_range(50, 200)
			var gold = randi_range(200, 500)
			var supplies = randi_range(50, 200)
			var max_crew = randi_range(25, 50)
			return FactionStats.new(attack, defense, max_speed, guns, max_hp, gold, supplies, max_crew)
		Faction.NAVY:
			var attack = randf_range(1, 3)
			var defense = randf_range(1, 3)
			var max_speed = randf_range(2, 5)
			var guns = randi_range(2, 6)
			var max_hp = randi_range(50, 150)
			var gold = randi_range(50, 100)
			var supplies = randi_range(50, 150)
			var max_crew = randi_range(50, 200)
			return FactionStats.new(attack, defense, max_speed, guns, max_hp, gold, supplies, max_crew)
		Faction.SLAVER:
			var attack = randf_range(0.5, 2.0)
			var defense = randf_range(0.5, 2.0)
			var max_speed = randf_range(1, 5)
			var guns = randi_range(1, 4)
			var max_hp = randi_range(50, 150)
			var gold = randi_range(50, 300)
			var supplies = randi_range(50, 100)
			var max_crew = randi_range(50, 150)
			return FactionStats.new(attack, defense, max_speed, guns, max_hp, gold, supplies, max_crew)
		_:
			var attack = randf_range(0.5, 1.0)
			var defense = randf_range(0.5, 1.0)
			var max_speed = randf_range(0.5, 2.5)
			var guns = randi_range(0, 2)
			var max_hp = randi_range(20, 50)
			var gold = randi_range(0, 50)
			var supplies = randi_range(0, 50)
			var max_crew = randi_range(10, 20)
			return FactionStats.new(attack, defense, max_speed, guns, max_hp, gold, supplies, max_crew)
