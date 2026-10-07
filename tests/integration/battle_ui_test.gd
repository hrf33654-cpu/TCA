extends GdUnitTestSuite


func test_battle_scene_projects_fixture_state_and_all_ten_cards() -> void:
	var runner := scene_runner("res://scenes/battle/battle_scene.tscn")
	await runner.simulate_frames(2)
	var controller := runner.scene() as BattleController
	assert_that(controller).is_not_null()
	assert_that(controller.session.is_ready()).is_true()
	assert_that(controller.view_state["player"]["hand_count"]).is_equal(10)
	assert_that(controller.view_state["opponent"]["hp"]).is_equal(30)
	assert_that(controller.card_widgets.size()).is_equal(10)
	assert_that(controller._hand_count_label.text).is_equal("10 张")
	for record in controller.view_state["player"]["hand"]:
		var widget := controller.card_widgets[String(record["instance_id"])] as CardWidget
		assert_that(widget).is_not_null()
		assert_that(widget.card_data.has("category")).is_true()
		assert_that(widget._name_label.text).is_equal(String(record["card"]["display_name"]))
		assert_that(widget.text.contains("Damage")).is_false()


func test_select_and_play_self_card_updates_hud_effect_and_history() -> void:
	var runner := scene_runner("res://scenes/battle/battle_scene.tscn")
	await runner.simulate_frames(2)
	var controller := runner.scene() as BattleController
	var n_id := _instance_id(controller, "n")
	controller.select_card(n_id)
	assert_that(controller._play_button.text).contains("对自己使用")
	controller._play_button.emit_signal("pressed")
	assert_that(controller.view_state["player"]["energy"]).is_equal(7)
	assert_that(controller.view_state["player"]["effects"]["next_incoming_damage_reduction"]).is_equal(1)
	assert_that(controller.view_state["player"]["hand_count"]).is_equal(9)
	assert_that(controller._recent_events_label.text).contains("我方使用氮 N")
	assert_that(controller.session.state.validate_invariants(controller.session.catalog)).is_empty()


func test_target_mapping_uses_battle_participant_ids() -> void:
	var runner := scene_runner("res://scenes/battle/battle_scene.tscn")
	await runner.simulate_frames(2)
	var controller := runner.scene() as BattleController
	assert_that(controller._selected_target_id({"target_kind": "self"})).is_equal("player")
	assert_that(controller._selected_target_id({"target_kind": "opponent"})).is_equal("opponent")
	controller._target_selector.select(0)
	assert_that(controller._selected_target_id({"target_kind": "any"})).is_equal("opponent")
	controller._target_selector.select(1)
	assert_that(controller._selected_target_id({"target_kind": "any"})).is_equal("player")


func test_reaction_slots_offer_both_products_and_selected_choice_resolves() -> void:
	var runner := scene_runner("res://scenes/battle/battle_scene.tscn")
	await runner.simulate_frames(2)
	var controller := runner.scene() as BattleController
	var carbon_id := _instance_id(controller, "c")
	var oxygen_id := _instance_id(controller, "o")
	controller.assign_reaction_card(carbon_id, 0)
	controller.assign_reaction_card(oxygen_id, 1)
	assert_that(controller.session.preview_reaction("player")["candidate_product_ids"]).is_equal(["co", "co2"])
	assert_that(controller.product_buttons.has("co")).is_true()
	assert_that(controller.product_buttons.has("co2")).is_true()
	(controller.product_buttons["co2"] as Button).emit_signal("pressed")
	assert_that(controller.view_state["player"]["energy"]).is_equal(6)
	assert_that(controller.view_state["player"]["discard_pile_count"]).is_equal(2)
	assert_that(controller.view_state["player"]["reaction_slots"]).is_equal([null, null])
	assert_that(_hand_count(controller, "co2")).is_equal(1)
	assert_that(controller._recent_events_label.text).contains("二氧化碳 CO₂")
	assert_that(controller.session.state.validate_invariants(controller.session.catalog)).is_empty()


func test_unsupported_reaction_is_atomic_and_clear_returns_both_cards() -> void:
	var runner := scene_runner("res://scenes/battle/battle_scene.tscn")
	await runner.simulate_frames(2)
	var controller := runner.scene() as BattleController
	var carbon_id := _instance_id(controller, "c")
	var nitrogen_id := _instance_id(controller, "n")
	controller.assign_reaction_card(carbon_id, 0)
	controller.assign_reaction_card(nitrogen_id, 1)
	var before := controller.session.get_view_state()
	assert_that(controller.session.preview_reaction("player")["valid"]).is_false()
	controller._on_resolve_pressed()
	assert_that(controller.session.get_view_state()).is_equal(before)
	assert_that(controller._status_label.text).contains("当前没有可用配方")
	controller._on_clear_pressed()
	assert_that(controller.view_state["player"]["hand_count"]).is_equal(10)
	assert_that(controller.view_state["player"]["reaction_slots"]).is_equal([null, null])
	assert_that(controller.view_state["player"]["discard_pile_count"]).is_equal(0)
	assert_that(controller.session.state.validate_invariants(controller.session.catalog)).is_empty()


func test_end_turn_advances_ai_round_and_result_overlay_can_restart() -> void:
	var runner := scene_runner("res://scenes/battle/battle_scene.tscn")
	await runner.simulate_frames(2)
	var controller := runner.scene() as BattleController
	controller._end_turn_button.emit_signal("pressed")
	assert_that(controller.view_state["round_number"]).is_equal(2)
	assert_that(controller.view_state["current_actor_id"]).is_equal("player")
	assert_that(controller.view_state["phase"]).is_equal("player_action")
	controller.session.state.sides["opponent"]["hp"] = 0
	OutcomeEvaluator.refresh(controller.session.state)
	controller._refresh()
	assert_that(controller._result_overlay.visible).is_true()
	assert_that(controller._result_title.text).is_equal("胜利")
	controller._result_restart_button.emit_signal("pressed")
	assert_that(controller.view_state["outcome"]).is_equal("ongoing")
	assert_that(controller.view_state["round_number"]).is_equal(1)
	assert_that(controller._result_overlay.visible).is_false()


func _instance_id(controller: BattleController, definition_id: String) -> String:
	for record in controller.view_state.get("player", {}).get("hand", []):
		if String(record.get("definition_id", "")) == definition_id:
			return String(record.get("instance_id", ""))
	return ""


func _hand_count(controller: BattleController, definition_id: String) -> int:
	var count := 0
	for record in controller.view_state.get("player", {}).get("hand", []):
		if String(record.get("definition_id", "")) == definition_id:
			count += 1
	return count
