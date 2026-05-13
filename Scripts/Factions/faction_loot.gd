class_name FactionLoot
static var faction_loot = {
	FactionsData.Faction.PIRATE: [
		{"id": 0, "chance": 1.0, "min": 5, "max": 50},
		{"id": 1, "chance": 1.0, "min": 5, "max": 50},
		{"id": 2, "chance": 1.0, "min": 1, "max": 6},

		# optional flavor items
		{"id": 18, "chance": 0.35, "min": 1, "max": 1}, # fishing rig
	],

	FactionsData.Faction.MERCHANT: [
		{"id": 0, "chance": 1.0, "min": 5, "max": 50},
		{"id": 1, "chance": 1.0, "min": 5, "max": 25},
		{"id": 3, "chance": 0.9, "min": 1, "max": 10},
		{"id": 4, "chance": 0.8, "min": 1, "max": 10},
		{"id": 6, "chance": 0.6, "min": 1, "max": 10},
		{"id": 8, "chance": 0.5, "min": 1, "max": 10},

		{"id": 18, "chance": 0.15, "min": 1, "max": 1}, # fishing rig
	],

	FactionsData.Faction.NAVY: [
		{"id": 0, "chance": 1.0, "min": 1, "max": 50},
		{"id": 2, "chance": 0.9, "min": 1, "max": 10},
		{"id": 3, "chance": 1.0, "min": 50, "max": 200},
		{"id": 4, "chance": 0.7, "min": 1, "max": 25},
		{"id": 7, "chance": 0.8, "min": 5, "max": 25},
		{"id": 8, "chance": 1.0, "min": 25, "max": 50},
	],

	FactionsData.Faction.SLAVER: [
		{"id": 0, "chance": 0.8, "min": 1, "max": 10},
		{"id": 2, "chance": 0.5, "min": 1, "max": 5},
		{"id": 3, "chance": 0.8, "min": 1, "max": 20},
		{"id": 4, "chance": 0.9, "min": 1, "max": 25},
		{"id": 7, "chance": 1.0, "min": 100, "max": 200},
		{"id": 8, "chance": 0.7, "min": 1, "max": 25},
	],

	FactionsData.Faction.BOUNTYHUNTER: [
		{"id": 0, "chance": 1.0, "min": 1, "max": 50},
		{"id": 2, "chance": 0.5, "min": 1, "max": 5},
		{"id": 3, "chance": 1.0, "min": 50, "max": 200},
		{"id": 4, "chance": 0.7, "min": 1, "max": 25},
		{"id": 7, "chance": 1.0, "min": 100, "max": 200},
		{"id": 8, "chance": 0.7, "min": 1, "max": 25},
	],

	FactionsData.Faction.CARTOGRAPHER: [
		{"id": 0, "chance": 0.6, "min": 0, "max": 20},
		{"id": 11, "chance": 1.0, "min": 10, "max": 50},
		{"id": 6, "chance": 1.0, "min": 10, "max": 50},
		{"id": 5, "chance": 0.8, "min": 1, "max": 5},
	],

	FactionsData.Faction.VIKING: [
		{"id": 0, "chance": 0.7, "min": 1, "max": 10},
		{"id": 4, "chance": 1.0, "min": 5, "max": 50},
		{"id": 5, "chance": 0.8, "min": 1, "max": 5},
		{"id": 9, "chance": 1.0, "min": 20, "max": 50},
	],

	FactionsData.Faction.FISHERMAN: [
		{"id": 0, "chance": 0.7, "min": 1, "max": 10},
		{"id": 1, "chance": 1.0, "min": 5, "max": 50},
		{"id": 4, "chance": 1.0, "min": 5, "max": 50},
		{"id": 5, "chance": 0.8, "min": 1, "max": 5},
		{"id": 9, "chance": 1.0, "min": 20, "max": 50},

		{"id": 18, "chance": 0.9, "min": 1, "max": 1}, # fishing rig
	],
}