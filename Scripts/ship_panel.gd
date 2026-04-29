extends FoldableContainer

class_name ShipPanel

var _release_callable: Callable

var ship: Ship

@export_group("Nodes")
@export var flag_texture_rect: TextureRect
@export var faction_texture_rect: TextureRect
@export var label_h: Label
@export var label_f: Label
@export var status_label: Label
@export var stats_label: Label

@export var hitpoints_pb: ProgressBar
@export var crew_pb: ProgressBar
@export var recovery_pb: ProgressBar

@export var release_button: Button
@export var tab_bar: TabBar

@export var status_panel: Control
@export var stats_panel: Control
@export var cannons_panel: Control

func _ready() -> void:
	tab_bar.tab_clicked.connect(_on_tab_pressed)
	set_active_tab(0)

func set_ship(_ship: Ship):
	ship = _ship
	if _ship: set_faction_icon(FactionsData.get_faction_icon(_ship.faction))

func set_faction_icon(faction_texture: Texture2D):
	faction_texture_rect.texture = faction_texture

func _on_tab_pressed(_tab):
	set_active_tab(_tab)

func set_active_tab(_tab: int):
	stats_panel.visible = false
	status_panel.visible = false
	cannons_panel.visible = false
	match _tab:
		0:
			status_panel.visible = true
		1:
			stats_panel.visible = true
		2:
			create_canon_ui(ship)
			cannons_panel.visible = true

func _on_release_pressed(_ship: Ship):
	print("release pressed")
	if _ship and _ship.boarded_by:
		_ship.boarded_by.unboard_ship(_ship)
		print("unboard")

func update_ship_panel(_ship: Ship):
	if _ship == null:
		label_h.text = "No ship selected"
		status_label.text = "Select a ship to view its stats"
		label_f.visible = false
		crew_pb.visible = false
		hitpoints_pb.visible = false
		recovery_pb.visible = false
		release_button.visible = false
		flag_texture_rect.visible = false
		return
	else:
		label_f.visible = true
		crew_pb.visible = true
		hitpoints_pb.visible = true
		recovery_pb.visible = true
		release_button.visible = true
		flag_texture_rect.visible = true

	if _ship != _ship.gameManager.player_ship:
		_release_callable = Callable(_on_release_pressed).bind(_ship)
		if not release_button.pressed.is_connected(_release_callable):
			release_button.pressed.connect(_release_callable)

	release_button.visible = _ship.boarded_by != null
	
	flag_texture_rect.texture = FactionsData.get_flag(_ship.nation, _ship.faction)

	var ship_name = ""
	
	ship_name = _ship.ship_name
	label_h.text = "%s" % ship_name
	label_f.text = "%s Lvl:%s" % [FactionsData.FACTION_NAMES[_ship.faction], _ship.level]
	
	var color = FactionsData.get_faction_color(_ship.faction)
	label_f.self_modulate = color

	var ai_text = ""
	if _ship is EnemyShip:
		ai_text = "State: %s" % (_ship as EnemyShip).AIStateNames[(_ship as EnemyShip).ai_state]
		if (_ship.ai_state == EnemyShip.AIState.COMBAT):
			ai_text += "\nSubState: %s" % (_ship as EnemyShip).CombatStateNames[(_ship as EnemyShip).combat_state]
		ai_text += "\nIn combat: %.s" % [str(_ship.in_combat)]
		if _ship.attacker and _ship.attacker is Ship: ai_text += "\nTarget: %.s" % [str(_ship.attacker.ship_name)]
	
	var stats_text = ""
	var status_text = ""
	if _ship:
		# debug info
		# ship_text += "\nTarg.Spd: %.2f/%.2f" % [ship.target_speed, ship.top_speed]
		# ship_text += "\nAct.Spd: %.2f" % [ship.actual_speed]
		# ship_text += "\nHeading: %.2f" % [rad_to_deg(ship.rotation.y)]
		stats_text += "\nCrew: %s/%s" % [_ship.crew, _ship.max_crew]
		stats_text += "\nHp: %.2f/%.2f" % [_ship.hit_points, _ship.max_hit_points]
		stats_text += "\nAgility: %.2f" % [_ship.agility]
		stats_text += "\nAttack: %.2f" % [_ship.attack]
		stats_text += "\nDefense: %.2f" % [_ship.defense]
		stats_text += "\nGold: %.2f" % [_ship.gold]
		stats_text += "\nSupplies: %.2f" % [_ship.supplies]
		stats_text += "\nGuns: %.2f" % [_ship.guns]
		
		crew_pb.max_value = _ship.max_crew
		crew_pb.value = _ship.crew

		var progress: float = _ship.recovery_progress

		recovery_pb.value = progress
		recovery_pb.max_value = 1.0
		
		hitpoints_pb.max_value = _ship.max_hit_points
		hitpoints_pb.value = _ship.hit_points


	status_label.text = ai_text + status_text
	stats_label.text = stats_text

func create_canon_ui(_ship: Ship):
	for child in cannons_panel.get_children():
		child.queue_free()
	if _ship == null:
		return
	
	var player_controlled = _ship is PlayerShip

	var vb = VBoxContainer.new()
	cannons_panel.add_child(vb)

	var hb := HBoxContainer.new()
	vb.add_child(hb)

	var l = Label.new()
	l.text = "Show trajectory"
	hb.add_child(l)
	var cb := CheckBox.new()
	hb.add_child(cb)
	var cannons_active = true
	cb.button_pressed = !cannons_active

	cb.toggled.connect(func(_pressed: bool):
		_ship.active_port(_pressed)
		_ship.active_starboard(_pressed)
		_ship.active_bow(_pressed)
	)

	if _ship.cannons_layout.cannons_port.size() > 0:
		create_canon_pb("Port", vb, _ship.cannons_layout.cannons_port)
		if player_controlled:
			var port_button = Button.new()
			vb.add_child(port_button)
			port_button.text = "Fire port"
			port_button.pressed.connect(_ship.shoot_port)
	if _ship.cannons_layout.cannons_starboard.size() > 0:
		create_canon_pb("Starboard", vb, _ship.cannons_layout.cannons_starboard)
		if player_controlled:
			var starboard_button = Button.new()
			vb.add_child(starboard_button)
			starboard_button.text = "Fire starboard"
			starboard_button.pressed.connect(_ship.shoot_starboard)
	if _ship.cannons_layout.cannons_bow.size() > 0:
		create_canon_pb("Bow", vb, _ship.cannons_layout.cannons_bow)
		if player_controlled:
			var bow_button = Button.new()
			vb.add_child(bow_button)
			bow_button.text = "Fire bow"
			bow_button.pressed.connect(_ship.shoot_bow)

func create_canon_pb(side_name: String, vb: VBoxContainer, cannons: Array[Cannon]):
	var ls := Label.new()
	ls.text = side_name
	vb.add_child(ls)
	for cannon in cannons:
		var pb = ProgressBar.new()
		pb.max_value = cannon.fire_rate
		pb.value = pb.max_value - cannon.fire_timer
		vb.add_child(pb)
		if not cannon.is_connected("_fire_timer_changed", Callable(self , "update_pb").bind(pb)):
			cannon.connect("_fire_timer_changed", Callable(self , "update_pb").bind(pb))
	
func update_pb(value: float, pb):
	if pb:
		pb.value = pb.max_value - value
