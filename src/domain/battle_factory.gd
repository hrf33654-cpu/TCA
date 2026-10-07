extends RefCounted
class_name BattleFactory

const FIXTURE_STARTING_HAND: Array[String] = ["c", "n", "o", "cl", "b", "s", "ar", "co", "no2", "h2o2"]
const FIXTURE_DRAW_POOL: Array[String] = ["c", "n", "o", "cl", "b", "f", "s", "ar", "co", "no2", "h2o2", "cl2"]
const PLAYER_SHUFFLE_SALT := 0x13579BDF
const OPPONENT_SHUFFLE_SALT := 0x2468ACE0


static func create_fixture(catalog: BattleContentCatalog, fixture_seed: int) -> BattleState:
	var state := BattleState.new()
	state.seed = fixture_seed
	state.sides = {
		BattleState.PLAYER_ID: _new_side_state(),
		BattleState.OPPONENT_ID: _new_side_state(),
	}
	state.reaction_slots = {
		BattleState.PLAYER_ID: [null, null],
		BattleState.OPPONENT_ID: [null, null],
	}
	for side_id in BattleState.SIDE_IDS:
		for definition_id in FIXTURE_STARTING_HAND:
			if not catalog.has_card(definition_id):
				return null
			var hand_instance := state.create_instance(definition_id, side_id, "hand")
			state.sides[side_id]["hand"].append(hand_instance.instance_id)
		var draw_ids := FIXTURE_DRAW_POOL.duplicate()
		var rng := RandomNumberGenerator.new()
		var side_salt := PLAYER_SHUFFLE_SALT if side_id == BattleState.PLAYER_ID else OPPONENT_SHUFFLE_SALT
		rng.seed = fixture_seed ^ side_salt
		_shuffle(draw_ids, rng)
		for definition_id in draw_ids:
			if not catalog.has_card(definition_id):
				return null
			var draw_instance := state.create_instance(definition_id, side_id, "draw_pile")
			state.sides[side_id]["draw_pile"].append(draw_instance.instance_id)
	return state


static func _new_side_state() -> Dictionary:
	return {
		"hp": 30,
		"energy": 8,
		"max_energy": 8,
		"turn_count": 0,
		"hand": [],
		"draw_pile": [],
		"discard_pile": [],
		"next_hand_order": 0,
		"effects": {
			"next_reaction_discount": 0,
			"next_incoming_damage_reduction": 0,
			"draw_after_next_reaction": false,
			"next_damage_bonus": 0,
			"fixture_first_damage_used_this_turn": false,
			"fixture_first_reaction_used_this_turn": false,
		},
	}


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
