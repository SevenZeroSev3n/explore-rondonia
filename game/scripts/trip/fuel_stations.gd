class_name FuelStations
extends RefCounted
## Petrol stations beside BR-364, one at each town on the road (ADR 0009): every one of
## those towns has real stations, so no invented place is needed.


## [{town, pos, angle, road_km}] with each station set back `setback` px to the right of
## the road (travelling towards Porto Velho), its front facing the road.
static func from_towns(towns: Array[Dictionary], road: PackedVector2Array, setback: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in towns:
		var seg := clampi(int(t.road_seg), 0, road.size() - 2)
		var d := (road[seg + 1] - road[seg]).normalized()
		var n := Vector2(-d.y, d.x)                 # right of the direction of travel
		out.append({
			"town": str(t.name),
			"pos": (t.road_pos as Vector2) + n * setback,
			"angle": atan2(-n.x, n.y),              # SpriteStack angle whose front faces -n
			"road_km": float(t.road_km),
		})
	return out


static func nearest(stations: Array[Dictionary], km: float) -> Dictionary:
	var best := {}
	for s in stations:
		if best.is_empty() or absf(s.road_km - km) < absf(best.road_km - km):
			best = s
	return best


## The first station further along the road than km (towards Porto Velho), or {}.
static func next_ahead(stations: Array[Dictionary], km: float) -> Dictionary:
	var best := {}
	for s in stations:
		if s.road_km > km + 1.0 and (best.is_empty() or s.road_km < best.road_km):
			best = s
	return best
