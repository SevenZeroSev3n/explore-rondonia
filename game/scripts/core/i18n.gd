extends Node
## Loads player-facing strings from game/data/i18n/strings.json into the
## TranslationServer (ADR 0006), so every tr("KEY") works. JSON instead of CSV
## keeps the data diff-friendly and avoids generated .translation files.

signal locale_changed(locale: String)

const STRINGS_PATH := "res://data/i18n/strings.json"
const LOCALES: PackedStringArray = ["en", "pt_BR"]


func _enter_tree() -> void:
	var table := parse(FileAccess.get_file_as_string(STRINGS_PATH))
	for t in build_translations(table):
		TranslationServer.add_translation(t)
	set_locale(initial_locale(OS.get_locale()))


## {key: {locale: text}} from the JSON text; empty on malformed input.
static func parse(text: String) -> Dictionary:
	var json := JSON.new()   # instance parse: no engine error spam on bad input
	if json.parse(text) != OK:
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}


static func build_translations(table: Dictionary) -> Array[Translation]:
	var out: Array[Translation] = []
	for locale in LOCALES:
		var t := Translation.new()
		t.locale = locale
		for key in table:
			var entry: Dictionary = table[key]
			if entry.has(locale):
				t.add_message(key, entry[locale])
		out.append(t)
	return out


## Portuguese for Portuguese-speaking browsers, English for everyone else (ADR 0006).
static func initial_locale(system_locale: String) -> String:
	return "pt_BR" if system_locale.to_lower().begins_with("pt") else "en"


func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)


func current() -> String:
	return "pt_BR" if TranslationServer.get_locale().begins_with("pt") else "en"


func toggle() -> void:
	set_locale("en" if current() == "pt_BR" else "pt_BR")
