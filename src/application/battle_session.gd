extends RefCounted
class_name BattleSession

const DEFAULT_SEED := 0x54434101

var seed: int = DEFAULT_SEED
var catalog: BattleContentCatalog
var rules: BattleRules
var opponent_policy: OpponentPolicy
var state: BattleState
var initialization_error: String = ""
var _catalog_is_valid: bool = false


static func create_fixture(fixture_seed: int = DEFAULT_SEED) -> BattleSession:
	var session := BattleSession.new()
	session.seed = fixture_seed
	session._initialize_fixture()
	return session


func restart() -> Dictionary:
	if catalog == null or not _catalog_is_valid:
		return _public_result(false, false, "catalog_unavailable", initialization_error, [], get_view_state())
	_initialize_fixture()
	if state == null:
		return _public_result(false, false, "battle_initialization_failed", initialization_error, [], get_view_state())
	var events: Array[Dictionary] = []
	_append_application_event("battle_restarted", {"seed": seed}, events)
	return _public_result(true, true, "", "", events, get_view_state())


func is_ready() -> bool:
	return state != null and catalog != null and initialization_error.is_empty()


func get_view_state() -> Dictionary:
	if state == null or catalog == null:
		return {
			"is_ready": false,
			"initialization_error": initialization_error,
			"round_number": 0,
			"current_actor_id": "",
			"phase": "unavailable",
			"outcome": "ongoing",
			"player": {},
			"opponent": {},
			"log_events": [],
		}
	var view := state.to_view_state(catalog)
	view["is_ready"] = is_ready()
	view["initialization_error"] = initialization_error
	return view


func play_card(actor_id: String, card_instance_id: String, target_id: String) -> Dictionary:
	if not is_ready():
		return _unavailable_result()
	if actor_id != BattleState.PLAYER_ID:
		return _not_player_command_result()
	return _submit_player_action(rules.play_card(state, actor_id, card_instance_id, target_id), true)


func assign_reaction_card(actor_id: String, card_instance_id: String, slot_index: int) -> Dictionary:
	if not is_ready():
		return _unavailable_result()
	if actor_id != BattleState.PLAYER_ID:
		return _not_player_command_result()
	return _submit_player_action(rules.assign_reaction_card(state, actor_id, card_instance_id, slot_index))


func preview_reaction(actor_id: String) -> Dictionary:
	if not is_ready():
		return {
			"valid": false,
			"reason_code": "catalog_unavailable",
			"message": initialization_error,
			"candidate_product_ids": [],
			"cost": 0,
			"discount": 0,
		}
	return rules.preview_reaction(state, actor_id)


func resolve_reaction(actor_id: String, product_id: String) -> Dictionary:
	if not is_ready():
		return _unavailable_result()
	if actor_id != BattleState.PLAYER_ID:
		return _not_player_command_result()
	return _submit_player_action(rules.resolve_reaction(state, actor_id, product_id), true)


func clear_reaction(actor_id: String) -> Dictionary:
	if not is_ready():
		return _unavailable_result()
	if actor_id != BattleState.PLAYER_ID:
		return _not_player_command_result()
	return _submit_player_action(rules.clear_reaction(state, actor_id))


func end_turn(actor_id: String) -> Dictionary:
	if not is_ready():
		return _unavailable_result()
	if actor_id != BattleState.PLAYER_ID:
		return _public_result(false, false, "player_command_only", "Only the player can submit an end-turn command.", [], get_view_state())
	if state.outcome != "ongoing" or state.current_actor_id != actor_id or state.phase != "player_action":
		return _public_result(false, false, "not_current_actor", "It is not the player's action phase.", [], get_view_state())
	var events: Array[Dictionary] = []
	_advance_after_player_turn(events)
	return _public_result(true, true, "", "", events, get_view_state())


func _initialize_fixture() -> void:
	initialization_error = ""
	if catalog == null:
		var load_result := BattleContentLoader.load_fixture_catalog()
		catalog = load_result["catalog"] as BattleContentCatalog
		_catalog_is_valid = bool(load_result["valid"])
		if not bool(load_result["valid"]):
			initialization_error = "; ".join(load_result["errors"])
	if not _catalog_is_valid or catalog == null:
		rules = null
		opponent_policy = null
		state = null
		return
	rules = BattleRules.new(catalog)
	opponent_policy = OpponentPolicy.new(rules)
	state = BattleFactory.create_fixture(catalog, seed)
	if state == null:
		initialization_error = "Fixture catalog is missing one or more required card definitions."
		return
	var begin_result := rules.begin_turn(state, BattleState.PLAYER_ID)
	if not bool(begin_result["accepted"]):
		initialization_error = String(begin_result.get("message", "Failed to begin player turn."))
		state = null
		return
	state = begin_result["state"] as BattleState


