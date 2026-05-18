class_name FactionLoot

static var faction_loot = {
	FactionsData.Faction.NONE: [
		{"id": "rations", "chance": 1.0, "min": 30, "max": 50},
		{"id": "rum", "chance": 1.0, "min": 30, "max": 50},
	],

	FactionsData.Faction.PIRATE: [
		{"id": "rations", "chance": 1.0, "min": 30, "max": 50},
		{"id": "rum", "chance": 1.0, "min": 5, "max": 50},
		{"id": "cannon_balls", "chance": 1.0, "min": 25, "max": 100},

		# optional flavor items
		{"id": "fishing_rig", "chance": 0.15, "min": 1, "max": 1},
	],

	FactionsData.Faction.MERCHANT: [
		{"id": "rations", "chance": 1.0, "min": 30, "max": 50},
		{"id": "rum", "chance": 1.0, "min": 5, "max": 25},
		{"id": "documents", "chance": 0.9, "min": 1, "max": 10},
		{"id": "shackles", "chance": 0.8, "min": 1, "max": 10},
		{"id": "firearms", "chance": 0.6, "min": 1, "max": 10},
		{"id": "gold", "chance": 0.5, "min": 1, "max": 10},

		{"id": "fishing_rig", "chance": 0.15, "min": 1, "max": 1},
	],

	FactionsData.Faction.NAVY: [
		{"id": "rations", "chance": 1.0, "min": 30, "max": 50},
		{"id": "cannon_balls", "chance": 0.9, "min": 50, "max": 100},
		{"id": "rum", "chance": 1.0, "min": 50, "max": 200},
		{"id": "ropes", "chance": 0.7, "min": 1, "max": 25},
		{"id": "shackles", "chance": 0.8, "min": 5, "max": 25},
		{"id": "gold", "chance": 1.0, "min": 25, "max": 50},
	],

	FactionsData.Faction.SLAVER: [
		{"id": "rations", "chance": 0.8, "min": 30, "max": 50},
		{"id": "cannon_balls", "chance": 0.5, "min": 1, "max": 10},
		{"id": "rum", "chance": 0.8, "min": 1, "max": 20},
		{"id": "ropes", "chance": 0.9, "min": 1, "max": 25},
		{"id": "shackles", "chance": 1.0, "min": 100, "max": 200},
		{"id": "gold", "chance": 0.7, "min": 1, "max": 25},
	],

	FactionsData.Faction.BOUNTYHUNTER: [
		{"id": "rations", "chance": 1.0, "min": 30, "max": 50},
		{"id": "cannon_balls", "chance": 0.5, "min": 25, "max": 100},
		{"id": "rum", "chance": 1.0, "min": 50, "max": 200},
		{"id": "ropes", "chance": 0.7, "min": 1, "max": 25},
		{"id": "shackles", "chance": 1.0, "min": 100, "max": 200},
		{"id": "gold", "chance": 0.7, "min": 1, "max": 25},
	],

	FactionsData.Faction.CARTOGRAPHER: [
		{"id": "rations", "chance": 0.6, "min": 30, "max": 50},
		{"id": "maps", "chance": 1.0, "min": 10, "max": 50},
		{"id": "documents", "chance": 1.0, "min": 10, "max": 50},
		{"id": "navigation_equipment", "chance": 0.8, "min": 1, "max": 5},
	],

	FactionsData.Faction.VIKING: [
		{"id": "rations", "chance": 0.7, "min": 30, "max": 50},
		{"id": "ropes", "chance": 1.0, "min": 5, "max": 50},
		{"id": "navigation_equipment", "chance": 0.8, "min": 1, "max": 5},
		{"id": "fishing_gear", "chance": 1.0, "min": 20, "max": 50},
	],

	FactionsData.Faction.FISHERMAN: [
		{"id": "rations", "chance": 0.7, "min": 30, "max": 50},
		{"id": "rum", "chance": 1.0, "min": 5, "max": 50},
		{"id": "ropes", "chance": 1.0, "min": 5, "max": 50},
		{"id": "navigation_equipment", "chance": 0.8, "min": 1, "max": 5},
		{"id": "fishing_gear", "chance": 1.0, "min": 20, "max": 50},

		{"id": "fishing_rig", "chance": 0.9, "min": 1, "max": 1},
	],
}