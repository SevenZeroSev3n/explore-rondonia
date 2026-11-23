extends GutTest

const H := Forest.Habitat


func test_habitat_by_distance() -> void:
	assert_eq(Forest.habitat(1000.0, 30.0), H.RIVERSIDE, "riverbanks win, even far from the road")
	assert_eq(Forest.habitat(100.0, INF), H.PASTURE, "the cleared belt along BR-364")
	assert_eq(Forest.habitat(INF, INF), H.FOREST)


func test_pick_follows_weights_and_is_deterministic() -> void:
	var w := {"a": 1.0, "b": 3.0}
	assert_eq(Forest.pick(w, 0.0), "a")
	assert_eq(Forest.pick(w, 0.24), "a")
	assert_eq(Forest.pick(w, 0.26), "b")
	assert_eq(Forest.pick(w, 0.999), "b")


func test_each_habitat_has_its_own_species() -> void:
	var f := Forest.new(1)
	var seen := {H.FOREST: {}, H.RIVERSIDE: {}, H.PASTURE: {}}
	for h in seen:
		for i in 200:
			var s := Forest.pick(Forest.WEIGHTS[h], i / 200.0)
			seen[h][s] = true
	assert_has(seen[H.RIVERSIDE], "buriti", "buriti palms line the rivers")
	assert_does_not_have(seen[H.PASTURE], "acai")
	assert_has(seen[H.PASTURE], "castanheira", "protected castanheiras stand alone in pasture")
	assert_gt(seen[H.FOREST].size(), 4, "the forest is mixed")


func test_forest_is_far_denser_than_pasture() -> void:
	var f := Forest.new(364)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var kept := {H.FOREST: 0, H.PASTURE: 0}
	for i in 2000:
		var p := Vector2(rng.randf_range(0, 5000), rng.randf_range(0, 5000))
		var keep := rng.randf()
		var sp := rng.randf()
		for h in kept:
			if not f.tree_at(h, p, keep, sp).is_empty():
				kept[h] += 1
	assert_gt(kept[H.FOREST], 1200, "most forest candidates become trees")
	assert_lt(kept[H.PASTURE], 250, "pasture keeps only a few")


func test_cover_has_groves_and_clearings() -> void:
	var f := Forest.new(364)
	var lo := 1.0
	var hi := 0.0
	for x in range(0, 6000, 50):
		for y in range(0, 6000, 50):
			var c := f.cover(Vector2(x, y))
			lo = minf(lo, c)
			hi = maxf(hi, c)
	assert_lt(lo, 0.4, "some clearings")
	assert_eq(hi, 1.0, "some closed forest")


func test_every_species_has_a_sheet_matching_its_slice_count() -> void:
	for species in Forest.SLICES:
		var sheet: Texture2D = load("res://assets/stacks/%s/%s_slices.png" % [species, species])
		assert_not_null(sheet, species)
		# Tree slices are square: sheet width = slice side x slice count.
		assert_eq(sheet.get_width(), sheet.get_height() * Forest.SLICES[species], species)
