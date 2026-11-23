extends Node
## Local save (ADR 0002: progress saved locally, no cloud). On the web build
## user:// lives in the browser's IndexedDB.

const PATH := "user://save.json"
const VERSION := 1

var passport := Passport.new()
var locale := ""


func _ready() -> void:
	load_save()
	if not locale.is_empty():
		I18n.set_locale(locale)
	I18n.locale_changed.connect(func(l: String) -> void:
		locale = l
		save())
	passport.stamped.connect(func(_c: String) -> void: save())


func load_save() -> void:
	var d := decode(FileAccess.get_file_as_string(PATH))
	passport = Passport.from_dict(d.get("passport", {}))
	locale = str(d.get("locale", ""))


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(encode(passport, locale))


static func encode(p: Passport, loc: String) -> String:
	return JSON.stringify({"version": VERSION, "locale": loc, "passport": p.to_dict()})


## A missing or corrupt save is a fresh start, never a crash.
static func decode(text: String) -> Dictionary:
	var json := JSON.new()   # instance parse: no engine error spam on bad input
	if text.is_empty() or json.parse(text) != OK:
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}
