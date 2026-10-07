extends RefCounted
class_name BattleState

const PLAYER_ID := "player"
const OPPONENT_ID := "opponent"
const SIDE_IDS := [PLAYER_ID, OPPONENT_ID]
const PHASE_SETUP := "setup"
const PHASE_TURN_TRANSITION := "turn_transition"
const PHASE_TERMINAL := "terminal"

var seed: int = 0
var round_number: int = 1
var current_actor_id: String = PLAYER_ID
var phase: String = PHASE_SETUP
var outcome: String = "ongoing"
var next_instance_serial: int = 1
var fixture_rules: Dictionary = {
	"enabled": true,
	"first_damage_bonus": 1,
	"first_reaction_draw": 1,
}
var sides: Dictionary = {}
var card_instances: Dictionary = {}
var reaction_slots: Dictionary = {}
var event_log: Array[Dictionary] = []


func duplicate_state() -> BattleState:
	var result := BattleState.new()
	result.seed = seed
	result.round_number = round_number
	result.current_actor_id = current_actor_id
	result.phase = phase
	result.outcome = outcome
	result.next_instance_serial = next_instance_serial
	result.fixture_rules = fixture_rules.duplicate(true)
	result.sides = {}
	for side_id in SIDE_IDS:
		var side: Dictionary = sides.get(side_id, {})
		var side_copy: Dictionary = side.duplicate(true)
		for zone_name in ["hand", "draw_pile", "discard_pile"]:
			side_copy[zone_name] = side.get(zone_name, []).duplicate()
		result.sides[side_id] = side_copy
	result.card_instances = {}
	for instance_id in card_instances:
		var card_instance: CardInstance = card_instances[instance_id]
		result.card_instances[instance_id] = card_instance.duplicate_instance()
	result.reaction_slots = {PLAYER_ID: [], OPPONENT_ID: []}
	for side_id in SIDE_IDS:
		var slots: Array = reaction_slots.get(side_id, [null, null])
		var slot_copy: Array = []
		for slot in slots:
			slot_copy.append(slot.duplicate(true) if slot is Dictionary else null)
		result.reaction_slots[side_id] = slot_copy
	result.event_log = []
	for event in event_log:
		result.event_log.append(event.duplicate(true))
	return result


func create_instance(definition_id: String, owner_id: String, zone: String) -> CardInstance:
	var prefix := "p" if owner_id == PLAYER_ID else "o"
	var instance_id := "%s-%06d" % [prefix, next_instance_serial]
	next_instance_serial += 1
	var hand_order := -1
	if zone == "hand" and sides.has(owner_id):
		hand_order = int(sides[owner_id].get("next_hand_order", 0))
		sides[owner_id]["next_hand_order"] = hand_order + 1
	var instance := CardInstance.new(instance_id, definition_id, owner_id, zone, hand_order)
	card_instances[instance_id] = instance
	return instance


func append_event(event_type: String, data: Dictionary = {}) -> Dictionary:
	var event := {"type": event_type, "round_number": round_number}
	for key in data:
		event[key] = data[key]
	event_log.append(event)
	return event


