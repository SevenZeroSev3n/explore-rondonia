extends GutTest
## ADR 0009: road progress, fuel tank, petrol stations, fences and animal groups.

# An L-shaped road: 300 px north, then 400 px east (700 px), mapped to 700 km.
var road := PackedVector2Array([Vector2(0, 0), Vector2(0, -300), Vector2(400, -300)])


func test_progress_projects_onto_the_road_and_scales_to_km() -> void:
	var p := RoadProgress.new(road, 700.0)
	assert_almost_eq(p.km_at(Vector2(0, 0)), 0.0, 0.01)
	assert_almost_eq(p.km_at(Vector2(5, -150)), 150.0, 0.01, "beside the road counts as the nearest point")
	assert_almost_eq(p.km_at(Vector2(200, -320)), 500.0, 0.01)
	assert_almost_eq(p.km_at(Vector2(900, -300)), 700.0, 0.01, "past the end stays at the end")


func test_progress_finds_the_point_at_a_km() -> void:
	var p := RoadProgress.new(road, 700.0)
	assert_almost_eq(p.point_at_km(150.0), Vector2(0, -150), Vector2(0.01, 0.01))
	assert_almost_eq(p.point_at_km(500.0), Vector2(200, -300), Vector2(0.01, 0.01))


func test_tank_burns_with_distance_and_refills() -> void:
	var t := FuelTank.new(250.0)
	assert_eq(t.fraction(), 1.0, "starts full")
	t.burn_km(100.0)
	assert_almost_eq(t.fraction(), 0.6, 0.0001)
	t.burn_km(500.0)
	assert_true(t.is_empty())
	assert_eq(t.level_km, 0.0, "never below zero")
	t.fill_step(1.0, 100.0)
	assert_almost_eq(t.level_km, 100.0, 0.0001, "fills at a rate")
	t.fill_step(10.0, 100.0)
	assert_eq(t.level_km, 250.0, "never above capacity")


func test_stations_sit_beside_the_road_at_each_town() -> void:
	var towns: Array[Dictionary] = [
		{"name": "A", "road_pos": Vector2(0, -50), "road_seg": 0, "road_km": 50.0},
		{"name": "B", "road_pos": Vector2(300, -300), "road_seg": 1, "road_km": 600.0},
	]
	var st := FuelStations.from_towns(towns, road, 64.0)
	assert_eq(st.size(), 2)
	assert_almost_eq(st[0].pos.distance_to(towns[0].road_pos), 64.0, 0.01, "set back from the road")
	assert_eq(FuelStations.nearest(st, 400.0).town, "B")
	assert_eq(FuelStations.nearest(st, 100.0).town, "A")
	assert_eq(FuelStations.next_ahead(st, 100.0).town, "B")
	assert_true(FuelStations.next_ahead(st, 650.0).is_empty(), "nothing after the last town")


func test_fence_posts_follow_both_sides_at_the_spacing() -> void:
	var posts := Roadside.fence_posts(road, Rect2(-200, -400, 800, 500), 80.0, 25.0)
	assert_gt(posts.size(), 40)
	var left := posts.filter(func(p): return p.side < 0)
	var right := posts.filter(func(p): return p.side > 0)
	assert_eq(left.size() > 0 and right.size() > 0, true, "both sides of the road")
	var even := 0
	for p in posts:
		assert_gt(RoadGeometry.distance_to_polyline(road, p.pos), 64.0, "never on the road")
		if absf((p.next as Vector2).distance_to(p.pos) - 25.0) < 0.5:
			even += 1
	assert_gt(float(even), posts.size() * 0.9, "posts are evenly spaced except around the bend")


func test_fence_posts_only_inside_the_rect() -> void:
	var rect := Rect2(-200, -100, 400, 100)
	for p in Roadside.fence_posts(road, rect, 80.0, 25.0):
		assert_true(rect.has_point(p.pos))


func test_animal_groups_by_habitat() -> void:
	var cows := Fauna.group(Forest.Habitat.PASTURE, Vector2(100, 100), 0.1, 0.5)
	assert_gt(cows.size(), 1, "cattle graze in small herds")
	for a in cows:
		assert_eq(a.species, "cattle")
		assert_lt((a.pos as Vector2).distance_to(Vector2(100, 100)), 60.0)
	var capys := Fauna.group(Forest.Habitat.RIVERSIDE, Vector2.ZERO, 0.1, 0.5)
	assert_eq(capys[0].species, "capybara")
	assert_eq(Fauna.group(Forest.Habitat.FOREST, Vector2.ZERO, 0.1, 0.5), [], "no animals in deep forest")
	assert_eq(Fauna.group(Forest.Habitat.PASTURE, Vector2.ZERO, 0.99, 0.5), [], "most spots stay empty")
	assert_eq(Fauna.group(Forest.Habitat.PASTURE, Vector2(3, 4), 0.1, 0.3),
		Fauna.group(Forest.Habitat.PASTURE, Vector2(3, 4), 0.1, 0.3), "deterministic")


func test_speedometer_reads_100_at_top_speed_on_asphalt() -> void:
	var m := VehicleModel.new()
	m.speed = m.max_speed
	assert_almost_eq(m.kmh(), 100.0, 0.001)
	m.speed = m.max_speed * VehicleModel.DIRT
	assert_almost_eq(m.kmh(), 60.0, 0.001)


func test_new_species_have_slice_counts_and_weights() -> void:
	for s in ["babacu", "sumauma"]:
		assert_has(Forest.SLICES, s)
	assert_gt(Forest.WEIGHTS[Forest.Habitat.PASTURE].get("babacu", 0.0), 0.0, "babaçu dominates pastures")
	assert_gt(Forest.WEIGHTS[Forest.Habitat.FOREST].get("sumauma", 0.0), 0.0)
