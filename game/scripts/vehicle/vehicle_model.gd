class_name VehicleModel
extends RefCounted
## Pure driving logic, no nodes: speed and heading from throttle, steering and
## the surface under the wheels. Heading 0 = north (-Y), positive = clockwise.

## Surface speed factors (ADR 0008: potholes and dirt slow you down, never stop you).
const ASPHALT := 1.0
const DIRT := 0.6
const OFFROAD := 0.35
## The speedometer reads this at max_speed on asphalt (the map is compressed, ADR 0003).
const KMH_AT_TOP := 100.0

var max_speed := 120.0      ## px/s on asphalt
var acceleration := 73.0    ## px/s²
var braking := 187.0        ## px/s²
var drag := 40.0            ## px/s² when coasting
var reverse_max := 33.0     ## px/s
var steer_rate := 2.4       ## rad/s at full steering authority

var speed := 0.0            ## px/s, negative when reversing
var heading := 0.0          ## radians


## Advances the model by dt. throttle and steer are in [-1, 1]; negative throttle brakes,
## then reverses once stopped. surface is a speed factor such as ASPHALT or DIRT.
func step(throttle: float, steer: float, dt: float, surface: float = ASPHALT) -> void:
	throttle = clampf(throttle, -1.0, 1.0)
	steer = clampf(steer, -1.0, 1.0)
	var top := max_speed * surface

	if throttle > 0.0:
		if speed < 0.0:
			speed = minf(speed + braking * throttle * dt, 0.0)
		else:
			speed = minf(speed + acceleration * throttle * dt, maxf(top, speed))
	elif throttle < 0.0:
		if speed > 0.0:
			speed = maxf(speed + braking * throttle * dt, 0.0)
		else:
			speed = maxf(speed + acceleration * 0.5 * throttle * dt, -reverse_max * surface)
	else:
		speed = move_toward(speed, 0.0, drag * dt)

	# Entering a slower surface bleeds speed off quickly instead of snapping.
	if speed > top:
		speed = maxf(top, speed - braking * dt)

	# No steering when stopped; full authority from 30% of top speed. Reversing steers inverted
	# naturally because the sign of speed carries through.
	var authority := clampf(speed / (max_speed * 0.3), -1.0, 1.0)
	heading = wrapf(heading + steer * steer_rate * authority * dt, -PI, PI)


## Speedometer reading (ADR 0009): top speed on asphalt shows 100 km/h.
func kmh() -> float:
	return speed / max_speed * KMH_AT_TOP


func forward() -> Vector2:
	return Vector2(sin(heading), -cos(heading))


func velocity() -> Vector2:
	return forward() * speed
