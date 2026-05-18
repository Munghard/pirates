extends Node

# ideas for chaos faction, attacks everyone, very dangerous
# faction name:
# Black Tide, Cult of the black tide
# The Saltborn, Cult of the Saltborn
# Church of the Last Tide, Cult of the Last Tide

class_name FactionsData


func ready():
	init_portraits()

static func init_portraits():
	for i in range(1, 52):
		var path = "res://Textures/male-peasants/portrait_%d.jpg" % i
		if ResourceLoader.exists(path):
			portraits.append(load(path))

enum Nation {ENGLAND, SPAIN, FRANCE, NETHERLANDS, NORDIC}
const NATION_NAMES = {
	Nation.ENGLAND: "ENGLAND",
	Nation.SPAIN: "SPAIN",
	Nation.FRANCE: "FRANCE",
	Nation.NETHERLANDS: "NETHERLANDS",
	Nation.NORDIC: "NORDIC",
}

const NATION_FLAGS = {
	Nation.ENGLAND: preload("res://Textures/Flag_of_the_United_Kingdom.png"),
	Nation.SPAIN: preload("res://Textures/Bandera_de_España.png"),
	Nation.FRANCE: preload("res://Textures/Flag_of_France.png"),
	Nation.NETHERLANDS: preload("res://Textures/Flag_of_the_Netherlands.png"),
	Nation.NORDIC: preload("res://Textures/raven-banner-vikings.jpg")
}
static func get_flag(nation: Nation, _faction: Faction) -> Texture2D:
	var flag = NATION_FLAGS.get(nation)
	#if faction == Faction.PIRATE:
		#flag = preload("res://Textures/Pirate_Flag_of_Jack_Rackham.png")
	flag = preload("res://Textures/swallowtail.png")
	return flag

enum Faction {NONE, PIRATE, MERCHANT, NAVY, SLAVER, CARTOGRAPHER, BOUNTYHUNTER, VIKING, FISHERMAN}

const FACTION_NAMES = {
	Faction.NONE: "None",
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
static var portraits = []

static var available_portraits = []

static func get_unique_portrait() -> Texture2D:
	if portraits.is_empty():
		init_portraits()
	if available_portraits.is_empty():
		available_portraits = portraits.duplicate()

	var index = randi_range(0, available_portraits.size() - 1)
	var portrait = available_portraits[index]

	available_portraits.remove_at(index)

	return portrait

static func reset_portraits():
	available_portraits = portraits.duplicate()

static var available_port_names = []

static func reset_port_names():
	available_port_names = PORT_NAMES.duplicate()

static func get_unique_port_name() -> String:
	if available_port_names.is_empty():
		reset_port_names()

	var index = randi_range(0, available_port_names.size() - 1)
	var port_name = available_port_names[index]

	available_port_names.remove_at(index)

	return port_name


static var available_ship_names = []

static func reset_ship_names():
	available_ship_names = NAMES.duplicate()

static func get_unique_ship_name() -> String:
	if available_ship_names.is_empty():
		reset_ship_names()

	var index = randi_range(0, available_ship_names.size() - 1)
	var ship_name = available_ship_names[index]

	available_ship_names.remove_at(index)

	return ship_name

static func get_enemy_factions(f1: FactionsData.Faction) -> Array[FactionsData.Faction]:
	match f1:
		FactionsData.Faction.NONE:
			return []
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
	if f1 == FactionsData.Faction.NONE or f2 == FactionsData.Faction.NONE:
		return false
	return get_enemy_factions(f1).has(f2)

static func get_random_name() -> String:
	return NAMES[randi() % NAMES.size()]

static func get_nation_color(nation: Nation) -> Color:
	match nation:
		Nation.ENGLAND:
			return Color("#3260e0") #
		Nation.FRANCE:
			return Color("#c0392b") #
		Nation.NETHERLANDS:
			return Color("#9b2bc0") #
		Nation.SPAIN:
			return Color("#c0b92b") #
		Nation.NORDIC:
			return Color("#2bc050") #
		_:
			return Color("#7f8c8d") # neutral graya

static func get_faction_color(faction: Faction) -> Color:
	match faction:
		Faction.PIRATE:
			return Color("#c0392b") # deep pirate red
		
		Faction.MERCHANT:
			return Color("#2ecc71") # wealthy trade green
		
		Faction.NAVY:
			return Color("#2980b9") # naval blue
		
		Faction.SLAVER:
			return Color("#8e44ad") # oppressive purple
		
		Faction.BOUNTYHUNTER:
			return Color("#d35400") # rugged orange
		
		Faction.VIKING:
			return Color("#dd8eb5") # cold steel gray
		
		Faction.CARTOGRAPHER:
			return Color("#f1c40f") # parchment gold
		
		Faction.FISHERMAN:
			return Color("#16a085") # seafoam teal
		
		_:
			return Color("#7f8c8d") # neutral graya

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
			texture = preload("res://Textures/fishing.png")
		Faction.BOUNTYHUNTER:
			texture = preload("res://Textures/wanted-reward.png")
		Faction.VIKING:
			texture = preload("res://Textures/viking-helmet.png")
		Faction.CARTOGRAPHER:
			texture = preload("res://Textures/globe.png")
		_:
			texture = preload("res://Textures/flying-flag.png")
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

static func get_port_stats(faction: Faction) -> ShipStats:
	var port_stats = FactionsData.get_faction_stats(faction)
	return port_stats

static func get_faction_starting_cannons(faction: Faction) -> int:
	match faction:
		Faction.PIRATE:
			return 4
		Faction.MERCHANT:
			return 2
		Faction.NAVY:
			return 6
		Faction.SLAVER:
			return 3
		Faction.BOUNTYHUNTER:
			return 4
		Faction.VIKING:
			return 3
		Faction.CARTOGRAPHER:
			return 1
		Faction.FISHERMAN:
			return 1
		_:
			return 0

static func get_faction_inventory(faction: Faction) -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	
	if not FactionLoot.faction_loot.has(faction):
		return result

	for entry in FactionLoot.faction_loot[faction]:
		if randf() <= entry.chance:
			result.append(
				InventoryItem.new(
					entry.id,
					randi_range(entry.min, entry.max)
				)
			)

	return result

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
		FactionsData.Nation.NETHERLANDS: 20,
		FactionsData.Nation.NORDIC: 20
		})
	return rolled_nation

