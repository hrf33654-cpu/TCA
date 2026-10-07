extends GdUnitTestSuite

var catalog: BattleContentCatalog
var rules: BattleRules
var state: BattleState


func before_test() -> void:
	catalog = BattleContentLoader.load_fixture_catalog()["catalog"] as BattleContentCatalog
	rules = BattleRules.new(catalog)
	state = BattleFactory.create_fixture(catalog, BattleSession.DEFAULT_SEED)
	state = rules.begin_turn(state, BattleState.PLAYER_ID)["state"] as BattleState


func test_turn_lifecycle_rejects_repeated_and_out_of_order_transitions_without_mutation() -> void:
	var before := state.to_view_state(catalog)
	var repeated_begin := rules.begin_turn(state, BattleState.PLAYER_ID)
	assert_that(repeated_begin["accepted"]).is_false()
	assert_that(repeated_begin["reason_code"]).is_equal("turn_not_finished")
	assert_that(state.to_view_state(catalog)).is_equal(before)
	var skipped_turn := rules.begin_turn(state, BattleState.OPPONENT_ID)
	assert_that(skipped_turn["accepted"]).is_false()
	assert_that(skipped_turn["reason_code"]).is_equal("turn_not_finished")
	assert_that(state.to_view_state(catalog)).is_equal(before)

	var finished_player := rules.finish_turn(state, BattleState.PLAYER_ID)
	assert_that(finished_player["accepted"]).is_true()
	var transition_state: BattleState = finished_player["state"]
	assert_that(transition_state.phase).is_equal(BattleState.PHASE_TURN_TRANSITION)
	var repeated_player := rules.begin_turn(transition_state, BattleState.PLAYER_ID)
	assert_that(repeated_player["accepted"]).is_false()
	assert_that(repeated_player["reason_code"]).is_equal("invalid_turn_order")
	assert_that(transition_state.phase).is_equal(BattleState.PHASE_TURN_TRANSITION)

	var began_opponent := rules.begin_turn(transition_state, BattleState.OPPONENT_ID)
	assert_that(began_opponent["accepted"]).is_true()
	var opponent_state: BattleState = began_opponent["state"]
	var opponent_before := opponent_state.to_view_state(catalog)
	var repeated_opponent := rules.begin_turn(opponent_state, BattleState.OPPONENT_ID)
	assert_that(repeated_opponent["accepted"]).is_false()
	assert_that(repeated_opponent["reason_code"]).is_equal("turn_not_finished")
	assert_that(opponent_state.to_view_state(catalog)).is_equal(opponent_before)
	assert_that(opponent_state.validate_invariants(catalog)).is_empty()


func test_play_damage_card_applies_fixture_bonus_and_moves_unique_instance() -> void:
	var instance_id := _hand_instance_id(state, BattleState.PLAYER_ID, "o")
	var result := rules.play_card(state, BattleState.PLAYER_ID, instance_id, BattleState.OPPONENT_ID)
	assert_that(result["accepted"]).is_true()
	var next_state: BattleState = result["state"]
	assert_that(next_state.sides[BattleState.PLAYER_ID]["energy"]).is_equal(6)
	assert_that(next_state.sides[BattleState.OPPONENT_ID]["hp"]).is_equal(27)
	assert_that(next_state.sides[BattleState.PLAYER_ID]["hand"].size()).is_equal(9)
	assert_that(next_state.sides[BattleState.PLAYER_ID]["discard_pile"].has(instance_id)).is_true()
	assert_that(next_state.card_instances[instance_id].zone).is_equal("discard_pile")
	assert_that(next_state.sides[BattleState.PLAYER_ID]["effects"]["fixture_first_damage_used_this_turn"]).is_true()
	assert_that(state.sides[BattleState.PLAYER_ID]["energy"]).is_equal(8)
	assert_that(state.sides[BattleState.OPPONENT_ID]["hp"]).is_equal(30)


func test_rejected_play_for_wrong_target_has_zero_side_effects() -> void:
	var before := state.to_view_state(catalog)
	var result := rules.play_card(state, BattleState.PLAYER_ID, _hand_instance_id(state, "player", "o"), "player")
	assert_that(result["accepted"]).is_false()
	assert_that(result["reason_code"]).is_equal("invalid_target")
	assert_that(state.to_view_state(catalog)).is_equal(before)
	assert_that(result["state"]).is_same(state)


func test_rejected_play_for_missing_instance_has_zero_side_effects() -> void:
	var before := state.to_view_state(catalog)
	var result := rules.play_card(state, "player", "not-a-card-instance", "opponent")
	assert_that(result["accepted"]).is_false()
	assert_that(result["reason_code"]).is_equal("card_not_in_hand")
	assert_that(state.to_view_state(catalog)).is_equal(before)


