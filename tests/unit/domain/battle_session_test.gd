extends GdUnitTestSuite


func test_fixture_has_expected_unique_opening_cards_and_deterministic_piles() -> void:
	var first := BattleSession.create_fixture()
	var same_seed := BattleSession.create_fixture()
	assert_that(first.is_ready()).is_true()
	var first_view := first.get_view_state()
	assert_that(first_view["outcome"]).is_equal("ongoing")
	assert_that(first_view["phase"]).is_equal("player_action")
	assert_that(first_view["round_number"]).is_equal(1)
	assert_that(first_view["player"]["hp"]).is_equal(30)
	assert_that(first_view["player"]["energy"]).is_equal(8)
	assert_that(first_view["player"]["hand_count"]).is_equal(10)
	assert_that(first_view["player"]["draw_pile_count"]).is_equal(12)
	assert_that(first_view["opponent"]["hand_count"]).is_equal(10)
	assert_that(first_view["opponent"]["draw_pile_count"]).is_equal(12)
	assert_that(_definition_ids(first_view["player"]["hand"])).is_equal(["c", "n", "o", "cl", "b", "s", "ar", "co", "no2", "h2o2"])
	assert_that(_instance_ids(first_view["player"]["hand"])).is_not_equal(_instance_ids(first_view["opponent"]["hand"]))
	assert_that(_draw_cards(first).size()).is_equal(24)
	assert_that(_draw_ids(first)).is_equal(_draw_ids(same_seed))
	assert_that(first.state.validate_invariants(first.catalog)).is_empty()


func test_rejected_session_command_returns_unchanged_view_state() -> void:
	var session := BattleSession.create_fixture()
	var before := session.get_view_state()
	var o_id := _hand_instance_id(session, "player", "o")
	var result := session.play_card("player", o_id, "player")
	assert_that(result["accepted"]).is_false()
	assert_that(result["state_changed"]).is_false()
	assert_that(result["reason_code"]).is_equal("invalid_target")
	assert_that(session.get_view_state()).is_equal(before)
	assert_that(result["view_state"]).is_equal(before)


func test_only_player_commands_can_mutate_the_application_session() -> void:
	var session := BattleSession.create_fixture()
	var before := session.get_view_state()
	var opponent_card_id := _hand_instance_id(session, "opponent", "o")
	var result := session.play_card("opponent", opponent_card_id, "player")
	assert_that(result["accepted"]).is_false()
	assert_that(result["reason_code"]).is_equal("player_command_only")
	assert_that(session.get_view_state()).is_equal(before)


func test_ai_uses_deterministic_reaction_then_returns_control_to_player() -> void:
	var session := BattleSession.create_fixture()
	session.state.sides["player"]["energy"] = 5
	var finished_player := session.rules.finish_turn(session.state, "player")
	var begin_ai := session.rules.begin_turn(finished_player["state"] as BattleState, "opponent")
	var ai_state: BattleState = begin_ai["state"]
	var first_action := session.opponent_policy.choose_action(ai_state)
	var second_action := session.opponent_policy.choose_action(ai_state)
	assert_that(first_action).is_equal(second_action)
	assert_that(first_action["type"]).is_equal("reaction")
	assert_that(first_action["product_id"]).is_equal("co")
	var result := session.end_turn("player")
	assert_that(result["accepted"]).is_true()
	assert_that(result["view_state"]["current_actor_id"]).is_equal("player")
	assert_that(result["view_state"]["round_number"]).is_equal(2)
	assert_that(result["view_state"]["phase"]).is_equal("player_action")
	assert_that(_event_count(result["events"], "reaction_resolved")).is_equal(1)
	assert_that(result["view_state"]["opponent"]["discard_pile_count"]).is_equal(2)
	assert_that(result["view_state"]["opponent"]["draw_pile_count"]).is_equal(11)
	assert_that(result["view_state"]["player"]["draw_pile_count"]).is_equal(11)
	assert_that(result["view_state"]["player"]["energy"]).is_equal(7)
	assert_that(session.state.validate_invariants(session.catalog)).is_empty()