func validate_invariants(catalog: BattleContentCatalog) -> Array[String]:
	var errors: Array[String] = []
	if round_number < 1:
		errors.append("Round number must be positive.")
	if outcome not in ["ongoing", "player_won", "player_lost", "draw"]:
		errors.append("Unknown battle outcome: %s" % outcome)
	if outcome == "ongoing":
		if phase not in [PHASE_SETUP, PHASE_TURN_TRANSITION, "%s_action" % PLAYER_ID, "%s_action" % OPPONENT_ID]:
			errors.append("Unknown active battle phase: %s" % phase)
		if phase == "%s_action" % PLAYER_ID and current_actor_id != PLAYER_ID:
			errors.append("Player action phase has a different current actor.")
		if phase == "%s_action" % OPPONENT_ID and current_actor_id != OPPONENT_ID:
			errors.append("Opponent action phase has a different current actor.")
	else:
		if phase != PHASE_TERMINAL:
			errors.append("A completed battle must be in terminal phase.")
	var occurrences: Dictionary = {}
	for side_id in SIDE_IDS:
		if not sides.has(side_id):
			errors.append("Missing side state: %s" % side_id)
			continue
		var side: Dictionary = sides[side_id]
		var slots: Array = reaction_slots.get(side_id, [])
		if slots.size() != 2:
			errors.append("Each side must have exactly two reaction slots: %s" % side_id)
			continue
		var hp := int(side.get("hp", -1))
		var energy := int(side.get("energy", -1))
		var max_energy := int(side.get("max_energy", -1))
		if hp < 0:
			errors.append("HP must not be negative for %s" % side_id)
		if max_energy < 0 or energy < 0 or energy > max_energy:
			errors.append("Energy is out of range for %s" % side_id)
		for zone_name in ["hand", "draw_pile", "discard_pile"]:
			for instance_id in side.get(zone_name, []):
				_register_occurrence(errors, occurrences, side_id, String(instance_id), zone_name)
		for slot in slots:
			if slot is Dictionary:
				_register_occurrence(errors, occurrences, side_id, String(slot.get("instance_id", "")), "reaction")
	for instance_id in card_instances:
		var instance: CardInstance = card_instances[instance_id]
		if instance.instance_id != String(instance_id):
			errors.append("Card instance map key differs from instance ID: %s" % instance_id)
		if instance.owner_id not in SIDE_IDS:
			errors.append("Card instance has an unknown owner: %s" % instance_id)
		if instance.zone not in ["hand", "draw_pile", "discard_pile", "reaction"]:
			errors.append("Card instance has an unknown zone: %s" % instance_id)
		if not catalog.has_card(instance.definition_id):
			errors.append("Card instance references missing definition: %s" % instance.definition_id)
		if not occurrences.has(instance_id):
			errors.append("Card instance is not in any zone: %s" % instance_id)
			continue
		if occurrences[instance_id].size() != 1:
			errors.append("Card instance occurs in multiple zones: %s" % instance_id)
		var occurrence: Dictionary = occurrences[instance_id][0]
		if occurrence.owner_id != instance.owner_id or occurrence.zone != instance.zone:
			errors.append("Card instance ownership/zone mismatch: %s" % instance_id)
	for instance_id in occurrences:
		if not card_instances.has(instance_id):
			errors.append("Zone references missing card instance: %s" % instance_id)
	return errors


func to_view_state(catalog: BattleContentCatalog) -> Dictionary:
	var player_view := _side_to_view(PLAYER_ID, catalog)
	var opponent_view := _side_to_view(OPPONENT_ID, catalog)
	return {
		"round_number": round_number,
		"current_actor_id": current_actor_id,
		"phase": phase,
		"outcome": outcome,
		"player": player_view,
		"opponent": opponent_view,
		"log_events": _copy_events(event_log),
	}


func _side_to_view(side_id: String, catalog: BattleContentCatalog) -> Dictionary:
	var side: Dictionary = sides.get(side_id, {})
	var hand_view: Array[Dictionary] = []
	for instance_id in side.get("hand", []):
		hand_view.append(_instance_to_view(String(instance_id), catalog))
	var slots_view: Array = []
	for slot in reaction_slots.get(side_id, [null, null]):
		if slot is Dictionary:
			slots_view.append(_instance_to_view(String(slot.get("instance_id", "")), catalog))
		else:
			slots_view.append(null)
	return {
		"side_id": side_id,
		"hp": int(side.get("hp", 0)),
		"energy": int(side.get("energy", 0)),
		"max_energy": int(side.get("max_energy", 0)),
		"hand_count": hand_view.size(),
		"draw_pile_count": side.get("draw_pile", []).size(),
		"discard_pile_count": side.get("discard_pile", []).size(),
		"hand": hand_view,
		"reaction_slots": slots_view,
		"effects": side.get("effects", {}).duplicate(true),
	}


func _instance_to_view(instance_id: String, catalog: BattleContentCatalog) -> Dictionary:
	var instance: CardInstance = card_instances.get(instance_id)
	if instance == null:
		return {}
	var definition := catalog.get_card(instance.definition_id)
	return instance.to_record(definition)


func _register_occurrence(
		errors: Array[String],
		occurrences: Dictionary,
		side_id: String,
		instance_id: String,
		zone_name: String) -> void:
	if not occurrences.has(instance_id):
		occurrences[instance_id] = []
	occurrences[instance_id].append({"owner_id": side_id, "zone": zone_name})


func _copy_events(events: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		result.append(event.duplicate(true))
	return result
