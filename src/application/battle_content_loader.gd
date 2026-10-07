extends RefCounted
class_name BattleContentLoader

const CARD_DATA_PATH := "res://godot_assets/data/cards"
const REACTION_DATA_PATH := "res://godot_assets/data/reactions"


static func load_fixture_catalog() -> Dictionary:
	var card_definitions: Array[CardDefinition] = []
	var reaction_definitions: Array[ReactionRecipe] = []
	var errors: Array[String] = []
	var card_files := _resource_files(CARD_DATA_PATH)
	var reaction_files := _resource_files(REACTION_DATA_PATH)
	if card_files.is_empty():
		errors.append("No card resources found at %s." % CARD_DATA_PATH)
	if reaction_files.is_empty():
		errors.append("No reaction resources found at %s." % REACTION_DATA_PATH)
	for file_name in card_files:
		var path := "%s/%s" % [CARD_DATA_PATH, file_name]
		var definition := ResourceLoader.load(path) as CardDefinition
		if definition == null:
			errors.append("Failed to load CardDefinition resource: %s" % path)
		else:
			card_definitions.append(definition)
	for file_name in reaction_files:
		var path := "%s/%s" % [REACTION_DATA_PATH, file_name]
		var recipe := ResourceLoader.load(path) as ReactionRecipe
		if recipe == null:
			errors.append("Failed to load ReactionRecipe resource: %s" % path)
		else:
			reaction_definitions.append(recipe)
	var catalog := BattleContentCatalog.new(card_definitions, reaction_definitions)
	var report := catalog.validate_all()
	for error in report["errors"]:
		errors.append(String(error))
	return {
		"valid": errors.is_empty(),
		"catalog": catalog,
		"errors": errors,
	}


static func _resource_files(directory_path: String) -> Array[String]:
	var files: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return files
	for file_name in directory.get_files():
		if file_name.to_lower().ends_with(".tres"):
			files.append(file_name)
	files.sort()
	return files