func test_ai_skips_when_no_legal_action_and_still_advances_turn_once() -> void:
	var session := BattleSession.create_fixture()
	session.state.sides["opponent"]["energy"] = 0
	var result := session.end_turn("player")
	assert_that(result["accepted"]).is_true()
	assert_that(result["view_state"]["current_actor_id"]).is_equal("player")
	assert_that(result["view_state"]["round_number"]).is_equal(2)
	assert_that(_event_count(result["events"], "opponent_skipped")).is_equal(1)
	assert_that(_event_count(result["events"], "turn_ended")).is_equal(2)
	assert_that(session.state.validate_invariants(session.catalog)).is_empty()


func test_empty_hand_terminal_state_freezes_commands_until_restart() -> void:
	var session := BattleSession.create_fixture()
	for instance_id in session.state.sides["player"]["hand"].duplicate():
		var instance: CardInstance = session.state.card_instances[String(instance_id)]
		instance.zone = "discard_pile"
		session.state.sides["player"]["discard_pile"].append(instance.instance_id)
	session.state.sides["player"]["hand"].clear()
	OutcomeEvaluator.refresh(session.state)
	assert_that(session.state.outcome).is_equal("player_lost")
	var before := session.get_view_state()
	var result := session.end_turn("player")
	assert_that(result["accepted"]).is_false()
	assert_that(session.get_view_state()).is_equal(before)
	var restarted := session.restart()
	assert_that(restarted["accepted"]).is_true()
	assert_that(restarted["view_state"]["outcome"]).is_equal("ongoing")
	assert_that(restarted["view_state"]["player"]["hand_count"]).is_equal(10)
	assert_that(restarted["view_state"]["round_number"]).is_equal(1)


func test_player_turn_auto_ends_when_successful_action_leaves_no_legal_move() -> void:
	var session := BattleSession.create_fixture()
	_keep_only_player_cards(session, ["n", "cl"])
	session.state.sides["player"]["energy"] = 1
	var n_id := _hand_instance_id(session, "player", "n")
	var result := session.play_card("player", n_id, "player")
	assert_that(result["accepted"]).is_true()
	assert_that(result["view_state"]["current_actor_id"]).is_equal("player")
	assert_that(result["view_state"]["round_number"]).is_equal(2)
	assert_that(result["view_state"]["player"]["hand_count"]).is_equal(2)
	assert_that(_event_count(result["events"], "turn_ended")).is_equal(2)


func test_unsupported_staged_reaction_remains_editable_without_legal_moves() -> void:
	var session := BattleSession.create_fixture()
	_keep_only_player_cards(session, ["c", "cl"])
	session.state.sides["player"]["energy"] = 0
	var c_id := _hand_instance_id(session, "player", "c")
	var cl_id := _hand_instance_id(session, "player", "cl")
	var first_assignment := session.assign_reaction_card("player", c_id, 0)
	assert_that(first_assignment["accepted"]).is_true()
	assert_that(first_assignment["view_state"]["current_actor_id"]).is_equal("player")
	var second_assignment := session.assign_reaction_card("player", cl_id, 1)
	assert_that(second_assignment["accepted"]).is_true()
	assert_that(second_assignment["view_state"]["current_actor_id"]).is_equal("player")
	assert_that(session.preview_reaction("player")["reason_code"]).is_equal("unsupported_recipe")
	var before_resolve := session.get_view_state()
	var failed_resolve := session.resolve_reaction("player", "")
	assert_that(failed_resolve["accepted"]).is_false()
	assert_that(session.get_view_state()).is_equal(before_resolve)
	var cleared := session.clear_reaction("player")
	assert_that(cleared["accepted"]).is_true()
	assert_that(cleared["view_state"]["current_actor_id"]).is_equal("player")
	assert_that(cleared["view_state"]["player"]["hand_count"]).is_equal(2)
	assert_that(session.state.validate_invariants(session.catalog)).is_empty()


func test_unaffordable_staged_reaction_keeps_both_slots_and_can_be_cleared() -> void:
	var session := BattleSession.create_fixture()
	_keep_only_player_cards(session, ["c", "o"])
	session.state.sides["player"]["energy"] = 0
	var c_id := _hand_instance_id(session, "player", "c")
	var o_id := _hand_instance_id(session, "player", "o")
	assert_that(session.assign_reaction_card("player", c_id, 0)["accepted"]).is_true()
	assert_that(session.assign_reaction_card("player", o_id, 1)["accepted"]).is_true()
	assert_that(session.preview_reaction("player")["valid"]).is_true()
	var before_resolve := session.get_view_state()
	var failed_resolve := session.resolve_reaction("player", "co")
	assert_that(failed_resolve["accepted"]).is_false()
	assert_that(failed_resolve["reason_code"]).is_equal("insufficient_energy")
	assert_that(session.get_view_state()).is_equal(before_resolve)
	var cleared := session.clear_reaction("player")
	assert_that(cleared["accepted"]).is_true()
	assert_that(cleared["view_state"]["player"]["hand_count"]).is_equal(2)
	assert_that(session.state.validate_invariants(session.catalog)).is_empty()


