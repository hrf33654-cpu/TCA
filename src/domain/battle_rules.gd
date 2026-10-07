extends RefCounted
class_name BattleRules

const REACTION_BASE_COST := 2
const ENERGY_REGEN_PER_TURN := 2

var catalog: BattleContentCatalog


func _init(p_catalog: BattleContentCatalog) -> void:
	catalog = p_catalog


func play_card(state: BattleState, actor_id: String, instance_id: String, target_id: String) -> Dictionary:
	var actor_error := _validate_actor(state, actor_id)
	if not actor_error.is_empty():
		return _reject(state, actor_error, "invalid_actor_or_phase")
	var instance: CardInstance = state.card_instances.get(instance_id)
	if instance == null or instance.owner_id != actor_id or instance.zone != "hand":
		return _reject(state, "The card instance is not in this actor's hand.", "card_not_in_hand")
	var hand: Array = state.sides[actor_id]["hand"]
	var hand_index := hand.find(instance_id)
	if hand_index < 0:
		return _reject(state, "The card instance is missing from its hand zone.", "card_not_in_hand")
	var definition := catalog.get_card(instance.definition_id)
	if definition == null:
		return _reject(state, "Card definition is not available.", "missing_card_definition")
	var target_error := _validate_target(state, actor_id, target_id, definition.target_kind)
	if not target_error.is_empty():
		return _reject(state, target_error, "invalid_target")
	var actor_side: Dictionary = state.sides[actor_id]
	if definition.energy_cost < 0 or int(actor_side["energy"]) < definition.energy_cost:
		return _reject(state, "Not enough energy to play this card.", "insufficient_energy")
	if definition.effects.is_empty():
		return _reject(state, "Card has no supported machine-readable effect.", "missing_effect")
	var next_state := state.duplicate_state()
	var events: Array[Dictionary] = []
	var next_instance: CardInstance = next_state.card_instances[instance_id]
	var next_actor_side: Dictionary = next_state.sides[actor_id]
	next_actor_side["energy"] = int(next_actor_side["energy"]) - definition.energy_cost
	next_actor_side["hand"].remove_at(hand_index)
	_add_to_discard(next_state, next_instance)
	_emit(next_state, events, "card_played", {
		"actor_id": actor_id,
		"instance_id": instance_id,
		"definition_id": definition.id,
		"target_id": target_id,
		"energy_cost": definition.energy_cost,
	})
	var base_damage := definition.get_base_damage()
	if base_damage > 0:
		_apply_damage(next_state, actor_id, target_id, definition, base_damage, events)
	for effect in definition.effects:
		var effect_type := StringName(effect.get("type", ""))
		var amount := int(effect.get("amount", 0))
		match effect_type:
			&"damage":
				pass
			&"next_reaction_discount":
				next_actor_side["effects"]["next_reaction_discount"] = maxi(
					int(next_actor_side["effects"].get("next_reaction_discount", 0)), amount)
				_emit(next_state, events, "effect_applied", {"actor_id": actor_id, "effect_type": String(effect_type), "amount": amount})
			&"next_incoming_damage_reduction":
				next_actor_side["effects"]["next_incoming_damage_reduction"] = maxi(
					int(next_actor_side["effects"].get("next_incoming_damage_reduction", 0)), amount)
				_emit(next_state, events, "effect_applied", {"actor_id": actor_id, "effect_type": String(effect_type), "amount": amount})
			&"draw_after_next_reaction":
				next_actor_side["effects"]["draw_after_next_reaction"] = true
				_emit(next_state, events, "effect_applied", {"actor_id": actor_id, "effect_type": String(effect_type), "amount": amount})
			&"next_damage_bonus":
				next_actor_side["effects"]["next_damage_bonus"] = maxi(
					int(next_actor_side["effects"].get("next_damage_bonus", 0)), amount)
				_emit(next_state, events, "effect_applied", {"actor_id": actor_id, "effect_type": String(effect_type), "amount": amount})
			&"draw_now":
				_draw_cards(next_state, actor_id, amount, "card_effect", events)
			_:
				return _reject(state, "Card effect is unsupported.", "unsupported_effect")
	OutcomeEvaluator.refresh(next_state)
	if next_state.outcome != "ongoing":
		events.append(next_state.event_log.back().duplicate(true))
	var invariant_errors := next_state.validate_invariants(catalog)
	assert(invariant_errors.is_empty(), "Invalid state after play_card: %s" % "; ".join(invariant_errors))
	return _accept(next_state, events)


