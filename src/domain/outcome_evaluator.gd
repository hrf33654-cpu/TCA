extends RefCounted
class_name OutcomeEvaluator

## Fixture policy: either zero HP or an empty current hand means that side has
## lost. Both sides failing after one atomic action produce a draw.

static func evaluate(state: BattleState) -> String:
	var player_failed := _side_failed(state.sides.get(BattleState.PLAYER_ID, {}))
	var opponent_failed := _side_failed(state.sides.get(BattleState.OPPONENT_ID, {}))
	if player_failed and opponent_failed:
		return "draw"
	if opponent_failed:
		return "player_won"
	if player_failed:
		return "player_lost"
	return "ongoing"


static func refresh(state: BattleState) -> void:
	if state.outcome == "ongoing":
		state.outcome = evaluate(state)
		if state.outcome != "ongoing":
			state.phase = BattleState.PHASE_TERMINAL
			state.append_event("battle_ended", {"outcome": state.outcome})


static func _side_failed(side: Dictionary) -> bool:
	return int(side.get("hp", 0)) <= 0 or side.get("hand", []).is_empty()
