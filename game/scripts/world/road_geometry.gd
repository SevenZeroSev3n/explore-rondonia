class_name RoadGeometry
extends RefCounted
## Geometry helpers on road polylines (world coordinates).


## Shortest distance from point p to the polyline through points.
static func distance_to_polyline(points: PackedVector2Array, p: Vector2) -> float:
	if points.is_empty():
		return INF
	if points.size() == 1:
		return p.distance_to(points[0])
	var best := INF
	for i in points.size() - 1:
		var closest := Geometry2D.get_closest_point_to_segment(p, points[i], points[i + 1])
		best = minf(best, p.distance_to(closest))
	return best


## Speed factor of the ground at distance d from the road centre line.
static func surface_at_distance(d: float, asphalt_half_width: float, shoulder_half_width: float) -> float:
	if d <= asphalt_half_width:
		return VehicleModel.ASPHALT
	if d <= shoulder_half_width:
		return VehicleModel.DIRT
	return VehicleModel.OFFROAD
