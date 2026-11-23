extends GutTest


func test_same_chunk_gives_same_trees() -> void:
	var a := TreeScatter.candidates(Vector2i(3, -7), 384.0, 18, 364)
	var b := TreeScatter.candidates(Vector2i(3, -7), 384.0, 18, 364)
	assert_eq(a, b)


func test_different_chunks_differ() -> void:
	var a := TreeScatter.candidates(Vector2i(0, 0), 384.0, 18, 364)
	var b := TreeScatter.candidates(Vector2i(1, 0), 384.0, 18, 364)
	assert_ne(a, b)


func test_candidates_stay_inside_their_chunk() -> void:
	var chunk := Vector2i(-2, 5)
	var rect := Rect2(Vector2(chunk) * 384.0, Vector2(384.0, 384.0)).grow(1.0)
	for c in TreeScatter.candidates(chunk, 384.0, 18, 364):
		assert_true(rect.has_point(c.pos), "%s outside %s" % [c.pos, rect])


func test_count_varies_around_the_target() -> void:
	var n := TreeScatter.candidates(Vector2i(9, 9), 384.0, 18, 364).size()
	assert_between(n, 12, 24)


func test_chunk_of_handles_negative_coordinates() -> void:
	assert_eq(TreeScatter.chunk_of(Vector2(-1, -1), 384.0), Vector2i(-1, -1))
	assert_eq(TreeScatter.chunk_of(Vector2(383.9, 0), 384.0), Vector2i(0, 0))
