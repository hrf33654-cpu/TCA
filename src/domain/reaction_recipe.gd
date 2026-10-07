extends Resource
class_name ReactionRecipe

## Static content describing an unordered pair of element-card definitions.

@export var id: StringName = &""
@export var input_card_ids: Array[StringName] = []
@export var product_ids: Array[StringName] = []
@export var migration_status: StringName = &"migration_temp"
@export var scientific_review_status: StringName = &"unreviewed"


func normalized_key() -> String:
	if input_card_ids.size() != 2:
		return ""
	var ids := [String(input_card_ids[0]).to_lower(), String(input_card_ids[1]).to_lower()]
	ids.sort()
	return "%s+%s" % [ids[0], ids[1]]
