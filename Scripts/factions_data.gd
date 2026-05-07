extends Node

class_name FactionsData

enum Nation {ENGLAND, SPAIN, FRANCE, NETHERLANDS}
const NATION_NAMES = {
	Nation.ENGLAND: "ENGLAND",
	Nation.SPAIN: "SPAIN",
	Nation.FRANCE: "FRANCE",
	Nation.NETHERLANDS: "NETHERLANDS",
}

const NATION_FLAGS = {
	Nation.ENGLAND: preload("res://Textures/Flag_of_the_United_Kingdom.png"),
	Nation.SPAIN: preload("res://Textures/Bandera_de_España.png"),
	Nation.FRANCE: preload("res://Textures/flag_of_France.png"),
	Nation.NETHERLANDS: preload("res://Textures/Flag_of_the_Netherlands.png")
}
static func get_flag(nation: Nation, faction: Faction) -> Texture2D:
	var flag = NATION_FLAGS.get(nation)
	if faction == Faction.PIRATE:
		flag = preload("res://Textures/Pirate_Flag_of_Jack_Rackham.png")
	return flag

enum Faction {PIRATE, MERCHANT, NAVY, SLAVER, CARTOGRAPHER, BOUNTYHUNTER, VIKING, FISHERMAN}

const FACTION_NAMES = {
	Faction.PIRATE: "Pirate",
	Faction.MERCHANT: "Merchant",
	Faction.NAVY: "Navy",
	Faction.SLAVER: "Slaver",
	Faction.CARTOGRAPHER: "Cartographer",
	Faction.BOUNTYHUNTER: "Bounty Hunter",
	Faction.VIKING: "Viking",
	Faction.FISHERMAN: "Fisherman",
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

const PORT_NAMES = [
	"Blackwater Port",
	"Saltmarrow",
	"Driftwood Haven",
	"Redwake Harbor",
	"Ironhook Bay",
	"Stormreach Port",
	"Gull’s Rest",
	"Broken Mast Cove",
	"Widow’s Anchorage",
	"Brinewatch",
	"Daggerfall Cove",
	"Bloodtide Harbor",
	"Blackreef Port",
	"Hangman’s Bay",
	"Scarshore",
	"Deadman’s Wake",
	"Rusthook Anchorage",
	"Thieves’ Refuge",
	"Grimwater Port",
	"Crowscar Dock",
]

static func get_enemy_factions(f1: FactionsData.Faction) -> Array[FactionsData.Faction]:
	match f1:
		FactionsData.Faction.NAVY:
			return [FactionsData.Faction.PIRATE, FactionsData.Faction.SLAVER, FactionsData.Faction.VIKING]
		FactionsData.Faction.PIRATE:
			return [FactionsData.Faction.NAVY, FactionsData.Faction.MERCHANT, FactionsData.Faction.BOUNTYHUNTER, FactionsData.Faction.VIKING]
		FactionsData.Faction.MERCHANT:
			return [FactionsData.Faction.PIRATE]
		FactionsData.Faction.SLAVER:
			return [FactionsData.Faction.NAVY]
		FactionsData.Faction.BOUNTYHUNTER:
			return [FactionsData.Faction.PIRATE]
		FactionsData.Faction.VIKING:
			return [FactionsData.Faction.NAVY, FactionsData.Faction.MERCHANT, FactionsData.Faction.PIRATE]
		_:
			return []


static func is_enemy(f1, f2) -> bool:
	return get_enemy_factions(f1).has(f2)

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
			color = Color(0.8, 0.5, 0.8)
		_:
			color = Color(0.5, 0.5, 0.5)
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
		Faction.FISHERMAN:
			texture = preload("res://Textures/fishing-net.png")
		Faction.BOUNTYHUNTER:
			texture = preload("res://Textures/wanted-reward.png")
		Faction.VIKING:
			texture = preload("res://Textures/viking-helmet.png")
		_:
			texture = preload("res://Textures/sailboat.png")
	return texture

static func get_faction_stats(faction: Faction) -> ShipStats:
	match faction:
		Faction.PIRATE:
			var attack = randf_range(0.5, 2.5)
			var defense = randf_range(0.5, 2.0)
			var max_speed = randf_range(3, 5)
			var max_hp = randi_range(50, 100)
			var gold = randi_range(0, 100)
			var max_crew = randi_range(25, 100)
			return ShipStats.new(attack, defense, max_speed, max_hp, gold, max_crew)
		Faction.MERCHANT:
			var attack = randf_range(0.5, 1.0)
			var defense = randf_range(0.5, 3.0)
			var max_speed = randf_range(3, 5)
			var max_hp = randi_range(50, 200)
			var gold = randi_range(200, 500)
			var max_crew = randi_range(25, 50)
			return ShipStats.new(attack, defense, max_speed, max_hp, gold, max_crew)
		Faction.NAVY:
			var attack = randf_range(1, 3)
			var defense = randf_range(1, 3)
			var max_speed = randf_range(2, 5)
			var max_hp = randi_range(50, 150)
			var gold = randi_range(50, 100)
			var max_crew = randi_range(50, 200)
			return ShipStats.new(attack, defense, max_speed, max_hp, gold, max_crew)
		Faction.SLAVER:
			var attack = randf_range(0.5, 2.0)
			var defense = randf_range(0.5, 2.0)
			var max_speed = randf_range(1, 5)
			var max_hp = randi_range(50, 150)
			var gold = randi_range(50, 300)
			var max_crew = randi_range(50, 150)
			return ShipStats.new(attack, defense, max_speed, max_hp, gold, max_crew)
		_:
			var attack = randf_range(0.5, 1.0)
			var defense = randf_range(0.5, 1.0)
			var max_speed = randf_range(0.5, 2.5)
			var max_hp = randi_range(20, 50)
			var gold = randi_range(0, 50)
			var max_crew = randi_range(10, 20)
			return ShipStats.new(attack, defense, max_speed, max_hp, gold, max_crew)

static func get_faction_inventory(faction: Faction) -> Array[InventoryItem]:
	var items: Array[InventoryItem]
	match faction:
		Faction.PIRATE:
			items = [
				InventoryItem.new(0, randi_range(5, 50)),
				InventoryItem.new(1, randi_range(5, 50)),
				InventoryItem.new(2, randi_range(1, 6)),
			]
		Faction.MERCHANT:
			items = [
				InventoryItem.new(0, randi_range(5, 50)),
				InventoryItem.new(1, randi_range(5, 25)),
				InventoryItem.new(3, randi_range(1, 10)),
				InventoryItem.new(4, randi_range(1, 10)),
				InventoryItem.new(6, randi_range(1, 10)),
				InventoryItem.new(8, randi_range(1, 10)),
			]
		Faction.NAVY:
			items = [
				InventoryItem.new(0, randi_range(1, 50)),
				InventoryItem.new(2, randi_range(1, 10)),
				InventoryItem.new(3, randi_range(50, 200)),
				InventoryItem.new(4, randi_range(1, 25)),
				InventoryItem.new(7, randi_range(5, 25)),
				InventoryItem.new(8, randi_range(25, 50)),
			]
		Faction.SLAVER:
			items = [
				InventoryItem.new(0, randi_range(1, 10)),
				InventoryItem.new(2, randi_range(1, 5)),
				InventoryItem.new(3, randi_range(1, 20)),
				InventoryItem.new(4, randi_range(1, 25)),
				InventoryItem.new(7, randi_range(100, 200)),
				InventoryItem.new(8, randi_range(1, 25)),
			]
		Faction.BOUNTYHUNTER:
			items = [
				InventoryItem.new(0, randi_range(1, 50)),
				InventoryItem.new(2, randi_range(1, 5)),
				InventoryItem.new(3, randi_range(50, 200)),
				InventoryItem.new(4, randi_range(1, 25)),
				InventoryItem.new(7, randi_range(100, 200)),
				InventoryItem.new(8, randi_range(1, 25)),
			]
		Faction.CARTOGRAPHER:
			items = [
				InventoryItem.new(0, randi_range(0, 20)),
				InventoryItem.new(11, randi_range(10, 50)),
				InventoryItem.new(6, randi_range(10, 50)),
			]
		Faction.FISHERMAN:
			items = [
				InventoryItem.new(0, randi_range(1, 10)),
				InventoryItem.new(1, randi_range(5, 50)),
				InventoryItem.new(4, randi_range(5, 50)),
				InventoryItem.new(5, randi_range(1, 5)),
				InventoryItem.new(9, randi_range(20, 50)),
			]
		_:
			items = [
				InventoryItem.new(randi_range(0, Item_Database.item_database.size() - 1), randi_range(1, 10)),
				InventoryItem.new(randi_range(0, Item_Database.item_database.size() - 1), randi_range(1, 10)),
				InventoryItem.new(randi_range(0, Item_Database.item_database.size() - 1), randi_range(1, 10)),
			]

	return items

static func roll_weighted(options: Dictionary):
	var total = 0.0
	for w in options.values():
		total += w

	var r = randf() * total

	for key in options:
		r -= options[key]
		if r <= 0:
			return key

	return options.keys()[0]

static func roll_nation() -> FactionsData.Nation:
	var rolled_nation = FactionsData.roll_weighted({
		FactionsData.Nation.ENGLAND: 20,
		FactionsData.Nation.SPAIN: 20,
		FactionsData.Nation.FRANCE: 20,
		FactionsData.Nation.NETHERLANDS: 20
		})
	return rolled_nation

static func roll_faction() -> FactionsData.Faction:
	var rolled_faction = FactionsData.roll_weighted({
		FactionsData.Faction.NAVY: 25,
		FactionsData.Faction.MERCHANT: 25,
		FactionsData.Faction.PIRATE: 20,
		FactionsData.Faction.SLAVER: 10,
		FactionsData.Faction.CARTOGRAPHER: 10,
		FactionsData.Faction.BOUNTYHUNTER: 10,
		FactionsData.Faction.VIKING: 10,
		FactionsData.Faction.FISHERMAN: 10,
	})
	return rolled_faction
