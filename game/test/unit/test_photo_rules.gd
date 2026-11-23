extends GutTest

const R := PhotoRules.Result

# Ideal side: east of the spot (view_from 90°), ±45°.
var spot := {
	"id": "s", "pos": Vector2(100, 100), "radius": 10.0, "max_distance": 150.0,
	"view_from_deg": 90.0, "window_half_deg": 45.0,
}
var frame := Rect2(0, 0, 240, 200)


func test_ok_from_the_right_side() -> void:
	assert_eq(PhotoRules.evaluate(spot, frame, Vector2(180, 100)), R.OK)


func test_must_be_fully_in_frame() -> void:
	var cut := Rect2(95, 0, 200, 200)   # left edge cuts through the spot
	assert_eq(PhotoRules.evaluate(spot, cut, Vector2(180, 100)), R.NOT_IN_FRAME)


func test_too_far() -> void:
	assert_eq(PhotoRules.evaluate(spot, Rect2(-500, -500, 2000, 2000), Vector2(400, 100)), R.TOO_FAR)


func test_wrong_side() -> void:
	assert_eq(PhotoRules.evaluate(spot, frame, Vector2(20, 100)), R.WRONG_ANGLE)


func test_window_edges() -> void:
	# 40° off the ideal bearing is inside ±45°, 50° is outside.
	var inside := Vector2(100, 100) + Vector2.from_angle(deg_to_rad(90.0 - 90.0 - 40.0)) * 60.0
	var outside := Vector2(100, 100) + Vector2.from_angle(deg_to_rad(90.0 - 90.0 - 50.0)) * 60.0
	assert_almost_eq(PhotoRules.angle_off(spot, inside), 40.0, 0.01)
	assert_eq(PhotoRules.evaluate(spot, frame, inside), R.OK)
	assert_eq(PhotoRules.evaluate(spot, frame, outside), R.WRONG_ANGLE)


func test_angle_wraps_around_north() -> void:
	var north := spot.duplicate()
	north.view_from_deg = 350.0
	var viewer := Vector2(100, 100) + Vector2(sin(deg_to_rad(10.0)), -cos(deg_to_rad(10.0))) * 50.0
	assert_almost_eq(PhotoRules.angle_off(north, viewer), 20.0, 0.01)


func test_pick_spot_prefers_the_one_nearest_the_centre() -> void:
	var a := spot.duplicate()
	a.id = "a"
	a.pos = Vector2(110, 100)
	var b := spot.duplicate()
	b.id = "b"
	b.pos = Vector2(20, 20)
	var c := spot.duplicate()
	c.id = "c"
	c.pos = Vector2(900, 900)
	assert_eq(PhotoRules.pick_spot([b, c, a], frame).id, "a")
	assert_true(PhotoRules.pick_spot([c], frame).is_empty())


func test_every_failure_has_a_hint() -> void:
	for r in [R.NOT_IN_FRAME, R.TOO_FAR, R.WRONG_ANGLE]:
		assert_ne(PhotoRules.hint_key(r), "")
	assert_eq(PhotoRules.hint_key(R.OK), "")
