class_name PolylineIndex
extends RefCounted
## Uniform-grid index over the segments of one or more polylines, for fast
## "how far is this point from the road / a river" queries on a map tens of
## thousands of pixels wide. Only answers up to a maximum distance.

var cell_size: float
var _points: Array[PackedVector2Array] = []
var _cells: Dictionary = {}   ## Vector2i -> Array of Vector2i(polyline index, segment index)


func _init(polylines: Array, cell: float = 64.0) -> void:
	cell_size = cell
	for line in polylines:
		_add(line)


## Distance from p to the nearest indexed segment, or INF when none is within max_distance.
func distance_within(p: Vector2, max_distance: float) -> float:
	var best := INF
	var lo := _cell(p - Vector2(max_distance, max_distance))
	var hi := _cell(p + Vector2(max_distance, max_distance))
	for cx in range(lo.x, hi.x + 1):
		for cy in range(lo.y, hi.y + 1):
			for ref: Vector2i in _cells.get(Vector2i(cx, cy), []):
				var pts := _points[ref.x]
				var q := Geometry2D.get_closest_point_to_segment(p, pts[ref.y], pts[ref.y + 1])
				best = minf(best, p.distance_to(q))
	return best if best <= max_distance else INF


func _add(line: PackedVector2Array) -> void:
	var li := _points.size()
	_points.append(line)
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var lo := _cell(Vector2(minf(a.x, b.x), minf(a.y, b.y)))
		var hi := _cell(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)))
		# Bounding-box cells: conservative, so queries never miss a segment.
		for cx in range(lo.x, hi.x + 1):
			for cy in range(lo.y, hi.y + 1):
				var key := Vector2i(cx, cy)
				if not _cells.has(key):
					_cells[key] = []
				_cells[key].append(Vector2i(li, i))


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / cell_size), floori(p.y / cell_size))