func test_rejected_play_for_insufficient_energy_has_zero_side_effects() -> void:
	state.sides["player"]["energy"] = 1
	var before := state.to_view_state(catalog)
	var result := rules.play_card(state, "player", _hand_instance_id(state, "player", "cl"), "opponent")
	assert_that(result["accepted"]).is_false()
	assert_that(result["reason_code"]).is_equal("insufficient_energy")
	assert_that(state.to_view_state(catalog)).is_equal(before)


func test_reaction_preview_is_order_independent_and_requires_product_choice() -> void:
	var c_id := _hand_instance_id(state, "player", "c")
	var o_id := _hand_instance_id(state, "player", "o")
	var first_assignment := rules.assign_reaction_card(state, "player", o_id, 0)
	assert_that(first_assignment["accepted"]).is_true()
	state = first_assignment["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", c_id, 1)["state"] as BattleState
	var preview := rules.preview_reaction(state, "player")
	assert_that(preview["valid"]).is_true()
	assert_that(preview["candidate_product_ids"]).is_equal(["co", "co2"])
	assert_that(preview["cost"]).is_equal(2)
	var before := state.to_view_state(catalog)
	var unselected := rules.resolve_reaction(state, "player", "")
	assert_that(unselected["accepted"]).is_false()
	assert_that(unselected["reason_code"]).is_equal("product_selection_required")
	assert_that(state.to_view_state(catalog)).is_equal(before)
	var invalid_product := rules.resolve_reaction(state, "player", "no")
	assert_that(invalid_product["accepted"]).is_false()
	assert_that(state.to_view_state(catalog)).is_equal(before)
	var resolved := rules.resolve_reaction(state, "player", "co2")
	assert_that(resolved["accepted"]).is_true()
	var next_state: BattleState = resolved["state"]
	assert_that(next_state.sides["player"]["energy"]).is_equal(6)
	assert_that(next_state.sides["player"]["hand"].size()).is_equal(10)
	assert_that(next_state.sides["player"]["discard_pile"].has(c_id)).is_true()
	assert_that(next_state.sides["player"]["discard_pile"].has(o_id)).is_true()
	var products := _instances_for_definition(next_state, "player", "co2", "hand")
	assert_that(products.size()).is_equal(1)
	assert_that(products[0] != c_id and products[0] != o_id).is_true()
	assert_that(next_state.reaction_slots["player"]).is_equal([null, null])


func test_unsupported_reaction_is_read_only_and_keeps_both_inputs_in_slots() -> void:
	var c_id := _hand_instance_id(state, "player", "c")
	var cl_id := _hand_instance_id(state, "player", "cl")
	state = rules.assign_reaction_card(state, "player", c_id, 0)["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", cl_id, 1)["state"] as BattleState
	var before := state.to_view_state(catalog)
	assert_that(rules.preview_reaction(state, "player")["reason_code"]).is_equal("unsupported_recipe")
	var result := rules.resolve_reaction(state, "player", "")
	assert_that(result["accepted"]).is_false()
	assert_that(result["reason_code"]).is_equal("unsupported_recipe")
	assert_that(state.to_view_state(catalog)).is_equal(before)
	assert_that(state.reaction_slots["player"][0]["instance_id"]).is_equal(c_id)
	assert_that(state.reaction_slots["player"][1]["instance_id"]).is_equal(cl_id)


func test_same_definition_cards_are_distinct_instances_and_can_react() -> void:
	var first_c := _hand_instance_id(state, "player", "c")
	var second_c := _move_draw_card_to_hand(state, "player", "c")
	assert_that(first_c).is_not_equal(second_c)
	var first_assignment := rules.assign_reaction_card(state, "player", first_c, 0)
	assert_that(first_assignment["accepted"]).is_true()
	state = first_assignment["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", second_c, 1)["state"] as BattleState
	var preview := rules.preview_reaction(state, "player")
	assert_that(preview["valid"]).is_true()
	assert_that(preview["candidate_product_ids"]).is_equal(["c"])
	var result := rules.resolve_reaction(state, "player", "c")
	assert_that(result["accepted"]).is_true()
	var next_state: BattleState = result["state"]
	assert_that(next_state.sides["player"]["discard_pile"].has(first_c)).is_true()
	assert_that(next_state.sides["player"]["discard_pile"].has(second_c)).is_true()
	var c_products := _instances_for_definition(next_state, "player", "c", "hand")
	assert_that(c_products.size()).is_equal(1)
	assert_that(c_products[0] != first_c and c_products[0] != second_c).is_true()
	assert_that(catalog.get_card(next_state.card_instances[c_products[0]].definition_id).is_element_card).is_true()