func assign_reaction_card(state: BattleState, actor_id: String, instance_id: String, slot_index: int) -> Dictionary:
	var actor_error := _validate_actor(state, actor_id)
	if not actor_error.is_empty():
		return _reject(state, actor_error, "invalid_actor_or_phase")
	if slot_index < 0 or slot_index >= 2:
		return _reject(state, "Reaction slot index must be 0 or 1.", "invalid_reaction_slot")
	var slots: Array = state.reaction_slots.get(actor_id, [])
	if slots.size() != 2:
		return _reject(state, "Reaction slots are not initialized.", "invalid_reaction_slots")
	if slots[slot_index] is Dictionary:
		return _reject(state, "Reaction slot is already occupied.", "reaction_slot_occupied")
	var instance: CardInstance = state.card_instances.get(instance_id)
	if instance == null or instance.owner_id != actor_id or instance.zone != "hand":
		return _reject(state, "The card instance is not in this actor's hand.", "card_not_in_hand")
	var hand: Array = state.sides[actor_id]["hand"]
	var hand_index := hand.find(instance_id)
	if hand_index < 0:
		return _reject(state, "The card instance is missing from its hand zone.", "card_not_in_hand")
	var definition := catalog.get_card(instance.definition_id)
	if definition == null or not definition.is_element_card:
		return _reject(state, "Only element cards can be assigned to a reaction slot.", "not_an_element_card")
	var next_state := state.duplicate_state()
	var next_hand: Array = next_state.sides[actor_id]["hand"]
	next_hand.remove_at(hand_index)
	var next_instance: CardInstance = next_state.card_instances[instance_id]
	next_instance.zone = "reaction"
	next_state.reaction_slots[actor_id][slot_index] = {
		"instance_id": instance_id,
		"original_hand_index": hand_index,
		"original_hand_order": next_instance.hand_order,
	}
	var events: Array[Dictionary] = []
	_emit(next_state, events, "reaction_card_assigned", {
		"actor_id": actor_id,
		"instance_id": instance_id,
		"definition_id": definition.id,
		"slot_index": slot_index,
	})
	var invariant_errors := next_state.validate_invariants(catalog)
	assert(invariant_errors.is_empty(), "Invalid state after assign_reaction_card: %s" % "; ".join(invariant_errors))
	return _accept(next_state, events)


func preview_reaction(state: BattleState, actor_id: String) -> Dictionary:
	if not state.sides.has(actor_id) or not state.reaction_slots.has(actor_id):
		return _invalid_preview("invalid_actor", "Unknown actor.")
	var slots: Array = state.reaction_slots[actor_id]
	if slots.size() != 2 or not (slots[0] is Dictionary) or not (slots[1] is Dictionary):
		return _invalid_preview("reaction_slots_incomplete", "Two element cards are required.")
	var left: CardInstance = state.card_instances.get(String(slots[0].get("instance_id", "")))
	var right: CardInstance = state.card_instances.get(String(slots[1].get("instance_id", "")))
	if left == null or right == null or left.instance_id == right.instance_id:
		return _invalid_preview("invalid_reaction_instances", "Reaction cards must be two distinct instances.")
	return _preview_pair(state, actor_id, left, right)


func resolve_reaction(state: BattleState, actor_id: String, selected_product_id: String) -> Dictionary:
	var actor_error := _validate_actor(state, actor_id)
	if not actor_error.is_empty():
		return _reject(state, actor_error, "invalid_actor_or_phase")
	var preview := preview_reaction(state, actor_id)
	if not bool(preview["valid"]):
		return _reject(state, String(preview["message"]), String(preview["reason_code"]))
	var slots: Array = state.reaction_slots[actor_id]
	var instances: Array[CardInstance] = [
		state.card_instances[String(slots[0]["instance_id"])],
		state.card_instances[String(slots[1]["instance_id"])],
	]
	return _commit_reaction(state, actor_id, instances, selected_product_id, true, preview)


