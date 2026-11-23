extends GutTest
## Loads the real main scene: start stamp, teleport rules. Swaps in a throwaway
## Passport so the test never writes over the player's save.

var _saved_passport: Passport
var world: Node


func before_each() -> void:
	_saved_passport = SaveStore.passport
	SaveStore.passport = Passport.new()   # not connected to save(): nothing touches disk
	world = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(world)
	await wait_process_frames(3)   # stamping runs in _process, not physics


func after_each() -> void:
	get_tree().paused = false
	SaveStore.passport = _saved_passport


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
