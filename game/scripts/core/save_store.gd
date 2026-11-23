extends Node
## Local save (ADR 0002: progress saved locally, no cloud). On the web build
## user:// lives in the browser's IndexedDB.

const PATH := "user://save.json"
const VERSION := 1

var passport := Passport.new()
var locale := ""
## One-off flags: "tutorial_seen", "completion_seen".
var flags := {}
## Tests turn this off so they never write over the player's save.
var persist := true


func _ready() -> void:
	load_save()
	if not locale.is_empty():
		I18n.set_locale(locale)
	I18n.locale_changed.connect(func(l: String) -> void:
		locale = l
		save())
	passport.stamped.connect(func(_c: String) -> void: save())
	passport.photographed.connect(func(_id: String) -> void: save())


func load_save() -> void:
	var d := decode(FileAccess.get_file_as_string(PATH))
	passport = Passport.from_dict(d.get("passport", {}))
	locale = str(d.get("locale", ""))
	var raw_flags: Variant = d.get("flags", {})
	flags = raw_flags if typeof(raw_flags) == TYPE_DICTIONARY else {}


func save() -> void:
	if not persist:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(encode(passport, locale, flags))


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func set_flag(flag: String) -> void:
	if has_flag(flag):
		return
	flags[flag] = true
	save()


static func encode(p: Passport, loc: String, f: Dictionary = {}) -> String:
	return JSON.stringify({"version": VERSION, "locale": loc, "passport": p.to_dict(), "flags": f})


## A missing or corrupt save is a fresh start, never a crash.
static func decode(text: String) -> Dictionary:
	var json := JSON.new()   # instance parse: no engine error spam on bad input
	if text.is_empty() or json.parse(text) != OK:
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}
