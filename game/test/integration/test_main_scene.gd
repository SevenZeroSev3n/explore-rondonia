extends GutTest
## Loads the real main scene: start stamp, teleport rules. Swaps in a throwaway
## Passport so the test never writes over the player's save.

var _saved_passport: Passport
var _saved_flags: Dictionary
var world: Node


func before_each() -> void:
	_saved_passport = SaveStore.passport
	_saved_flags = SaveStore.flags
	SaveStore.persist = false
	SaveStore.flags = {"tutorial_seen": true}
	SaveStore.passport = Passport.new()   # not connected to save(): nothing touches disk
	world = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(world)
	await wait_process_frames(3)   # stamping runs in _process, not physics


func after_each() -> void:
	get_tree().paused = false
	SaveStore.passport = _saved_passport
	SaveStore.flags = _saved_flags
	SaveStore.persist = true


func test_starting_in_vilhena_stamps_it() -> void:
	assert_true(SaveStore.passport.has_stamp("Vilhena"), "ADR 0008: the first stamp is the first reward")
	assert_false(SaveStore.passport.has_stamp("Porto Velho"))


func test_cannot_teleport_to_an_unvisited_city() -> void:
	var before: Vector2 = world.truck.position
	world.teleport_to("Porto Velho")
	assert_eq(world.truck.position, before)


func test_teleport_lands_on_the_road_facing_along_it() -> void:
	SaveStore.passport.stamp("Ariquemes")
	world.teleport_to("Ariquemes")
	var t: Dictionary = world.map.town("Ariquemes")
	assert_eq(world.truck.position, t.road_pos)
	assert_almost_eq(world.truck.model.heading, world.map.road_heading(t.road_seg), 0.0001)
	assert_eq(world.truck.model.speed, 0.0)


func test_arriving_near_a_city_stamps_it() -> void:
	var t: Dictionary = world.map.town("Ji-Paraná")
	world.truck.position = t.road_pos + Vector2(20, 0)
	await wait_process_frames(2)
	assert_true(SaveStore.passport.has_stamp("Ji-Paraná"))


func _stand_and_shoot(id: String, offset_deg: float) -> PhotoRules.Result:
	var spot: Dictionary = world.spots.filter(func(s): return s.id == id)[0]
	var bearing := deg_to_rad(spot.view_from_deg + offset_deg)
	world.truck.position = spot.pos + Vector2(sin(bearing), -cos(bearing)) * 50.0
	world.truck.get_node("Camera").reset_smoothing()
	await wait_process_frames(2)
	return world.take_photo(world.hud.viewfinder_rect())


func test_photo_from_the_right_side_unlocks_the_sheet() -> void:
	var result: PhotoRules.Result = await _stand_and_shoot("secret_teotonio", 0.0)
	assert_eq(result, PhotoRules.Result.OK)
	assert_true(SaveStore.passport.has_photo("secret_teotonio"))
	assert_true(world.hud._sheet.visible, "the sheet opens on a new photo")
	assert_true(get_tree().paused, "the sheet pauses the game")
	world.hud.close_sheet()
	assert_false(get_tree().paused)


func test_photo_from_the_wrong_side_only_hints() -> void:
	var result: PhotoRules.Result = await _stand_and_shoot("secret_rondon_jiparana", 180.0)
	assert_eq(result, PhotoRules.Result.WRONG_ANGLE)
	assert_false(SaveStore.passport.has_photo("secret_rondon_jiparana"))


func test_tutorial_shows_on_a_fresh_save_and_only_once() -> void:
	SaveStore.flags = {}
	var fresh = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(fresh)
	await wait_process_frames(3)
	assert_true(fresh.hud.is_showing("tutorial"))
	assert_true(get_tree().paused, "the tutorial pauses the game")
	fresh.hud.close_tutorial()
	assert_false(get_tree().paused)
	assert_true(SaveStore.has_flag("tutorial_seen"))


func test_completing_the_passport_shows_the_ending_after_the_last_sheet() -> void:
	for city in world.map.stamp_cities():
		SaveStore.passport.stamp(city)
	var photos: PackedStringArray = world.catalog.ids_in_diorama("efmm")
	photos.append_array(world.catalog.ids_of_kind("secret"))
	for id in photos.slice(0, photos.size() - 1):
		SaveStore.passport.add_photo(id)
	await wait_process_frames(2)
	assert_false(world.hud.is_showing("complete"), "not yet: one photo missing")
	world.hud.open_sheet(photos[-1])            # the last photo's sheet is on screen...
	SaveStore.passport.add_photo(photos[-1])
	await wait_process_frames(2)
	assert_false(world.hud.is_showing("complete"), "...so the ending waits for it")
	world.hud.close_sheet()
	assert_true(world.hud.is_showing("complete"))
	assert_true(SaveStore.has_flag("completion_seen"))
	world.hud._hide_info(world.hud._complete)
	SaveStore.passport.add_photo("anything else")
	assert_true(world.check_complete())
	await wait_process_frames(2)
	assert_false(world.hud.is_showing("complete"), "shown once")
