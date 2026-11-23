extends GutTest

var road := PackedVector2Array([Vector2(0, 0), Vector2(0, -500), Vector2(400, -900), Vector2(1200, -900)])


func test_matches_brute_force_within_range() -> void:
	var index := PolylineIndex.new([road], 64.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 400:
		var p := Vector2(rng.randf_range(-200, 1400), rng.randf_range(-1100, 200))
		var brute := RoadGeometry.distance_to_polyline(road, p)
		var fast := index.distance_within(p, 60.0)
		if brute <= 60.0:
			assert_almost_eq(fast, brute, 0.001, "point %s" % p)
		else:
			assert_eq(fast, INF, "point %s is out of range" % p)


func test_long_segment_spanning_many_cells_is_found_in_the_middle() -> void:
	var index := PolylineIndex.new([PackedVector2Array([Vector2(0, 0), Vector2(5000, 0)])], 64.0)
	assert_almost_eq(index.distance_within(Vector2(2500, 10), 20.0), 10.0, 0.001)


func test_several_polylines() -> void:
	var a := PackedVector2Array([Vector2(0, 0), Vector2(100, 0)])
	var b := PackedVector2Array([Vector2(0, 50), Vector2(100, 50)])
	var index := PolylineIndex.new([a, b], 32.0)
	assert_almost_eq(index.distance_within(Vector2(50, 40), 30.0), 10.0, 0.001)


func test_empty_index() -> void:
	var index := PolylineIndex.new([], 64.0)
	assert_eq(index.distance_within(Vector2.ZERO, 100.0), INF)