func resolve_reaction_from_hand_pair(
		state: BattleState,
		actor_id: String,
		first_instance_id: String,
		second_instance_id: String,
		selected_product_id: String) -> Dictionary:
	var actor_error := _validate_actor(state, actor_id)
	if not actor_error.is_empty():
		return _reject(state, actor_error, "invalid_actor_or_phase")
	if first_instance_id == second_instance_id:
		return _reject(state, "Reaction inputs must be distinct card instances.", "duplicate_reaction_instance")
	var first: CardInstance = state.card_instances.get(first_instance_id)
	var second: CardInstance = state.card_instances.get(second_instance_id)
	if first == null or second == null or first.owner_id != actor_id or second.owner_id != actor_id or first.zone != "hand" or second.zone != "hand":
		return _reject(state, "Both reaction inputs must be in the actor's hand.", "card_not_in_hand")
	var first_def := catalog.get_card(first.definition_id)
	var second_def := catalog.get_card(second.definition_id)
	if first_def == null or second_def == null or not first_def.is_element_card or not second_def.is_element_card:
		return _reject(state, "Reaction inputs must both be element cards.", "not_an_element_card")
	var preview := _preview_pair(state, actor_id, first, second)
	if not bool(preview["valid"]):
		return _reject(state, String(preview["message"]), String(preview["reason_code"]))
	return _commit_reaction(state, actor_id, [first, second], selected_product_id, false, preview)


func clear_reaction(state: BattleState, actor_id: String) -> Dictionary:
	var actor_error := _validate_actor(state, actor_id)
	if not actor_error.is_empty():
		return _reject(state, actor_error, "invalid_actor_or_phase")
	var slots: Array = state.reaction_slots.get(actor_id, [])
	if slots.size() != 2 or (not (slots[0] is Dictionary) and not (slots[1] is Dictionary)):
		return _reject(state, "Reaction area is already empty.", "reaction_area_empty")
	var next_state := state.duplicate_state()
	var events: Array[Dictionary] = []
	_return_reaction_slots(next_state, actor_id, events)
	return _accept(next_state, events)


func begin_turn(state: BattleState, actor_id: String) -> Dictionary:
	if state.outcome != "ongoing":
		return _reject(state, "The battle has ended.", "battle_terminal")
	if not state.sides.has(actor_id):
		return _reject(state, "Unknown actor.", "invalid_actor")
	if state.phase == BattleState.PHASE_SETUP:
		if actor_id != BattleState.PLAYER_ID:
			return _reject(state, "The player must begin the battle.", "invalid_turn_order")
		if int(state.sides[actor_id].get("turn_count", 0)) != 0:
			return _reject(state, "The opening player turn has already begun.", "turn_already_started")
	elif state.phase == BattleState.PHASE_TURN_TRANSITION:
		if actor_id != _other_side(state.current_actor_id):
			return _reject(state, "The next turn belongs to the other participant.", "invalid_turn_order")
	else:
		return _reject(state, "The current turn must finish before another turn begins.", "turn_not_finished")
	var next_state := state.duplicate_state()
	var side: Dictionary = next_state.sides[actor_id]
	var events: Array[Dictionary] = []
	if int(side["turn_count"]) > 0:
		var previous_energy := int(side["energy"])
		side["energy"] = mini(int(side["max_energy"]), previous_energy + ENERGY_REGEN_PER_TURN)
		_emit(next_state, events, "energy_restored", {
			"actor_id": actor_id,
			"amount": int(side["energy"]) - previous_energy,
			"energy": side["energy"],
		})
		_draw_cards(next_state, actor_id, 1, "turn_start", events)
	if actor_id == BattleState.PLAYER_ID and int(side["turn_count"]) > 0:
		next_state.round_number += 1
	var effects: Dictionary = side["effects"]
	effects["fixture_first_damage_used_this_turn"] = false
	effects["fixture_first_reaction_used_this_turn"] = false
	side["turn_count"] = int(side["turn_count"]) + 1
	next_state.current_actor_id = actor_id
	next_state.phase = "%s_action" % actor_id
	_emit(next_state, events, "turn_started", {
		"actor_id": actor_id,
		"side_turn_count": side["turn_count"],
		"round_number": next_state.round_number,
	})
	var invariant_errors := next_state.validate_invariants(catalog)
	assert(invariant_errors.is_empty(), "Invalid state after begin_turn: %s" % "; ".join(invariant_errors))
	return _accept(next_state, events)


