extends Node
class_name Allegiance

var faction: FactionsData.Faction
var nation: FactionsData.Nation
var faction_texture_rect: TextureRect

func _init(_nation: FactionsData.Nation, _faction: FactionsData.Faction, _faction_texture_rect: TextureRect) -> void:
	nation = _nation
	faction_texture_rect = _faction_texture_rect
	set_faction(_faction)

func _ready() -> void:
	set_faction_texture()

func set_faction(_faction: FactionsData.Faction):
	faction = _faction
	set_faction_texture()

func set_faction_texture():
	if faction_texture_rect:
		faction_texture_rect.texture = FactionsData.get_faction_icon(faction)
