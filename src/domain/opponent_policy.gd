extends RefCounted
class_name OpponentPolicy

var rules: BattleRules


func _init(p_rules: BattleRules) -> void:
	rules = p_rules


func choose_action(state: BattleState) -> Dictionary:
	if state.current_actor_id != BattleState.OPPONENT_ID or state.phase != "opponent_action" or state.outcome != "ongoing":
		return {"type": "none", "reason_code": "not_opponent_action"}
	var reactions := rules.get_legal_reaction_actions(state, BattleState.OPPONENT_ID)
	if not reactions.is_empty():
		reactions.sort_custom(_reaction_less)
		var chosen: Dictionary = reactions[0]
		var candidates: Array = chosen["product_ids"].duplicate()
		candidates.sort()
		return {
			"type": "reaction",
			"instance_ids": chosen["instance_ids"].duplicate(),
			"product_id": String(candidates[0]) if not candidates.is_empty() else "",
		}
	var play_actions := rules.get_legal_play_actions(state, BattleState.OPPONENT_ID)
	var damage_actions: Array[Dictionary] = []
	for action in play_actions:
		if int(action.get("base_damage", 0)) > 0 and String(action.get("target_id", "")) == BattleState.PLAYER_ID:
			damage_actions.append(action)
	if not damage_actions.is_empty():
		damage_actions.sort_custom(_damage_less)
		return damage_actions[0].duplicate(true)
	var self_actions: Array[Dictionary] = []
	for action in play_actions:
		if String(action.get("target_id", "")) == BattleState.OPPONENT_ID:
			self_actions.append(action)
	if not self_actions.is_empty():
		self_actions.sort_custom(_self_card_less)
		return self_actions[0].duplicate(true)
	return {"type": "none", "reason_code": "no_legal_action"}


func _reaction_less(left: Dictionary, right: Dictionary) -> bool:
	var left_ids: Array = left.get("definition_ids", []).duplicate()
	var right_ids: Array = right.get("definition_ids", []).duplicate()
	left_ids.sort()
	right_ids.sort()
	var left_instance_ids: Array = left.get("instance_ids", []).duplicate()
	var right_instance_ids: Array = right.get("instance_ids", []).duplicate()
	left_instance_ids.sort()
	right_instance_ids.sort()
	var left_key := "%s|%s|%s|%s" % [left_ids[0], left_ids[1], left_instance_ids[0], left_instance_ids[1]]
	var right_key := "%s|%s|%s|%s" % [right_ids[0], right_ids[1], right_instance_ids[0], right_instance_ids[1]]
	return left_key < right_key


func _damage_less(left: Dictionary, right: Dictionary) -> bool:
	var left_damage := int(left.get("base_damage", 0))
	var right_damage := int(right.get("base_damage", 0))
	if left_damage != right_damage:
		return left_damage > right_damage
	return _stable_card_key(left) < _stable_card_key(right)


func _self_card_less(left: Dictionary, right: Dictionary) -> bool:
	var left_cost := int(left.get("energy_cost", 0))
	var right_cost := int(right.get("energy_cost", 0))
	if left_cost != right_cost:
		return left_cost < right_cost
	return _stable_card_key(left) < _stable_card_key(right)


func _stable_card_key(action: Dictionary) -> String:
	return "%s|%s" % [String(action.get("definition_id", "")), String(action.get("instance_id", ""))]
