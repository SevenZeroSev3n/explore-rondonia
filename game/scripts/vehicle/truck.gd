class_name Truck
extends CharacterBody2D
## The player's pickup on the state map (layer 1). Physics stays in float
## coordinates; only the drawn stack snaps to whole pixels to avoid shimmer.

## Returns the surface speed factor at a world position. Set by the world.
var surface_provider: Callable = func(_pos: Vector2) -> float: return VehicleModel.ASPHALT
## Returns false where the truck may not go (outside the state, ADR 0002). Set by the world.
var bounds_provider: Callable = func(_pos: Vector2) -> bool: return true
var model := VehicleModel.new()
## False when the tank is empty (ADR 0009): the truck coasts to a stop and waits for the tow.
var engine_on := true

@onready var stack: SpriteStack = $Stack


func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	if not engine_on:
		throttle = minf(throttle, 0.0) if model.speed > 0.0 else 0.0
	var steer := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	model.step(throttle, steer, delta, surface_provider.call(global_position))
	var before := global_position
	velocity = model.velocity()
	if move_and_slide():
		# Hitting something kills most of the speed instead of grinding along it.
		model.speed *= 0.5
	if not bounds_provider.call(global_position):
		global_position = before
		model.speed = 0.0


func _process(_delta: float) -> void:
	stack.angle = model.heading
	stack.position = global_position.round() - global_position