func test_c_discount_is_consumed_only_by_successful_reaction() -> void:
	var c_buff_id := _hand_instance_id(state, "player", "c")
	state = rules.play_card(state, "player", c_buff_id, "player")["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["next_reaction_discount"]).is_equal(1)
	var n_id := _hand_instance_id(state, "player", "n")
	var o_id := _hand_instance_id(state, "player", "o")
	state = rules.assign_reaction_card(state, "player", n_id, 0)["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", o_id, 1)["state"] as BattleState
	assert_that(rules.preview_reaction(state, "player")["cost"]).is_equal(1)
	state.sides["player"]["energy"] = 0
	var before := state.to_view_state(catalog)
	var failed := rules.resolve_reaction(state, "player", "no")
	assert_that(failed["accepted"]).is_false()
	assert_that(failed["reason_code"]).is_equal("insufficient_energy")
	assert_that(state.to_view_state(catalog)).is_equal(before)
	state.sides["player"]["energy"] = 1
	var resolved := rules.resolve_reaction(state, "player", "no")
	assert_that(resolved["accepted"]).is_true()
	assert_that(resolved["state"].sides["player"]["effects"]["next_reaction_discount"]).is_equal(0)


func test_repeated_c_card_does_not_stack_reaction_discount() -> void:
	var first_c := _hand_instance_id(state, "player", "c")
	var second_c := _move_draw_card_to_hand(state, "player", "c")
	state = rules.play_card(state, "player", first_c, "player")["state"] as BattleState
	state = rules.play_card(state, "player", second_c, "player")["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["next_reaction_discount"]).is_equal(1)


func test_n_reduction_applies_once_and_expires_after_opponent_turn_end() -> void:
	var n_id := _hand_instance_id(state, "player", "n")
	state = rules.play_card(state, "player", n_id, "player")["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["next_incoming_damage_reduction"]).is_equal(1)
	state = rules.finish_turn(state, "player")["state"] as BattleState
	state = rules.begin_turn(state, "opponent")["state"] as BattleState
	var opponent_o := _hand_instance_id(state, "opponent", "o")
	var attack := rules.play_card(state, "opponent", opponent_o, "player")
	assert_that(attack["accepted"]).is_true()
	state = attack["state"] as BattleState
	assert_that(state.sides["player"]["hp"]).is_equal(28)
	assert_that(state.sides["player"]["effects"]["next_incoming_damage_reduction"]).is_equal(0)
	state = rules.finish_turn(state, "opponent")["state"] as BattleState
	state = rules.begin_turn(state, "player")["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["next_incoming_damage_reduction"]).is_equal(0)


func test_s_bonus_is_consumed_on_successful_damage_and_fixture_bonus_is_once_per_turn() -> void:
	var s_id := _hand_instance_id(state, "player", "s")
	var o_id := _hand_instance_id(state, "player", "o")
	state = rules.play_card(state, "player", s_id, "player")["state"] as BattleState
	state = rules.play_card(state, "player", o_id, "opponent")["state"] as BattleState
	assert_that(state.sides["opponent"]["hp"]).is_equal(26)
	assert_that(state.sides["player"]["effects"]["next_damage_bonus"]).is_equal(0)
	var cl_id := _hand_instance_id(state, "player", "cl")
	state = rules.play_card(state, "player", cl_id, "opponent")["state"] as BattleState
	assert_that(state.sides["opponent"]["hp"]).is_equal(23)


func test_b_draw_marker_persists_across_turns_and_is_consumed_by_successful_reaction() -> void:
	var b_id := _hand_instance_id(state, "player", "b")
	state = rules.play_card(state, "player", b_id, "player")["state"] as BattleState
	state = rules.finish_turn(state, "player")["state"] as BattleState
	state = rules.begin_turn(state, "opponent")["state"] as BattleState
	state = rules.finish_turn(state, "opponent")["state"] as BattleState
	state = rules.begin_turn(state, "player")["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["draw_after_next_reaction"]).is_true()
	var before_hand_count: int = state.sides["player"]["hand"].size()
	var c_id := _hand_instance_id(state, "player", "c")
	var o_id := _hand_instance_id(state, "player", "o")
	state = rules.assign_reaction_card(state, "player", c_id, 0)["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", o_id, 1)["state"] as BattleState
	state = rules.resolve_reaction(state, "player", "co")["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["draw_after_next_reaction"]).is_false()
	assert_that(state.sides["player"]["hand"].size()).is_equal(before_hand_count - 2 + 1 + 1 + 1)


func test_clear_and_end_turn_return_staged_cards_in_original_hand_order() -> void:
	var original_hand: Array = state.sides["player"]["hand"].duplicate()
	var c_id := _hand_instance_id(state, "player", "c")
	var o_id := _hand_instance_id(state, "player", "o")
	state = rules.assign_reaction_card(state, "player", o_id, 0)["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", c_id, 1)["state"] as BattleState
	state = rules.clear_reaction(state, "player")["state"] as BattleState
	assert_that(state.sides["player"]["hand"]).is_equal(original_hand)
	state = rules.assign_reaction_card(state, "player", o_id, 0)["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", c_id, 1)["state"] as BattleState
	state = rules.finish_turn(state, "player")["state"] as BattleState
	assert_that(state.sides["player"]["hand"]).is_equal(original_hand)
	assert_that(state.reaction_slots["player"]).is_equal([null, null])
	assert_that(state.sides["player"]["effects"]["next_reaction_discount"]).is_equal(0)


func test_outcome_evaluator_is_symmetric_and_draws_when_both_sides_fail() -> void:
	var player_empty := state.duplicate_state()
	player_empty.sides["player"]["hand"].clear()
	assert_that(OutcomeEvaluator.evaluate(player_empty)).is_equal("player_lost")
	var opponent_empty := state.duplicate_state()
	opponent_empty.sides["opponent"]["hp"] = 0
	assert_that(OutcomeEvaluator.evaluate(opponent_empty)).is_equal("player_won")
	var player_hp_zero := state.duplicate_state()
	player_hp_zero.sides["player"]["hp"] = 0
	assert_that(OutcomeEvaluator.evaluate(player_hp_zero)).is_equal("player_lost")
	var both_empty := state.duplicate_state()
	both_empty.sides["player"]["hp"] = 0
	both_empty.sides["opponent"]["hand"].clear()
	assert_that(OutcomeEvaluator.evaluate(both_empty)).is_equal("draw")


func test_card_and_reaction_draw_effects_are_safe_when_draw_pile_is_empty() -> void:
	for instance_id in state.sides["player"]["draw_pile"]:
		var instance: CardInstance = state.card_instances[String(instance_id)]
		instance.zone = "discard_pile"
		state.sides["player"]["discard_pile"].append(instance.instance_id)
	state.sides["player"]["draw_pile"].clear()
	var ar_id := _hand_instance_id(state, "player", "ar")
	var hand_before_ar: int = state.sides["player"]["hand"].size()
	var ar_result := rules.play_card(state, "player", ar_id, "player")
	assert_that(ar_result["accepted"]).is_true()
	state = ar_result["state"] as BattleState
	assert_that(state.sides["player"]["hand"].size()).is_equal(hand_before_ar - 1)
	assert_that(state.sides["player"]["draw_pile"]).is_empty()
	state.sides["player"]["effects"]["draw_after_next_reaction"] = true
	var c_id := _hand_instance_id(state, "player", "c")
	var o_id := _hand_instance_id(state, "player", "o")
	state = rules.assign_reaction_card(state, "player", c_id, 0)["state"] as BattleState
	state = rules.assign_reaction_card(state, "player", o_id, 1)["state"] as BattleState
	var reaction := rules.resolve_reaction(state, "player", "co")
	assert_that(reaction["accepted"]).is_true()
	state = reaction["state"] as BattleState
	assert_that(state.sides["player"]["effects"]["draw_after_next_reaction"]).is_false()
	assert_that(state.sides["player"]["draw_pile"]).is_empty()
	assert_that(_event_count(reaction["events"], "draw_pile_empty")).is_equal(2)


func _hand_instance_id(battle_state: BattleState, owner_id: String, definition_id: String) -> String:
	for instance_id in battle_state.sides[owner_id]["hand"]:
		var instance: CardInstance = battle_state.card_instances[String(instance_id)]
		if instance.definition_id == definition_id:
			return instance.instance_id
	return ""


func _move_draw_card_to_hand(battle_state: BattleState, owner_id: String, definition_id: String) -> String:
	var draw_pile: Array = battle_state.sides[owner_id]["draw_pile"]
	for index in draw_pile.size():
		var instance_id := String(draw_pile[index])
		var instance: CardInstance = battle_state.card_instances[instance_id]
		if instance.definition_id == definition_id:
			draw_pile.remove_at(index)
			instance.zone = "hand"
			instance.hand_order = int(battle_state.sides[owner_id]["next_hand_order"])
			battle_state.sides[owner_id]["next_hand_order"] = instance.hand_order + 1
			battle_state.sides[owner_id]["hand"].append(instance_id)
			return instance_id
	return ""


func _instances_for_definition(battle_state: BattleState, owner_id: String, definition_id: String, zone: String) -> Array[String]:
	var result: Array[String] = []
	var side: Dictionary = battle_state.sides[owner_id]
	var zone_cards: Array = side[zone]
	for instance_id in zone_cards:
		var instance: CardInstance = battle_state.card_instances[String(instance_id)]
		if instance.definition_id == definition_id:
			result.append(instance.instance_id)
	return result


func _event_count(events: Array, event_type: String) -> int:
	var count := 0
	for event in events:
		if String(event.get("type", "")) == event_type:
			count += 1
	return count