func finish_turn(state: BattleState, actor_id: String) -> Dictionary:
	if state.outcome != "ongoing":
		return _reject(state, "The battle has ended.", "battle_terminal")
	if actor_id != state.current_actor_id or not state.sides.has(actor_id) or state.phase != "%s_action" % actor_id:
		return _reject(state, "Only the current actor can end its turn.", "not_current_actor")
	var next_state := state.duplicate_state()
	var events: Array[Dictionary] = []
	_return_reaction_slots(next_state, actor_id, events)
	var actor_effects: Dictionary = next_state.sides[actor_id]["effects"]
	for effect_key in ["next_reaction_discount", "next_damage_bonus"]:
		if int(actor_effects.get(effect_key, 0)) > 0:
			actor_effects[effect_key] = 0
			_emit(next_state, events, "effect_expired", {"actor_id": actor_id, "effect_type": effect_key})
	var affected_side_id := _other_side(actor_id)
	var affected_effects: Dictionary = next_state.sides[affected_side_id]["effects"]
	if int(affected_effects.get("next_incoming_damage_reduction", 0)) > 0:
		affected_effects["next_incoming_damage_reduction"] = 0
		_emit(next_state, events, "effect_expired", {
			"actor_id": affected_side_id,
			"effect_type": "next_incoming_damage_reduction",
		})
	next_state.phase = BattleState.PHASE_TURN_TRANSITION
	_emit(next_state, events, "turn_ended", {"actor_id": actor_id})
	var invariant_errors := next_state.validate_invariants(catalog)
	assert(invariant_errors.is_empty(), "Invalid state after finish_turn: %s" % "; ".join(invariant_errors))
	return _accept(next_state, events)