static func roll_faction(nation: FactionsData.Nation) -> FactionsData.Faction:
	var rolled_faction
	
	# ENGLAND, SPAIN, FRANCE, NETHERLANDS, NORDIC
	match nation:
		FactionsData.Nation.ENGLAND:
			rolled_faction = FactionsData.roll_weighted({
				FactionsData.Faction.NONE: 50,
				FactionsData.Faction.NAVY: 35,
				FactionsData.Faction.MERCHANT: 25,
				FactionsData.Faction.PIRATE: 15,
				FactionsData.Faction.SLAVER: 10,
				FactionsData.Faction.BOUNTYHUNTER: 10,
				FactionsData.Faction.CARTOGRAPHER: 10,
				FactionsData.Faction.FISHERMAN: 5,
			})

		FactionsData.Nation.SPAIN:
			rolled_faction = FactionsData.roll_weighted({
				FactionsData.Faction.NONE: 50,
				FactionsData.Faction.NAVY: 30,
				FactionsData.Faction.SLAVER: 25,
				FactionsData.Faction.MERCHANT: 20,
				FactionsData.Faction.CARTOGRAPHER: 15,
				FactionsData.Faction.PIRATE: 5,
				FactionsData.Faction.BOUNTYHUNTER: 5,
			})

		FactionsData.Nation.FRANCE:
			rolled_faction = FactionsData.roll_weighted({
				FactionsData.Faction.NONE: 50,
				FactionsData.Faction.NAVY: 25,
				FactionsData.Faction.MERCHANT: 25,
				FactionsData.Faction.PIRATE: 20,
				FactionsData.Faction.BOUNTYHUNTER: 15,
				FactionsData.Faction.CARTOGRAPHER: 10,
				FactionsData.Faction.FISHERMAN: 5,
			})

		FactionsData.Nation.NETHERLANDS:
			rolled_faction = FactionsData.roll_weighted({
				FactionsData.Faction.NONE: 50,
				FactionsData.Faction.MERCHANT: 40,
				FactionsData.Faction.CARTOGRAPHER: 20,
				FactionsData.Faction.NAVY: 15,
				FactionsData.Faction.PIRATE: 10,
				FactionsData.Faction.FISHERMAN: 10,
				FactionsData.Faction.BOUNTYHUNTER: 5,
			})

		FactionsData.Nation.NORDIC:
			rolled_faction = FactionsData.roll_weighted({
				FactionsData.Faction.NONE: 50,
				FactionsData.Faction.VIKING: 35,
				FactionsData.Faction.FISHERMAN: 25,
				FactionsData.Faction.CARTOGRAPHER: 15,
				FactionsData.Faction.MERCHANT: 10,
				FactionsData.Faction.PIRATE: 10,
				FactionsData.Faction.BOUNTYHUNTER: 5,
			})
		
	return rolled_faction
