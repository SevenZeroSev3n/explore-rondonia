extends GutTest

const I18nScript := preload("res://scripts/core/i18n.gd")


func test_initial_locale_follows_the_browser() -> void:
	assert_eq(I18nScript.initial_locale("pt_BR"), "pt_BR")
	assert_eq(I18nScript.initial_locale("pt"), "pt_BR")
	assert_eq(I18nScript.initial_locale("PT-pt"), "pt_BR")
	assert_eq(I18nScript.initial_locale("en_US"), "en")
	assert_eq(I18nScript.initial_locale("es_BO"), "en", "everyone else gets English")


func test_build_translations_per_locale() -> void:
	var ts := I18nScript.build_translations({"HELLO": {"en": "Hello", "pt_BR": "Olá"}})
	assert_eq(ts.size(), 2)
	for t in ts:
		assert_eq(t.get_message("HELLO"), "Olá" if t.locale == "pt_BR" else "Hello")


func test_malformed_json_gives_an_empty_table() -> void:
	assert_eq(I18nScript.parse("nope"), {})


func test_shipped_strings_have_both_languages() -> void:
	var table := I18nScript.parse(FileAccess.get_file_as_string(I18nScript.STRINGS_PATH))
	assert_false(table.is_empty())
	for key in table:
		for locale in I18nScript.LOCALES:
			assert_true(table[key].has(locale), "%s is missing %s" % [key, locale])
			assert_false(str(table[key].get(locale, "")).is_empty(), "%s/%s is empty" % [key, locale])


func test_format_placeholders_match_between_languages() -> void:
	var table := I18nScript.parse(FileAccess.get_file_as_string(I18nScript.STRINGS_PATH))
	for key in table:
		assert_eq(table[key].en.count("%"), table[key].pt_BR.count("%"), "%s placeholders differ" % key)
