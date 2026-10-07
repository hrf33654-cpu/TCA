extends Resource
class_name CardDefinition

## Immutable catalog data. Runtime mutations belong to CardInstance/BattleState.

@export var id: StringName = &""
@export var display_name: String = ""
@export var formula: String = ""
@export var element_symbol: String = ""
@export var category: StringName = &"damage"
@export_range(0, 99, 1) var energy_cost: int = 0
@export_range(0, 999, 1) var base_damage: int = 0
@export var rules_text: String = ""
@export var target_kind: StringName = &"opponent"
@export var is_element_card: bool = false
@export var effects: Array[Dictionary] = []
@export_file("*.png") var art_path: String = ""
@export var migration_status: StringName = &"prototype_fixture"


func get_base_damage() -> int:
	var total := 0
	for effect in effects:
		if StringName(effect.get("type", "")) == &"damage":
			total += int(effect.get("amount", 0))
	return total


func get_effect_amount(effect_type: StringName, fallback: int = 0) -> int:
	for effect in effects:
		if StringName(effect.get("type", "")) == effect_type:
			return int(effect.get("amount", fallback))
	return fallback


func to_view_data() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"formula": formula,
		"element_symbol": element_symbol,
		"category": String(category),
		"energy_cost": energy_cost,
		"base_damage": base_damage,
		"rules_text": rules_text,
		"target_kind": String(target_kind),
		"is_element_card": is_element_card,
		"effects": effects.duplicate(true),
		"art_path": art_path,
		"migration_status": String(migration_status),
	}