func test_restart_reuses_seed_and_recreates_fresh_instance_ids() -> void:
	var session := BattleSession.create_fixture(23)
	var initial_player_ids := _instance_ids(session.get_view_state()["player"]["hand"])
	var n_id := _hand_instance_id(session, "player", "n")
	session.play_card("player", n_id, "player")
	var result := session.restart()
	assert_that(result["accepted"]).is_true()
	assert_that(_instance_ids(result["view_state"]["player"]["hand"])).is_equal(initial_player_ids)
	assert_that(_draw_ids(session)).is_equal(_draw_ids(BattleSession.create_fixture(23)))
	assert_that(result["view_state"]["player"]["energy"]).is_equal(8)
	assert_that(result["view_state"]["player"]["discard_pile_count"]).is_equal(0)


func test_view_projection_contains_expected_card_and_effect_contract() -> void:
	var view := BattleSession.create_fixture().get_view_state()
	var card: Dictionary = view["player"]["hand"][0]["card"]
	for expected_key in ["id", "display_name", "formula", "element_symbol", "category", "energy_cost", "base_damage", "rules_text", "target_kind", "is_element_card", "effects", "art_path", "migration_status"]:
		assert_that(card.has(expected_key)).is_true()
	assert_that(view["player"]["effects"].has("next_reaction_discount")).is_true()
	assert_that(view["player"]["reaction_slots"]).is_equal([null, null])
	assert_that(view.has("log_events")).is_true()


func _definition_ids(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		result.append(String(card["definition_id"]))
	return result


func _instance_ids(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		result.append(String(card["instance_id"]))
	return result


func _draw_cards(session: BattleSession) -> Array:
	var result: Array = []
	for owner_id in ["player", "opponent"]:
		for instance_id in session.state.sides[owner_id]["draw_pile"]:
			result.append(session.state.card_instances[String(instance_id)])
	return result


func _draw_ids(session: BattleSession) -> Array[String]:
	var result: Array[String] = []
	for owner_id in ["player", "opponent"]:
		for instance_id in session.state.sides[owner_id]["draw_pile"]:
			result.append(String(session.state.card_instances[String(instance_id)].definition_id))
	return result


func _hand_instance_id(session: BattleSession, owner_id: String, definition_id: String) -> String:
	for instance_id in session.state.sides[owner_id]["hand"]:
		var instance: CardInstance = session.state.card_instances[String(instance_id)]
		if instance.definition_id == definition_id:
			return instance.instance_id
	return ""


func _event_count(events: Array, event_type: String) -> int:
	var count := 0
	for event in events:
		if String(event.get("type", "")) == event_type:
			count += 1
	return count


func _keep_only_player_cards(session: BattleSession, definition_ids: Array[String]) -> void:
	var side: Dictionary = session.state.sides["player"]
	var selected: Array[String] = []
	for definition_id in definition_ids:
		var found := ""
		for instance_id in side["hand"]:
			var instance: CardInstance = session.state.card_instances[String(instance_id)]
			if instance.definition_id == definition_id and not selected.has(instance.instance_id):
				found = instance.instance_id
				break
		selected.append(found)
	var hand: Array = []
	for instance_id in side["hand"]:
		var instance: CardInstance = session.state.card_instances[String(instance_id)]
		if selected.has(instance.instance_id):
			hand.append(instance_id)
		else:
			instance.zone = "discard_pile"
			side["discard_pile"].append(instance_id)
	for instance_id in side["draw_pile"].duplicate():
		var instance: CardInstance = session.state.card_instances[String(instance_id)]
		if selected.has(instance.instance_id):
			side["draw_pile"].erase(instance_id)
			instance.zone = "hand"
			instance.hand_order = int(side["next_hand_order"])
			side["next_hand_order"] = instance.hand_order + 1
			hand.append(instance_id)
	side["hand"] = hand