func get_legal_play_actions(state: BattleState, actor_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if state.outcome != "ongoing" or not state.sides.has(actor_id):
		return actions
	var side: Dictionary = state.sides[actor_id]
	for instance_id in side["hand"]:
		var instance: CardInstance = state.card_instances.get(String(instance_id))
		if instance == null or instance.owner_id != actor_id or instance.zone != "hand":
			continue
		var definition := catalog.get_card(instance.definition_id)
		if definition == null or int(side["energy"]) < definition.energy_cost:
			continue
		for target_id in [BattleState.PLAYER_ID, BattleState.OPPONENT_ID]:
			if _validate_target(state, actor_id, target_id, definition.target_kind).is_empty():
				actions.append({
					"type": "play_card",
					"instance_id": instance.instance_id,
					"definition_id": String(definition.id),
					"target_id": target_id,
					"energy_cost": definition.energy_cost,
					"base_damage": definition.base_damage,
					"category": String(definition.category),
				})
	return actions


func get_legal_reaction_actions(state: BattleState, actor_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if state.outcome != "ongoing" or not state.sides.has(actor_id):
		return actions
	var pairs: Array[Array] = _possible_reaction_pairs(state, actor_id)
	var side: Dictionary = state.sides[actor_id]
	var discount := int(side["effects"].get("next_reaction_discount", 0))
	var cost := maxi(0, REACTION_BASE_COST - discount)
	if int(side["energy"]) < cost:
		return actions
	for pair in pairs:
		var first: CardInstance = pair[0]
		var second: CardInstance = pair[1]
		var recipe := catalog.get_recipe(first.definition_id, second.definition_id)
		if recipe == null:
			continue
		actions.append({
			"type": "reaction",
			"instance_ids": [first.instance_id, second.instance_id],
			"definition_ids": [first.definition_id, second.definition_id],
			"product_ids": _string_ids(recipe.product_ids),
			"cost": cost,
		})
	return actions


func has_legal_action(state: BattleState, actor_id: String) -> bool:
	return not get_legal_play_actions(state, actor_id).is_empty() or not get_legal_reaction_actions(state, actor_id).is_empty()


func _commit_reaction(
		state: BattleState,
		actor_id: String,
		instances: Array[CardInstance],
		selected_product_id: String,
		from_slots: bool,
		preview: Dictionary) -> Dictionary:
	var candidates: Array = preview["candidate_product_ids"]
	var product_id := selected_product_id.strip_edges().to_lower()
	if product_id.is_empty() and candidates.size() == 1:
		product_id = String(candidates[0])
	if product_id.is_empty():
		return _reject(state, "Choose one reaction product before resolving.", "product_selection_required")
	if not candidates.has(product_id):
		return _reject(state, "Selected product is not a candidate for this reaction.", "invalid_product_selection")
	var side: Dictionary = state.sides[actor_id]
	var cost := int(preview["cost"])
	if int(side["energy"]) < cost:
		return _reject(state, "Not enough energy to resolve this reaction.", "insufficient_energy")
	var next_state := state.duplicate_state()
	var next_side: Dictionary = next_state.sides[actor_id]
	var next_slots: Array = next_state.reaction_slots[actor_id]
	next_side["energy"] = int(next_side["energy"]) - cost
	next_side["effects"]["next_reaction_discount"] = 0
	for instance in instances:
		var next_instance: CardInstance = next_state.card_instances[instance.instance_id]
		if from_slots:
			next_slots[0] = null
			next_slots[1] = null
		else:
			var hand_index: int = next_side["hand"].find(instance.instance_id)
			if hand_index < 0:
				return _reject(state, "Reaction input moved before resolution.", "card_not_in_hand")
			next_side["hand"].remove_at(hand_index)
		_add_to_discard(next_state, next_instance)
	var product_instance := next_state.create_instance(product_id, actor_id, "hand")
	next_side["hand"].append(product_instance.instance_id)
	var events: Array[Dictionary] = []
	_emit(next_state, events, "reaction_resolved", {
		"actor_id": actor_id,
		"input_instance_ids": [instances[0].instance_id, instances[1].instance_id],
		"input_definition_ids": [instances[0].definition_id, instances[1].definition_id],
		"product_instance_id": product_instance.instance_id,
		"product_id": product_id,
		"energy_cost": cost,
	})
	if bool(next_state.fixture_rules.get("enabled", false)) and not bool(next_side["effects"]["fixture_first_reaction_used_this_turn"]):
		next_side["effects"]["fixture_first_reaction_used_this_turn"] = true
		_draw_cards(next_state, actor_id, int(next_state.fixture_rules.get("first_reaction_draw", 0)), "fixture_first_reaction", events)
	if bool(next_side["effects"].get("draw_after_next_reaction", false)):
		next_side["effects"]["draw_after_next_reaction"] = false
		_draw_cards(next_state, actor_id, 1, "draw_after_reaction", events)
	OutcomeEvaluator.refresh(next_state)
	if next_state.outcome != "ongoing":
		events.append(next_state.event_log.back().duplicate(true))
	var invariant_errors := next_state.validate_invariants(catalog)
	assert(invariant_errors.is_empty(), "Invalid state after reaction: %s" % "; ".join(invariant_errors))
	return _accept(next_state, events)


func _preview_pair(state: BattleState, actor_id: String, first: CardInstance, second: CardInstance) -> Dictionary:
	if first.instance_id == second.instance_id:
		return _invalid_preview("duplicate_reaction_instance", "Reaction cards must be distinct instances.")
	var first_def := catalog.get_card(first.definition_id)
	var second_def := catalog.get_card(second.definition_id)
	if first_def == null or second_def == null or not first_def.is_element_card or not second_def.is_element_card:
		return _invalid_preview("not_an_element_card", "Only element cards can react.")
	var recipe := catalog.get_recipe(first.definition_id, second.definition_id)
	if recipe == null:
		return _invalid_preview("unsupported_recipe", "This combination is not supported in the battle fixture.")
	var side: Dictionary = state.sides[actor_id]
	var discount := int(side["effects"].get("next_reaction_discount", 0))
	return {
		"valid": true,
		"reason_code": "",
		"message": "",
		"recipe_id": String(recipe.id),
		"candidate_product_ids": _string_ids(recipe.product_ids),
		"cost": maxi(0, REACTION_BASE_COST - discount),
		"discount": discount,
	}


func _possible_reaction_pairs(state: BattleState, actor_id: String) -> Array[Array]:
	var pairs: Array[Array] = []
	var slots: Array = state.reaction_slots.get(actor_id, [null, null])
	var occupied: Array[CardInstance] = []
	for slot in slots:
		if slot is Dictionary:
			var slot_instance: CardInstance = state.card_instances.get(String(slot.get("instance_id", "")))
			if slot_instance != null:
				occupied.append(slot_instance)
	var candidates: Array[CardInstance] = []
	for instance_id in state.sides[actor_id]["hand"]:
		var instance: CardInstance = state.card_instances.get(String(instance_id))
		if instance == null:
			continue
		var definition := catalog.get_card(instance.definition_id)
		if definition == null or not definition.is_element_card:
			continue
		candidates.append(instance)
	if occupied.size() >= 2:
		pairs.append([occupied[0], occupied[1]])
	elif occupied.size() == 1:
		for candidate in candidates:
			if candidate.instance_id != occupied[0].instance_id:
				pairs.append([occupied[0], candidate])
	else:
		for left_index in candidates.size():
			for right_index in range(left_index + 1, candidates.size()):
				pairs.append([candidates[left_index], candidates[right_index]])
	return pairs


func _apply_damage(
		state: BattleState,
		actor_id: String,
		target_id: String,
		definition: CardDefinition,
		base_damage: int,
		events: Array[Dictionary]) -> void:
	var actor_side: Dictionary = state.sides[actor_id]
	var target_side: Dictionary = state.sides[target_id]
	var effects: Dictionary = actor_side["effects"]
	var damage := base_damage
	var source_damage_bonus := int(effects.get("next_damage_bonus", 0))
	if source_damage_bonus > 0:
		damage += source_damage_bonus
		effects["next_damage_bonus"] = 0
		_emit(state, events, "effect_consumed", {
			"actor_id": actor_id,
			"effect_type": "next_damage_bonus",
			"amount": source_damage_bonus,
		})
	var fixture_bonus := 0
	if bool(state.fixture_rules.get("enabled", false)) and not bool(effects.get("fixture_first_damage_used_this_turn", false)):
		fixture_bonus = int(state.fixture_rules.get("first_damage_bonus", 0))
		effects["fixture_first_damage_used_this_turn"] = true
		damage += fixture_bonus
		if fixture_bonus > 0:
			_emit(state, events, "fixture_modifier_applied", {
				"actor_id": actor_id,
				"modifier": "first_damage_bonus",
				"amount": fixture_bonus,
			})
	var reduction := int(target_side["effects"].get("next_incoming_damage_reduction", 0))
	if reduction > 0:
		damage = maxi(0, damage - reduction)
		target_side["effects"]["next_incoming_damage_reduction"] = 0
		_emit(state, events, "effect_consumed", {
			"actor_id": target_id,
			"effect_type": "next_incoming_damage_reduction",
			"amount": reduction,
		})
	damage = maxi(0, damage)
	var previous_hp := int(target_side["hp"])
	target_side["hp"] = maxi(0, previous_hp - damage)
	_emit(state, events, "damage_dealt", {
		"actor_id": actor_id,
		"target_id": target_id,
		"definition_id": String(definition.id),
		"base_damage": base_damage,
		"source_bonus": source_damage_bonus,
		"fixture_bonus": fixture_bonus,
		"reduction": reduction,
		"amount": damage,
		"hp_before": previous_hp,
		"hp_after": target_side["hp"],
	})


func _draw_cards(
		state: BattleState,
		actor_id: String,
		count: int,
		source: String,
		events: Array[Dictionary]) -> void:
	var side: Dictionary = state.sides[actor_id]
	for draw_index in count:
		if side["draw_pile"].is_empty():
			_emit(state, events, "draw_pile_empty", {"actor_id": actor_id, "source": source})
			continue
		var instance_id: String = side["draw_pile"].pop_front()
		var instance: CardInstance = state.card_instances[instance_id]
		instance.zone = "hand"
		instance.hand_order = int(side.get("next_hand_order", 0))
		side["next_hand_order"] = instance.hand_order + 1
		side["hand"].append(instance_id)
		_emit(state, events, "card_drawn", {
			"actor_id": actor_id,
			"instance_id": instance_id,
			"definition_id": instance.definition_id,
			"source": source,
		})


func _return_reaction_slots(state: BattleState, actor_id: String, events: Array[Dictionary]) -> void:
	var slots: Array = state.reaction_slots[actor_id]
	var returned: Array[Dictionary] = []
	for slot in slots:
		if slot is Dictionary:
			returned.append(slot.duplicate(true))
	returned.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("original_hand_order", a.get("original_hand_index", 0))) < int(b.get("original_hand_order", b.get("original_hand_index", 0))))
	for slot in returned:
		var instance_id := String(slot.get("instance_id", ""))
		var instance: CardInstance = state.card_instances.get(instance_id)
		if instance == null:
			continue
		instance.zone = "hand"
		var hand: Array = state.sides[actor_id]["hand"]
		hand.append(instance_id)
		hand.sort_custom(func(left_id: String, right_id: String) -> bool:
			var left: CardInstance = state.card_instances[String(left_id)]
			var right: CardInstance = state.card_instances[String(right_id)]
			return left.hand_order < right.hand_order)
		_emit(state, events, "reaction_card_returned", {
			"actor_id": actor_id,
			"instance_id": instance_id,
			"definition_id": instance.definition_id,
			"original_hand_index": slot.get("original_hand_index", -1),
		})
	state.reaction_slots[actor_id] = [null, null]


