extends Node
class_name Wiki

func _init() -> void:
	create_entries()

var entries := {}


func create_entries():
	create_entry(
		"Controls",
		[ {
		"title": "Movement",
		"content":
		"WASD: Movement\nQ-E: Rotate"
		},
		{
		"title": "Cannons",
		"content":
		"UP-DOWN-Arrow: cannon pitch\nLEFT-RIGHT-Arrow: Fire cannons port,starboard\nEND: Fire cannons bow.\nG: show trajectories"
		},
		{
		"title": "Camera",
		"content":
		"RMB: drag to pan camera.\nF: zero camera offset.\nScrollwheel zoom."
		},
		{
		"title": "Selecting",
		"content":
		"LMB: Select ship "
		},
		{
		"title": "Inventory",
		"content":
		"Context specific\nTrading: LMB: Buy/Sell item\nIn world: LMB: Use item\nRMB : Drop item\nMMB : To move items between player inventory and stash."
		},
		{
		"title": "Menus",
		"content":
		"TAB: Inventory\nCAPSLOCK: ship panel and equipment panel."
		}]
	)
	create_entry(
		"Ships",
		[ {

		"title": "General",
		"content":
		"Ships have 3 main stats: Crew health, ship health and recovery.\nIf crew health or ship health reaches 0 you die.\nCrew health does not regenerate, you have to recruit more crew to replenish.\nShip health on the other hand regenerates over time when not taking damage, and can be thought about like a shield.\nWhen taking damage the recovery timer starts and when its elapsed the ship starts repairing.\nThere is also a crew morale stat but its not fully implemented yet.
		"
		}]
	)
	create_entry(
		"Ports",
		[ {

		"title": "General",
		"content":
		"Ports are controlled by factions and provides some services and commerce.\nYou can sell materials, and purchase a market for trading other goods.\nPorts define the areas faction and ships of the faction will spawn in the area.\nPorts can be captured by destroying all rival ships in vicinity.\nPorts can also be captured by other ships from other factions.Ports have some defenses depending on faction. You can also purchase defenses on ports you control.
		"
		}]
	)

	create_entry(
		"Factions",
		[ {

		"title": "Navy",
		"content":
		"

		"
		},
		{
		"title": "Merchant",
		"content":
		"

		"
		
		},
		{
		"title": "Pirate",
		"content":
		"

		"
		
		},
		{
		"title": "Slaver",
		"content":
		"

		"
		
		},
		{
		"title": "Cartographer",
		"content":
		"

		"
		
		},
		{
		"title": "Bountyhunter",
		"content":
		"

		"
		
		},
		{
		"title": "Viking",
		"content":
		"

		"
		
		},
		{
		"title": "Fisherman",
		"content":
		"

		"
		
		}]
	)
	create_entry(
		"Nations",
		[ {

		"title": "England",
		"content":
		"

		"
		},
		{

		"title": "France",
		"content":
		"

		"
		},
		{

		"title": "Spain",
		"content":
		"

		"
		},
		{

		"title": "Netherlands",
		"content":
		"

		"
		},
		{

		"title": "Nordic",
		"content":
		"

		"
		},
		
		]
	)
	create_entry(
		"Items",
		[ {

		"title": "General",
		"content":
		"There are different types of items, passive items that increase your stats like the spyglass increasing your look range.\nConsumables that gets consumed over time like rations and rum, active items like cannon balls, and interactable items like repair kits and harpoons.
		"
		}]
	)
	create_entry(
		"Points of interest",
		[ {
		"title": "Lighthouses",
		"content":
		"Lighthouses reveal a large area on the map when visited.
		"},
		{
		"title": "Mines",
		"content":
		"Mines are places you can visit to gain easily sellable items like wood, ore and fiber. These can then be sold at any port.
		"},
		{
		"title": "Maelstroms",
		"content":
		"Maelstroms are a world hazard that sucks in ships and swallows them.
		"
		}]
	)
	create_entry(
		"Animals",
		[ {
		"title": "Whales",
		"content":
		"Whales can be hunted for resources.
		"},
		{
		"title": "Sharks",
		"content":
		"Sharks can be hunted for resources.
		"}]
	)

func create_entry(category: String, items: Array):
	if not entries.has(category):
		entries[category] = []
	
	for item in items:
		entries[category].append({
			"title": item.title,
			"content": item.content,
		})