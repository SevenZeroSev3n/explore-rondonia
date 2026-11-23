class_name Truck
extends CharacterBody2D
## The player's pickup on the state map (layer 1). Physics stays in float
## coordinates; only the drawn stack snaps to whole pixels to avoid shimmer.

## Returns the surface speed factor at a world position. Set by the world.
var surface_provider: Callable = func(_pos: Vector2) -> float: return VehicleModel.ASPHALT
var model := VehicleModel.new()

@onready var stack: SpriteStack = $Stack


func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	model.step(throttle, steer, delta, surface_provider.call(global_position))
	velocity = model.velocity()
	if move_and_slide():
		# Hitting something kills most of the speed instead of grinding along it.
		model.speed *= 0.5


func _process(_delta: float) -> void:
	stack.angle = model.heading
	stack.position = global_position.round() - global_position
