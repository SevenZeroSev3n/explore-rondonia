extends GutTest

var line := PackedVector2Array([Vector2(0, 0), Vector2(0, -100), Vector2(100, -100)])


func test_distance_to_a_vertical_segment() -> void:
	assert_almost_eq(RoadGeometry.distance_to_polyline(line, Vector2(10, -50)), 10.0, 0.001)


func test_distance_uses_the_closest_segment() -> void:
	assert_almost_eq(RoadGeometry.distance_to_polyline(line, Vector2(50, -90)), 10.0, 0.001)


func test_distance_beyond_the_end_is_to_the_endpoint() -> void:
	assert_almost_eq(RoadGeometry.distance_to_polyline(line, Vector2(0, 30)), 30.0, 0.001)


func test_degenerate_polylines() -> void:
	assert_eq(RoadGeometry.distance_to_polyline(PackedVector2Array(), Vector2.ZERO), INF)
	var single := PackedVector2Array([Vector2(3, 4)])
	assert_almost_eq(RoadGeometry.distance_to_polyline(single, Vector2.ZERO), 5.0, 0.001)


func test_surface_bands() -> void:
	assert_eq(RoadGeometry.surface_at_distance(0.0, 13.0, 18.0), VehicleModel.ASPHALT)
	assert_eq(RoadGeometry.surface_at_distance(13.0, 13.0, 18.0), VehicleModel.ASPHALT)
	assert_eq(RoadGeometry.surface_at_distance(15.0, 13.0, 18.0), VehicleModel.DIRT)
	assert_eq(RoadGeometry.surface_at_distance(40.0, 13.0, 18.0), VehicleModel.OFFROAD)
