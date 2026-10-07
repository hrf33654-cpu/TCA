extends GdUnitTestSuite


func test_fixture_catalog_loads_valid_migration_data() -> void:
	var result := BattleContentLoader.load_fixture_catalog()
	assert_that(result["valid"]).is_true()
	assert_that(result["errors"]).is_empty()
	var catalog: BattleContentCatalog = result["catalog"]
	assert_that(catalog.get_card_ids().size()).is_equal(16)
	assert_that(catalog.get_recipe("c", "o").product_ids.size()).is_equal(2)
	assert_that(catalog.get_recipe("o", "c").id).is_equal(&"c_o")
	assert_that(catalog.get_recipe("c", "c").product_ids[0]).is_equal(&"c")
	assert_that(catalog.validate_all()["valid"]).is_true()


func test_fixture_marks_unapproved_output_and_science_status_explicitly() -> void:
	var catalog := _catalog()
	assert_that(catalog.get_card("co2").migration_status).is_equal(&"migration_temp")
	assert_that(catalog.get_card("n").migration_status).is_equal(&"migration_temp")
	assert_that(catalog.get_recipe("n", "o").scientific_review_status).is_equal(&"unreviewed")
	assert_that(catalog.get_card("ar").is_element_card).is_false()
	assert_that(catalog.get_card("b").is_element_card).is_false()
	assert_that(catalog.get_card("s").is_element_card).is_false()


func test_catalog_rejects_duplicate_definition_ids() -> void:
	var first := CardDefinition.new()
	first.id = &"x"
	var duplicate := CardDefinition.new()
	duplicate.id = &"X"
	var catalog := BattleContentCatalog.new([first, duplicate], [])
	var report := catalog.validate_all()
	assert_that(report["valid"]).is_false()
	assert_that("Duplicate card definition ID: x" in report["errors"]).is_true()


func test_catalog_rejects_unknown_effect_and_orphan_recipe_product() -> void:
	var invalid_card := CardDefinition.new()
	invalid_card.id = &"invalid"
	invalid_card.display_name = "Invalid"
	invalid_card.category = &"buff"
	invalid_card.target_kind = &"self"
	invalid_card.rules_text = "Unknown effect"
	invalid_card.effects = [{"type": &"execute_script", "amount": 1}]
	var c := _catalog().get_card("c")
	var orphan_recipe := ReactionRecipe.new()
	orphan_recipe.id = &"orphan"
	orphan_recipe.input_card_ids = [&"c", &"c"]
	orphan_recipe.product_ids = [&"missing"]
	var catalog := BattleContentCatalog.new([c, invalid_card], [orphan_recipe])
	var report := catalog.validate_all()
	assert_that(report["valid"]).is_false()
	assert_that(_errors_contain(report["errors"], "Unsupported effect 'execute_script' on card invalid")).is_true()
	assert_that(_errors_contain(report["errors"], "references missing product missing")).is_true()


func test_catalog_rejects_reaction_using_non_element_input() -> void:
	var recipe := ReactionRecipe.new()
	recipe.id = &"bad_input"
	recipe.input_card_ids = [&"c", &"b"]
	recipe.product_ids = [&"co"]
	var catalog := BattleContentCatalog.new(_all_cards(), [recipe])
	var report := catalog.validate_all()
	assert_that(report["valid"]).is_false()
	assert_that(_errors_contain(report["errors"], "input is not an element card: b")).is_true()


func _catalog() -> BattleContentCatalog:
	return BattleContentLoader.load_fixture_catalog()["catalog"] as BattleContentCatalog


func _all_cards() -> Array[CardDefinition]:
	var cards: Array[CardDefinition] = []
	var catalog := _catalog()
	for card_id in catalog.get_card_ids():
		cards.append(catalog.get_card(card_id))
	return cards


func _errors_contain(errors: Array, fragment: String) -> bool:
	for error in errors:
		if String(error).contains(fragment):
			return true
	return false