func _add_to_discard(state: BattleState, instance: CardInstance) -> void:
	instance.zone = "discard_pile"
	state.sides[instance.owner_id]["discard_pile"].append(instance.instance_id)


func _validate_actor(state: BattleState, actor_id: String) -> String:
	if state.outcome != "ongoing":
		return "The battle has ended."
	if not state.sides.has(actor_id):
		return "Unknown actor."
	if actor_id != state.current_actor_id or state.phase != "%s_action" % actor_id:
		return "It is not this actor's action phase."
	return ""


func _validate_target(state: BattleState, actor_id: String, target_id: String, target_kind: StringName) -> String:
	if target_id not in [BattleState.PLAYER_ID, BattleState.OPPONENT_ID] or not state.sides.has(target_id):
		return "The target is not a battle participant."
	if int(state.sides[target_id].get("hp", 0)) <= 0:
		return "A defeated target cannot be selected."
	if target_kind == &"self" and target_id != actor_id:
		return "This card must target its owner."
	if target_kind == &"opponent" and target_id == actor_id:
		return "This card must target the opponent."
	if target_kind not in [&"self", &"opponent", &"any"]:
		return "This card has an unsupported target rule."
	return ""


func _invalid_preview(reason_code: String, message: String) -> Dictionary:
	return {
		"valid": false,
		"reason_code": reason_code,
		"message": message,
		"recipe_id": "",
		"candidate_product_ids": [],
		"cost": REACTION_BASE_COST,
		"discount": 0,
	}


func _accept(next_state: BattleState, events: Array[Dictionary]) -> Dictionary:
	return {"accepted": true, "state_changed": true, "reason_code": "", "events": _copy_events(events), "state": next_state}


func _reject(state: BattleState, message: String, reason_code: String) -> Dictionary:
	return {"accepted": false, "state_changed": false, "reason_code": reason_code, "message": message, "events": [], "state": state}


func _emit(state: BattleState, events: Array[Dictionary], event_type: String, data: Dictionary = {}) -> void:
	events.append(state.append_event(event_type, data).duplicate(true))


func _other_side(actor_id: String) -> String:
	return BattleState.OPPONENT_ID if actor_id == BattleState.PLAYER_ID else BattleState.PLAYER_ID


func _string_ids(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value).to_lower())
	return result


func _copy_events(events: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		result.append(event.duplicate(true))
	return result
