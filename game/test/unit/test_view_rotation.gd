extends GutTest
## The rotating diorama camera: slices, photo angles and walking stay screen-correct.

const EPS := Vector2(0.0001, 0.0001)


func test_without_view_rotation_slices_match_the_original_guide_formula() -> void:
	var angle := 0.7
	var squash := 0.75
	var xf := SpriteStack.slice_transform(angle, 0.0, squash, 5.0)
	var guide := Transform2D(angle, Vector2.ZERO).scaled(Vector2(1.0, squash))
	var p := Vector2(3, -8)
	assert_almost_eq(xf.basis_xform(p), guide.basis_xform(p), EPS)
	assert_almost_eq(xf.origin, Vector2(0, -5), EPS)


func test_with_view_rotation_slices_look_right_on_screen() -> void:
	var angle := 0.4
	var cam := 1.1
	var squash := 0.75
	var canvas := Transform2D(-cam, Vector2.ZERO)   # what a Camera2D rotated by cam does to the canvas
	var on_screen := canvas * SpriteStack.slice_transform(angle, cam, squash, 6.0)
	var expected := Transform2D(Vector2(1, 0), Vector2(0, squash), Vector2.ZERO) * Transform2D(angle - cam, Vector2.ZERO)
	var p := Vector2(5, -2)
	assert_almost_eq(on_screen.basis_xform(p), expected.basis_xform(p), EPS, "turned and squashed on screen")
	assert_almost_eq(on_screen.origin, Vector2(0, -6), EPS, "slices lift straight up on screen")


func test_eye_bearing_follows_the_camera() -> void:
	assert_almost_eq(PhotoRules.eye_bearing_deg(0.0), 180.0, 0.001, "default view looks from the south")
	assert_almost_eq(PhotoRules.eye_bearing_deg(-PI / 2.0), 90.0, 0.001)
	assert_almost_eq(PhotoRules.eye_bearing_deg(PI / 2.0), 270.0, 0.001)
	assert_almost_eq(PhotoRules.eye_bearing_deg(PI), 0.0, 0.001)


func test_judge_checks_frame_then_distance_then_angle() -> void:
	var spot := {"max_distance": 100.0, "window_half_deg": 30.0, "view_from_deg": 90.0}
	assert_eq(PhotoRules.judge(spot, false, 10.0, 0.0), PhotoRules.Result.NOT_IN_FRAME)
	assert_eq(PhotoRules.judge(spot, true, 150.0, 0.0), PhotoRules.Result.TOO_FAR)
	assert_eq(PhotoRules.judge(spot, true, 50.0, 31.0), PhotoRules.Result.WRONG_ANGLE)
	assert_eq(PhotoRules.judge(spot, true, 50.0, 29.0), PhotoRules.Result.OK)
	assert_almost_eq(PhotoRules.bearing_off(spot, 110.0), 20.0, 0.001)
	assert_almost_eq(PhotoRules.bearing_off({"view_from_deg": 350.0}, 10.0), 20.0, 0.001)


func test_walking_is_relative_to_the_screen() -> void:
	var up := Vector2(0, -1)
	assert_almost_eq(Traveler.move_direction(up, 0.0), Vector2(0, -1), EPS)
	# Camera turned 90° clockwise: screen-up now points east in the world.
	assert_almost_eq(Traveler.move_direction(up, PI / 2.0), Vector2(1, 0), EPS)
	assert_eq(Traveler.move_direction(Vector2.ZERO, 1.0), Vector2.ZERO)
	assert_almost_eq(Traveler.move_direction(Vector2(1, 1), 0.0).length(), 1.0, 0.0001, "no faster diagonally")
