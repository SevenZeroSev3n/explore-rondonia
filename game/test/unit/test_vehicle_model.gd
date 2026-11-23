extends GutTest

const DT := 1.0 / 60.0


func _drive(m: VehicleModel, throttle: float, steer: float, seconds: float, surface := VehicleModel.ASPHALT) -> void:
	for i in int(seconds / DT):
		m.step(throttle, steer, DT, surface)


func test_starts_still_facing_north() -> void:
	var m := VehicleModel.new()
	assert_eq(m.speed, 0.0)
	assert_almost_eq(m.forward(), Vector2(0, -1), Vector2(0.0001, 0.0001))


func test_accelerates_up_to_top_speed_on_asphalt() -> void:
	var m := VehicleModel.new()
	_drive(m, 1.0, 0.0, 10.0)
	assert_almost_eq(m.speed, m.max_speed, 0.01)
	assert_lt(m.velocity().y, 0.0, "full throttle from rest drives north")


func test_dirt_and_offroad_cap_speed_lower() -> void:
	var dirt := VehicleModel.new()
	_drive(dirt, 1.0, 0.0, 10.0, VehicleModel.DIRT)
	var off := VehicleModel.new()
	_drive(off, 1.0, 0.0, 10.0, VehicleModel.OFFROAD)
	assert_almost_eq(dirt.speed, dirt.max_speed * VehicleModel.DIRT, 0.01)
	assert_almost_eq(off.speed, off.max_speed * VehicleModel.OFFROAD, 0.01)
	assert_gt(off.speed, 0.0, "off-road slows the truck but never stops it")


func test_leaving_asphalt_bleeds_speed_gradually() -> void:
	var m := VehicleModel.new()
	_drive(m, 1.0, 0.0, 10.0)
	m.step(1.0, 0.0, DT, VehicleModel.OFFROAD)
	assert_gt(m.speed, m.max_speed * VehicleModel.OFFROAD, "no instant snap down")
	assert_lt(m.speed, m.max_speed)


func test_coasting_comes_to_a_stop() -> void:
	var m := VehicleModel.new()
	_drive(m, 1.0, 0.0, 2.0)
	_drive(m, 0.0, 0.0, 10.0)
	assert_eq(m.speed, 0.0)


func test_brake_stops_then_reverses_slowly() -> void:
	var m := VehicleModel.new()
	_drive(m, 1.0, 0.0, 2.0)
	_drive(m, -1.0, 0.0, 10.0)
	assert_almost_eq(m.speed, -m.reverse_max, 0.01)


func test_cannot_turn_while_stopped() -> void:
	var m := VehicleModel.new()
	_drive(m, 0.0, 1.0, 1.0)
	assert_eq(m.heading, 0.0)


func test_steering_right_turns_clockwise_towards_east() -> void:
	var m := VehicleModel.new()
	_drive(m, 1.0, 0.0, 3.0)
	_drive(m, 1.0, 1.0, 0.3)
	assert_gt(m.heading, 0.0)
	assert_gt(m.velocity().x, 0.0, "turning right while heading north moves east")


func test_heading_stays_wrapped() -> void:
	var m := VehicleModel.new()
	_drive(m, 1.0, 1.0, 30.0)
	assert_between(m.heading, -PI, PI)


func test_inputs_are_clamped() -> void:
	var a := VehicleModel.new()
	var b := VehicleModel.new()
	a.step(5.0, 0.0, DT)
	b.step(1.0, 0.0, DT)
	assert_eq(a.speed, b.speed)
