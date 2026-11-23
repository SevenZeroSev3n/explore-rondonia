class_name StateMapData
extends RefCounted
## The layer-1 map built by tools/geo/build_map.py (ADR 0003), parsed into Godot types.

const DEFAULT_PATH := "res://data/geo/state_map.json"

var px_per_m := 0.0
var road_name := ""
var road := PackedVector2Array()
var border := PackedVector2Array()
var rivers: Array[Dictionary] = []   ## {name: String, points: PackedVector2Array}
var towns: Array[Dictionary] = []    ## {name, pos: Vector2, road_pos: Vector2, road_seg: int, road_km, stamp: bool}
var attribution: PackedStringArray = []


static func load_file(path: String = DEFAULT_PATH) -> StateMapData:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("state map not found: %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("state map is not a JSON object: %s" % path)
		return null
	return from_dict(parsed)


static func from_dict(d: Dictionary) -> StateMapData:
	var m := StateMapData.new()
	m.px_per_m = float(d.get("px_per_m", 0.0))
	var road_d: Dictionary = d.get("road", {})
	m.road_name = str(road_d.get("name", ""))
	m.road = _points(road_d.get("points", []))
	m.border = _points(d.get("border", []))
	for r in d.get("rivers", []):
		m.rivers.append({"name": str(r.get("name", "")), "points": _points(r.get("points", []))})
	for t in d.get("towns", []):
		var pos: Array = t.get("pos", [0, 0])
		var road_pos: Array = t.get("road_pos", pos)
		m.towns.append({
			"name": str(t.get("name", "")),
			"pos": Vector2(pos[0], pos[1]),
			"road_pos": Vector2(road_pos[0], road_pos[1]),
			"road_seg": int(t.get("road_seg", 0)),
			"road_km": float(t.get("road_km", 0.0)),
			"stamp": bool(t.get("stamp", false)),
		})
	for line in d.get("attribution", []):
		m.attribution.append(str(line))
	return m


func town(town_name: String) -> Dictionary:
	for t in towns:
		if t.name == town_name:
			return t
	return {}


func stamp_cities() -> PackedStringArray:
	var out: PackedStringArray = []
	for t in towns:
		if t.stamp:
			out.append(t.name)
	return out


## Heading (0 = north, clockwise) of the road at segment i.
func road_heading(i: int) -> float:
	i = clampi(i, 0, road.size() - 2)
	var d := road[i + 1] - road[i]
	return atan2(d.x, -d.y)


static func _points(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(raw.size())
	for i in raw.size():
		out[i] = Vector2(raw[i][0], raw[i][1])
	return out
