extends GutTest


func test_from_dict_parses_all_layers() -> void:
	var m := StateMapData.from_dict({
		"px_per_m": 0.06,
		"road": {"name": "BR-364", "points": [[0, 0], [10, -20]]},
		"border": [[-5, -5], [5, -5], [5, 5]],
		"rivers": [{"name": "Rio Machado", "points": [[1, 1], [2, 2]]}],
		"towns": [{"name": "Vilhena", "pos": [3, 4], "road_km": 0, "stamp": true}],
		"attribution": ["© OpenStreetMap contributors, ODbL"],
	})
	assert_almost_eq(m.px_per_m, 0.06, 0.0001)
	assert_eq(m.road_name, "BR-364")
	assert_eq(m.road, PackedVector2Array([Vector2(0, 0), Vector2(10, -20)]))
	assert_eq(m.border.size(), 3)
	assert_eq(m.rivers[0].name, "Rio Machado")
	assert_eq(m.towns[0].pos, Vector2(3, 4))
	assert_true(m.towns[0].stamp)
	assert_eq(m.attribution.size(), 1)


func test_shipped_map_is_sane() -> void:
	var m := StateMapData.load_file()
	assert_not_null(m)
	assert_gt(m.road.size(), 100, "BR-364 has a real shape")
	assert_gt(m.border.size(), 100, "the state border has a real shape")
	var names := m.towns.map(func(t): return t.name)
	for city in ["Vilhena", "Ji-Paraná", "Ariquemes", "Porto Velho"]:
		assert_has(names, city)
	assert_true(Geometry2D.is_point_in_polygon(m.road[0], m.border), "road starts inside the state")
	assert_false(m.attribution.is_empty(), "OSM/IBGE credits travel with the data")


func test_driving_the_whole_road_takes_about_eight_minutes() -> void:
	var m := StateMapData.load_file()
	var length := 0.0
	for i in m.road.size() - 1:
		length += m.road[i].distance_to(m.road[i + 1])
	var minutes := length / VehicleModel.new().max_speed / 60.0
	assert_almost_eq(minutes, 8.0, 0.25, "ADR 0003: ~8 minutes end to end at cruise speed")


func test_town_lookup_and_stamp_cities() -> void:
	var m := StateMapData.load_file()
	assert_eq(m.stamp_cities(), PackedStringArray(["Vilhena", "Ji-Paraná", "Ariquemes", "Porto Velho"]))
	var t := m.town("Ji-Paraná")
	assert_false(t.is_empty())
	assert_lt(t.road_pos.distance_to(t.pos), 200.0, "the stamp point sits on the road near the town")
	assert_true(m.town("Atlantis").is_empty())


func test_road_heading_points_along_the_road() -> void:
	var m := StateMapData.from_dict({"road": {"points": [[0, 0], [0, -10], [10, -10]]}})
	assert_almost_eq(m.road_heading(0), 0.0, 0.0001, "north")
	assert_almost_eq(m.road_heading(1), PI / 2, 0.0001, "east")
	assert_almost_eq(m.road_heading(99), PI / 2, 0.0001, "clamped to the last segment")
