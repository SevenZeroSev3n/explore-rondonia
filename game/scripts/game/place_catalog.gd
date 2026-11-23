class_name PlaceCatalog
extends RefCounted
## Tourist places and secrets from game/data/places/*.json (ADR 0006): bilingual
## name and text, sources, photo rules. Text is picked by the current locale.

const DIR := "res://data/places"

var places: Dictionary = {}   ## id -> Dictionary (raw JSON)


static func load_dir(dir: String = DIR) -> PlaceCatalog:
	var c := PlaceCatalog.new()
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".json"):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(dir.path_join(file))) != OK:
			push_warning("bad place file: %s" % file)
			continue
		var d: Variant = json.data
		if typeof(d) == TYPE_DICTIONARY and d.has("id"):
			c.places[d.id] = d
	return c


func has(id: String) -> bool:
	return places.has(id)


func ids_of_kind(kind: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for id in places:
		if places[id].get("kind", "") == kind:
			out.append(id)
	out.sort()
	return out


func name_of(id: String, locale: String) -> String:
	return _localized(id, "name", locale)


func text_of(id: String, locale: String) -> String:
	return _localized(id, "text", locale)


func sources_of(id: String) -> PackedStringArray:
	return PackedStringArray(places.get(id, {}).get("sources", []))


## Photo rules merged with the spot's position and side from the state map.
func spot_for(id: String, pos: Vector2, view_from_deg: float) -> Dictionary:
	var rules: Dictionary = places.get(id, {}).get("photo_rules", {})
	return {
		"id": id,
		"pos": pos,
		"view_from_deg": view_from_deg,
		"radius": float(rules.get("radius_px", 10.0)),
		"max_distance": float(rules.get("max_distance_px", 150.0)),
		"window_half_deg": float(rules.get("window_half_deg", 30.0)),
	}


## Falls back to English, then to the id, so a missing translation never shows blank.
func _localized(id: String, field: String, locale: String) -> String:
	var entry: Variant = places.get(id, {}).get(field, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return id
	return str(entry.get(locale, entry.get("en", id)))
