extends GutTest
## Enter the Madeira-Mamoré diorama from Porto Velho, photograph landmarks with the
## turning camera, leave. Swaps in a throwaway Passport so the save is untouched.

var _saved_passport: Passport
var _saved_flags: Dictionary
var world: Node


func before_each() -> void:
	_saved_passport = SaveStore.passport
	_saved_flags = SaveStore.flags
	SaveStore.persist = false
	SaveStore.flags = {"tutorial_seen": true}
	SaveStore.passport = Passport.new()
	world = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(world)
	await wait_process_frames(3)


func after_each() -> void:
	if world.diorama:
		world.exit_diorama()
	get_tree().paused = false
	SaveStore.passport = _saved_passport
	SaveStore.flags = _saved_flags
	SaveStore.persist = true


func _enter() -> Diorama:
	var pv: Dictionary = world.map.town("Porto Velho")
	world.truck.position = pv.road_pos
	await wait_process_frames(2)
	assert_true(world.near_diorama(), "the invitation shows at Porto Velho")
	world.enter_diorama()
	await wait_process_frames(3)
	return world.diorama


func _stand(d: Diorama, id: String, bearing_deg: float, camera_rotation: float) -> void:
	var spot: Dictionary = d.spots.filter(func(s): return s.id == id)[0]
	var b := deg_to_rad(bearing_deg)
	d.traveler.position = spot.pos + Vector2(sin(b), -cos(b)) * 55.0
	d._target_rotation = camera_rotation
	await wait_process_frames(2)
	d.camera.reset_smoothing()
	await wait_process_frames(2)


func test_entering_hides_the_state_map_and_exiting_restores_it() -> void:
	var d: Diorama = await _enter()
	assert_not_null(d)
	assert_false(world.ground.visible)
	assert_eq(d.spots.size(), 4, "locomotive, sheds, three water towers, river bank")
	world.exit_diorama()
	await wait_process_frames(2)
	assert_null(world.diorama)
	assert_true(world.ground.visible)
	assert_eq(SpriteStack.view_rotation, 0.0, "the state map is north-up again")


func test_locomotive_from_the_south_with_the_default_view() -> void:
	var d: Diorama = await _enter()
	await _stand(d, "efmm_locomotive", 180.0, 0.0)
	assert_eq(world.take_photo(world.hud.viewfinder_rect()), PhotoRules.Result.OK)
	assert_true(SaveStore.passport.has_photo("efmm_locomotive"))
	world.hud.close_sheet()


func test_water_towers_need_the_view_turned_to_look_from_the_east() -> void:
	var d: Diorama = await _enter()
	await _stand(d, "efmm_tres_caixas", 90.0, 0.0)
	assert_eq(world.take_photo(world.hud.viewfinder_rect()), PhotoRules.Result.WRONG_ANGLE)
	await _stand(d, "efmm_tres_caixas", 90.0, -PI / 2.0)
	assert_eq(world.take_photo(world.hud.viewfinder_rect()), PhotoRules.Result.OK)
	world.hud.close_sheet()


func test_leaving_works_only_at_the_truck() -> void:
	var d: Diorama = await _enter()
	assert_true(d.near_truck(), "you start next to the truck")
	d.traveler.position = Vector2(-200, 100)
	assert_false(d.near_truck())