func _submit_player_action(rule_result: Dictionary, auto_end_if_no_legal_move: bool = false) -> Dictionary:
	if not bool(rule_result.get("accepted", false)):
		return _public_result(
			false,
			false,
			String(rule_result.get("reason_code", "rule_rejected")),
			String(rule_result.get("message", "Action was rejected.")),
			[],
			get_view_state())
	state = rule_result["state"] as BattleState
	var events: Array[Dictionary] = _copy_events(rule_result.get("events", []))
	if auto_end_if_no_legal_move and state.outcome == "ongoing" and state.current_actor_id == BattleState.PLAYER_ID and not rules.has_legal_action(state, BattleState.PLAYER_ID):
		_advance_after_player_turn(events)
	return _public_result(true, true, "", "", events, get_view_state())


func _advance_after_player_turn(events: Array[Dictionary]) -> void:
	var finish_player := rules.finish_turn(state, BattleState.PLAYER_ID)
	if not bool(finish_player["accepted"]):
		return
	state = finish_player["state"] as BattleState
	_append_result_events(finish_player, events)
	var begin_opponent := rules.begin_turn(state, BattleState.OPPONENT_ID)
	if not bool(begin_opponent["accepted"]):
		return
	state = begin_opponent["state"] as BattleState
	_append_result_events(begin_opponent, events)
	var ai_action := opponent_policy.choose_action(state)
	var action_result: Dictionary = {}
	match String(ai_action.get("type", "none")):
		"reaction":
			var instance_ids: Array = ai_action.get("instance_ids", [])
			if instance_ids.size() == 2:
				action_result = rules.resolve_reaction_from_hand_pair(
					state,
					BattleState.OPPONENT_ID,
					String(instance_ids[0]),
					String(instance_ids[1]),
					String(ai_action.get("product_id", "")))
		"play_card":
			action_result = rules.play_card(
				state,
				BattleState.OPPONENT_ID,
				String(ai_action.get("instance_id", "")),
				String(ai_action.get("target_id", BattleState.PLAYER_ID)))
	if action_result.is_empty() or not bool(action_result.get("accepted", false)):
		_append_application_event("opponent_skipped", {"reason_code": ai_action.get("reason_code", "action_unavailable")}, events)
	else:
		state = action_result["state"] as BattleState
		_append_result_events(action_result, events)
	if state.outcome != "ongoing":
		return
	var finish_opponent := rules.finish_turn(state, BattleState.OPPONENT_ID)
	if not bool(finish_opponent["accepted"]):
		return
	state = finish_opponent["state"] as BattleState
	_append_result_events(finish_opponent, events)
	var begin_player := rules.begin_turn(state, BattleState.PLAYER_ID)
	if not bool(begin_player["accepted"]):
		return
	state = begin_player["state"] as BattleState
	_append_result_events(begin_player, events)


func _append_application_event(event_type: String, data: Dictionary, collected_events: Array[Dictionary]) -> void:
	var event := state.append_event(event_type, data).duplicate(true)
	collected_events.append(event)


func _append_result_events(result: Dictionary, collected_events: Array[Dictionary]) -> void:
	for event in result.get("events", []):
		collected_events.append(event.duplicate(true))


func _copy_events(events: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		if event is Dictionary:
			result.append(event.duplicate(true))
	return result


func _public_result(
		accepted: bool,
		state_changed: bool,
		reason_code: String,
		message: String,
		events: Array[Dictionary],
		view_state: Dictionary) -> Dictionary:
	return {
		"accepted": accepted,
		"state_changed": state_changed,
		"reason_code": reason_code,
		"message": message,
		"events": _copy_events(events),
		"view_state": view_state.duplicate(true),
	}


func _unavailable_result() -> Dictionary:
	return _public_result(false, false, "battle_unavailable", initialization_error, [], get_view_state())


func _not_player_command_result() -> Dictionary:
	return _public_result(false, false, "player_command_only", "Only the player can submit this command.", [], get_view_state())
