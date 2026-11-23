extends GutTest

var catalog: PlaceCatalog


func before_all() -> void:
	catalog = PlaceCatalog.load_dir()


func test_the_three_mvp_secrets_ship() -> void:
	assert_eq(catalog.ids_of_kind("secret"),
		PackedStringArray(["secret_mandi", "secret_rondon_jiparana", "secret_teotonio"]))


func test_every_place_is_bilingual_and_sourced() -> void:
	for id in catalog.places:
		for locale in ["en", "pt_BR"]:
			assert_false(catalog.places[id].name.get(locale, "").is_empty(), "%s name %s" % [id, locale])
			assert_false(catalog.places[id].text.get(locale, "").is_empty(), "%s text %s" % [id, locale])
		assert_false(catalog.sources_of(id).is_empty(), "%s has sources (ADR 0006)" % id)


func test_localized_text_falls_back_to_english_then_id() -> void:
	var c := PlaceCatalog.new()
	c.places = {"x": {"id": "x", "name": {"en": "Only English"}}}
	assert_eq(c.name_of("x", "pt_BR"), "Only English")
	assert_eq(c.text_of("x", "pt_BR"), "x")
	assert_eq(c.name_of("missing", "en"), "missing")


func test_spot_for_merges_rules_and_position() -> void:
	var s := catalog.spot_for("secret_teotonio", Vector2(1, 2), 63.0)
	assert_eq(s.pos, Vector2(1, 2))
	assert_eq(s.view_from_deg, 63.0)
	assert_gt(s.max_distance, s.radius)


func test_every_secret_is_on_the_state_map() -> void:
	var ids := StateMapData.load_file().spots.map(func(s): return s.id)
	for id in catalog.ids_of_kind("secret"):
		assert_has(ids, id, "rebuild the map after adding a place: python3 tools/geo/build_map.py")
