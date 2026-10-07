extends RefCounted
class_name CardInstance

## A physical card. Its ID is unique for the lifetime of a battle, even when
## another card references the same CardDefinition.

var instance_id: String = ""
var definition_id: String = ""
var owner_id: String = ""
var zone: String = ""
var hand_order: int = -1


func _init(
		p_instance_id: String = "",
		p_definition_id: String = "",
		p_owner_id: String = "",
		p_zone: String = "",
		p_hand_order: int = -1) -> void:
	instance_id = p_instance_id
	definition_id = p_definition_id
	owner_id = p_owner_id
	zone = p_zone
	hand_order = p_hand_order


func duplicate_instance() -> CardInstance:
	return CardInstance.new(instance_id, definition_id, owner_id, zone, hand_order)


func to_record(definition: CardDefinition) -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": definition_id,
		"owner_id": owner_id,
		"zone": zone,
		"card": definition.to_view_data() if definition != null else {},
	}
