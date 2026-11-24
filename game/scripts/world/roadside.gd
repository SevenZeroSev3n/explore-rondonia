class_name Roadside
extends RefCounted
## Fence lines along BR-364 (ADR 0009): posts on both sides at a fixed offset and spacing.
## Pure geometry; the state map decides where fences may stand (pasture only).


## Posts whose position falls in rect: [{pos, next, side}], where next is the following
## post on the same side (for the wire) and side is -1 (left) or 1 (right of travel).
## Posts that an inner bend pushes onto the road are dropped; road_distance(p) measures that
## (pass a spatial index's lookup in the game; the default walks the whole road).
static func fence_posts(road: PackedVector2Array, rect: Rect2, offset: float, spacing: float,
		road_distance: Callable = Callable()) -> Array:
	if not road_distance.is_valid():
		road_distance = func(p: Vector2) -> float: return RoadGeometry.distance_to_polyline(road, p)
	var out := []
	var s0 := 0.0
	for i in road.size() - 1:
		var a := road[i]
		var b := road[i + 1]
		var length := a.distance_to(b)
		if length <= 0.0:
			continue
		var reach := offset + spacing
		if rect.grow(reach).intersects(Rect2(a, Vector2.ZERO).expand(b)):
			var arc := ceilf(s0 / spacing) * spacing
			while arc < s0 + length:
				for side in [-1, 1]:
					var p := _offset_point(road, i, arc - s0, side, offset)
					if rect.has_point(p) and road_distance.call(p) > offset * 0.8:
						out.append({"pos": p, "next": _point_at_arc(road, i, arc - s0 + spacing, side, offset), "side": side})
				arc += spacing
		s0 += length
	return out


static func _offset_point(road: PackedVector2Array, i: int, along: float, side: int, offset: float) -> Vector2:
	var d := (road[i + 1] - road[i]).normalized()
	return road[i] + d * along + Vector2(-d.y, d.x) * side * offset


## The offset point `along` px past road[i], walking into the next segments if needed.
static func _point_at_arc(road: PackedVector2Array, i: int, along: float, side: int, offset: float) -> Vector2:
	while i < road.size() - 2 and along > road[i].distance_to(road[i + 1]):
		along -= road[i].distance_to(road[i + 1])
		i += 1
	return _offset_point(road, i, along, side, offset)
