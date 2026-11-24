extends GutTest
## Layer-1 zoom (ADR 0005 update): texels stay whole screen pixels, about half a UI pixel.

const StateMap := preload("res://scripts/world/state_map.gd")


func test_720p_draws_one_screen_pixel_per_texel() -> void:
	assert_almost_eq(StateMap.world_zoom(2), 0.5, 0.0001)


func test_1080p_keeps_texels_whole() -> void:
	var z := StateMap.world_zoom(3)
	assert_almost_eq(z, 1.0 / 3.0, 0.0001)
	assert_almost_eq(3 * z, roundf(3 * z), 0.0001, "a texel covers a whole number of screen pixels")


func test_4k_and_1440p() -> void:
	assert_almost_eq(StateMap.world_zoom(4), 0.5, 0.0001)
	assert_almost_eq(StateMap.world_zoom(6), 0.5, 0.0001)


func test_tiny_window_never_zooms_in() -> void:
	assert_almost_eq(StateMap.world_zoom(1), 1.0, 0.0001)
	assert_almost_eq(StateMap.world_zoom(0), 1.0, 0.0001)
