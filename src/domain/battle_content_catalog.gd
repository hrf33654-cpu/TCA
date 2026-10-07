extends RefCounted
class_name BattleContentCatalog

const SUPPORTED_EFFECT_TYPES := {
	"damage": true,
	"next_reaction_discount": true,
	"next_incoming_damage_reduction": true,
	"draw_after_next_reaction": true,
	"next_damage_bonus": true,
	"draw_now": true,
}

var _cards: Dictionary = {}
var _recipes_by_key: Dictionary = {}
var _construction_errors: Array[String] = []


func _init(cards: Array[CardDefinition] = [], recipes: Array[ReactionRecipe] = []) -> void:
	for definition in cards:
		add_card(definition)
	for recipe in recipes:
		add_recipe(recipe)


func add_card(definition: CardDefinition) -> void:
	if definition == null:
		_construction_errors.append("Card catalog contains a null definition.")
		return
	var card_id := String(definition.id).strip_edges().to_lower()
	if card_id.is_empty():
		_construction_errors.append("Card definition has an empty ID.")
		return
	if _cards.has(card_id):
		_construction_errors.append("Duplicate card definition ID: %s" % card_id)
		return
	_cards[card_id] = definition


func add_recipe(recipe: ReactionRecipe) -> void:
	if recipe == null:
		_construction_errors.append("Reaction catalog contains a null recipe.")
		return
	var recipe_key := recipe.normalized_key()
	if recipe_key.is_empty():
		_construction_errors.append("Reaction recipe %s must have exactly two input IDs." % recipe.id)
		return
	if _recipes_by_key.has(recipe_key):
		_construction_errors.append("Duplicate reaction recipe key: %s" % recipe_key)
		return
	_recipes_by_key[recipe_key] = recipe


func get_card(card_id: String) -> CardDefinition:
	return _cards.get(_normalize_id(card_id)) as CardDefinition


func has_card(card_id: String) -> bool:
	return _cards.has(_normalize_id(card_id))


func get_card_ids() -> Array[String]:
	var ids: Array[String] = []
	for card_id in _cards:
		ids.append(String(card_id))
	ids.sort()
	return ids


func get_recipe(first_card_id: String, second_card_id: String) -> ReactionRecipe:
	var normalized_ids := [_normalize_id(first_card_id), _normalize_id(second_card_id)]
	normalized_ids.sort()
	return _recipes_by_key.get("%s+%s" % [normalized_ids[0], normalized_ids[1]]) as ReactionRecipe


func validate_all() -> Dictionary:
	var errors: Array[String] = _construction_errors.duplicate()
	for card_id in _cards:
		var definition: CardDefinition = _cards[card_id]
		_validate_card(String(card_id), definition, errors)
	for recipe_key in _recipes_by_key:
		var recipe: ReactionRecipe = _recipes_by_key[recipe_key]
		_validate_recipe(String(recipe_key), recipe, errors)
	return {"valid": errors.is_empty(), "errors": errors}


func _validate_card(card_id: String, definition: CardDefinition, errors: Array[String]) -> void:
	if String(definition.id).strip_edges().to_lower() != card_id:
		errors.append("Card map key and definition ID differ: %s" % card_id)
	if definition.display_name.strip_edges().is_empty():
		errors.append("Card display name is empty: %s" % card_id)
	if String(definition.category) not in ["damage", "buff", "solvent"]:
		errors.append("Unsupported card category '%s': %s" % [definition.category, card_id])
	if String(definition.target_kind) not in ["self", "opponent", "any"]:
		errors.append("Unsupported target kind '%s': %s" % [definition.target_kind, card_id])
	if definition.energy_cost < 0:
		errors.append("Card energy cost must not be negative: %s" % card_id)
	if definition.base_damage < 0:
		errors.append("Card base damage must not be negative: %s" % card_id)
	if definition.is_element_card and definition.element_symbol.strip_edges().is_empty():
		errors.append("Element card has no element symbol: %s" % card_id)
	if definition.migration_status == &"":
		errors.append("Card migration status is missing: %s" % card_id)
	var effect_counts: Dictionary = {}
	var damage_sum := 0
	for effect in definition.effects:
		var effect_type := StringName(effect.get("type", ""))
		var effect_name := String(effect_type)
		if not SUPPORTED_EFFECT_TYPES.has(effect_name):
			errors.append("Unsupported effect '%s' on card %s" % [effect_name, card_id])
			continue
		var amount := int(effect.get("amount", 0))
		if amount <= 0:
			errors.append("Effect '%s' must have a positive amount on %s" % [effect_name, card_id])
		effect_counts[effect_name] = int(effect_counts.get(effect_name, 0)) + 1
		if effect_type == &"damage":
			damage_sum += amount
	for effect_type in effect_counts:
		if effect_type != "damage" and int(effect_counts[effect_type]) > 1:
			errors.append("Card %s repeats non-damage effect '%s'" % [card_id, effect_type])
	if damage_sum != definition.base_damage:
		errors.append("Card %s base damage (%d) differs from damage effects (%d)" % [card_id, definition.base_damage, damage_sum])
	if String(definition.category) == "damage" and damage_sum <= 0:
		errors.append("Damage category card has no damage effect: %s" % card_id)
	if not definition.rules_text.strip_edges().is_empty() and definition.effects.is_empty():
		errors.append("Card %s has rules text but no machine-readable effect" % card_id)


func _validate_recipe(recipe_key: String, recipe: ReactionRecipe, errors: Array[String]) -> void:
	if String(recipe.id).strip_edges().is_empty():
		errors.append("Reaction recipe has an empty ID: %s" % recipe_key)
	if recipe.input_card_ids.size() != 2:
		errors.append("Reaction recipe must have two inputs: %s" % recipe_key)
	else:
		for input_id in recipe.input_card_ids:
			var input_card := get_card(String(input_id))
			if input_card == null:
				errors.append("Reaction recipe %s references missing input %s" % [recipe_key, input_id])
			elif not input_card.is_element_card:
				errors.append("Reaction recipe %s input is not an element card: %s" % [recipe_key, input_id])
	if recipe.product_ids.is_empty():
		errors.append("Reaction recipe has no products: %s" % recipe_key)
	var products_seen: Dictionary = {}
	for product_id in recipe.product_ids:
		var normalized_product_id := _normalize_id(String(product_id))
		if products_seen.has(normalized_product_id):
			errors.append("Reaction recipe %s repeats product %s" % [recipe_key, product_id])
		products_seen[normalized_product_id] = true
		if not has_card(normalized_product_id):
			errors.append("Reaction recipe %s references missing product %s" % [recipe_key, product_id])
	if recipe.migration_status == &"":
		errors.append("Reaction recipe migration status is missing: %s" % recipe_key)


func _normalize_id(value: String) -> String:
	return value.strip_edges().to_lower()
