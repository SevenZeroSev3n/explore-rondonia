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


func test_every_photo_is_packed_and_credited() -> void:
	for id in catalog.places:
		for photo in catalog.photos_of(id):
			assert_true(ResourceLoader.exists(photo.file), "%s: %s exists" % [id, photo.file])
			for key in ["author", "license", "source_url"]:
				assert_false(str(photo.get(key, "")).is_empty(), "%s photo needs %s (ADR 0006)" % [id, key])
			for locale in ["en", "pt_BR"]:
				assert_false(catalog.caption_of(photo, locale).is_empty(), "%s caption %s" % [id, locale])


func test_teotonio_has_its_real_photo() -> void:
	var photos := catalog.photos_of("secret_teotonio")
	assert_eq(photos.size(), 1)
	assert_string_contains(photos[0].author, "Agência Brasil")
	assert_eq(photos[0].license, "CC BY 3.0 BR")


func test_photos_of_ignores_bad_data() -> void:
	var c := PlaceCatalog.new()
	c.places = {"a": {"photos": "nope"}, "b": {"photos": [{"no_file": 1}, {"file": "x"}]}}
	assert_eq(c.photos_of("a"), [])
	assert_eq(c.photos_of("b").size(), 1)
