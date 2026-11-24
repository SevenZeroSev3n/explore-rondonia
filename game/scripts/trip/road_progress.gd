class_name RoadProgress
extends RefCounted
## Where along BR-364 a world position is, in real kilometres (ADR 0009). The map is
## compressed (ADR 0003), so km come from scaling arc length to the road's real length.

var road: PackedVector2Array
var total_km := 0.0
var _cumulative := PackedFloat32Array()   ## arc length in px at each road point
var _total_px := 0.0


func _init(points: PackedVector2Array, road_km: float) -> void:
	road = points
	total_km = road_km
	_cumulative.resize(points.size())
	var acc := 0.0
	for i in points.size():
		if i > 0:
			acc += points[i - 1].distance_to(points[i])
		_cumulative[i] = acc
	_total_px = acc


## Km along the road of the nearest road point to pos.
func km_at(pos: Vector2) -> float:
	if road.size() < 2 or _total_px <= 0.0:
		return 0.0
	var best := INF
	var best_arc := 0.0
	for i in road.size() - 1:
		var a := road[i]
		var b := road[i + 1]
		var q := Geometry2D.get_closest_point_to_segment(pos, a, b)
		var d := pos.distance_squared_to(q)
		if d < best:
			best = d
			best_arc = _cumulative[i] + a.distance_to(q)
	return best_arc / _total_px * total_km


## World position on the road at a km.
func point_at_km(km: float) -> Vector2:
	var arc := clampf(km / total_km, 0.0, 1.0) * _total_px
	for i in road.size() - 1:
		if arc <= _cumulative[i + 1] or i == road.size() - 2:
			var seg := _cumulative[i + 1] - _cumulative[i]
			var t := 0.0 if seg <= 0.0 else (arc - _cumulative[i]) / seg
			return road[i].lerp(road[i + 1], clampf(t, 0.0, 1.0))
	return road[0] if road.size() > 0 else Vector2.ZERO
