extends GutTest

const SaveStoreScript := preload("res://scripts/core/save_store.gd")

var towns := [
	{"name": "Vilhena", "road_pos": Vector2(0, 0), "stamp": true},
	{"name": "Pimenta Bueno", "road_pos": Vector2(30, 0), "stamp": false},
	{"name": "Ji-Paraná", "road_pos": Vector2(500, 0), "stamp": true},
]


func test_stamp_only_counts_the_first_time() -> void:
	var p := Passport.new()
	watch_signals(p)
	assert_true(p.stamp("Vilhena"))
	assert_false(p.stamp("Vilhena"))
	assert_signal_emit_count(p, "stamped", 1)
	assert_true(p.has_stamp("Vilhena"))


func test_empty_city_is_ignored() -> void:
	assert_false(Passport.new().stamp(""))


func test_stamp_count_only_counts_required_cities() -> void:
	var p := Passport.new()
	p.stamp("Vilhena")
	p.stamp("Somewhere else")
	assert_eq(p.stamp_count(["Vilhena", "Ji-Paraná"]), 1)


func test_round_trip_through_dict() -> void:
	var p := Passport.new()
	p.stamp("Vilhena")
	p.photos.append("efmm_locomotive")
	var q := Passport.from_dict(p.to_dict())
	assert_eq(q.stamps, p.stamps)
	assert_eq(q.photos, p.photos)


func test_from_dict_drops_junk_and_duplicates() -> void:
	var q := Passport.from_dict({"stamps": ["Vilhena", 42, "Vilhena", null], "photos": "nope"})
	assert_eq(q.stamps, PackedStringArray(["Vilhena"]))
	assert_true(q.photos.is_empty())


func test_cities_in_reach_only_returns_stamp_cities_close_enough() -> void:
	assert_eq(Passport.cities_in_reach(towns, Vector2(10, 0), 70.0), PackedStringArray(["Vilhena"]))
	assert_eq(Passport.cities_in_reach(towns, Vector2(250, 0), 70.0), PackedStringArray())
	assert_eq(Passport.cities_in_reach(towns, Vector2(480, 30), 70.0), PackedStringArray(["Ji-Paraná"]))


func test_save_round_trip() -> void:
	var p := Passport.new()
	p.stamp("Ariquemes")
	var d := SaveStoreScript.decode(SaveStoreScript.encode(p, "pt_BR"))
	assert_eq(d.locale, "pt_BR")
	assert_eq(Passport.from_dict(d.passport).stamps, PackedStringArray(["Ariquemes"]))


func test_missing_or_corrupt_save_is_a_fresh_start() -> void:
	assert_eq(SaveStoreScript.decode(""), {})
	assert_eq(SaveStoreScript.decode("{not json"), {})
	assert_eq(SaveStoreScript.decode("[1, 2]"), {})


func test_photos_only_count_the_first_time() -> void:
	var p := Passport.new()
	watch_signals(p)
	assert_true(p.add_photo("secret_mandi"))
	assert_false(p.add_photo("secret_mandi"))
	assert_false(p.add_photo(""))
	assert_signal_emit_count(p, "photographed", 1)
	assert_eq(p.photo_count(["secret_mandi", "secret_teotonio"]), 1)


func test_complete_needs_every_stamp_and_photo() -> void:
	var p := Passport.new()
	var stamps := PackedStringArray(["A", "B"])
	var photos := PackedStringArray(["x"])
	assert_false(p.is_complete(stamps, photos))
	p.stamp("A")
	p.stamp("B")
	assert_false(p.is_complete(stamps, photos), "photos missing")
	p.add_photo("x")
	assert_true(p.is_complete(stamps, photos))


func test_flags_round_trip_through_the_save() -> void:
	var d := SaveStoreScript.decode(SaveStoreScript.encode(Passport.new(), "en", {"tutorial_seen": true}))
	assert_eq(d.flags, {"tutorial_seen": true})
