class_name Passport
extends RefCounted
## The player's progress (ADR 0008): city stamps now, photos later. Pure data;
## SaveStore persists it.

signal stamped(city: String)
signal photographed(place_id: String)

var stamps: PackedStringArray = []
var photos: PackedStringArray = []


func has_stamp(city: String) -> bool:
	return stamps.has(city)


## Stamps the city; returns true only the first time.
func stamp(city: String) -> bool:
	if city.is_empty() or has_stamp(city):
		return false
	stamps.append(city)
	stamped.emit(city)
	return true


func has_photo(place_id: String) -> bool:
	return photos.has(place_id)


## Records a valid photo of a place; returns true only the first time.
func add_photo(place_id: String) -> bool:
	if place_id.is_empty() or has_photo(place_id):
		return false
	photos.append(place_id)
	photographed.emit(place_id)
	return true


func photo_count(required: PackedStringArray) -> int:
	var n := 0
	for id in required:
		if has_photo(id):
			n += 1
	return n


func stamp_count(required: PackedStringArray) -> int:
	var n := 0
	for city in required:
		if has_stamp(city):
			n += 1
	return n


## True when every required stamp and photo is in (ADR 0008: the MVP ending).
func is_complete(required_stamps: PackedStringArray, required_photos: PackedStringArray) -> bool:
	return stamp_count(required_stamps) == required_stamps.size() \
		and photo_count(required_photos) == required_photos.size()


func to_dict() -> Dictionary:
	return {"stamps": Array(stamps), "photos": Array(photos)}


static func from_dict(d: Dictionary) -> Passport:
	var p := Passport.new()
	_append_strings(p.stamps, d.get("stamps", []))
	_append_strings(p.photos, d.get("photos", []))
	return p


## Appends the unique strings of raw, ignoring anything that is not an array of strings.
static func _append_strings(into: PackedStringArray, raw: Variant) -> void:
	if typeof(raw) != TYPE_ARRAY:
		return
	for item in raw:
		if typeof(item) == TYPE_STRING and not into.has(item):
			into.append(item)


## Stamp cities whose road point lies within radius of pos (stamped or not; Passport.stamp dedupes).
static func cities_in_reach(towns: Array, pos: Vector2, radius: float) -> PackedStringArray:
	var out: PackedStringArray = []
	for t in towns:
		if t.stamp and pos.distance_to(t.road_pos) <= radius:
			out.append(t.name)
	return out
