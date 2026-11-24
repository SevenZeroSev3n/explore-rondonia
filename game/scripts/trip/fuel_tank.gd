class_name FuelTank
extends RefCounted
## The truck's tank, measured in km of driving (ADR 0009). Fuel burns with distance,
## never with time, and refills for free at petrol stations.

var capacity_km := 250.0
var level_km := 250.0


func _init(capacity: float = 250.0) -> void:
	capacity_km = capacity
	level_km = capacity


func burn_km(km: float) -> void:
	level_km = maxf(0.0, level_km - maxf(km, 0.0))


func fill_step(dt: float, km_per_second: float) -> void:
	level_km = minf(capacity_km, level_km + km_per_second * dt)


func fill() -> void:
	level_km = capacity_km


func fraction() -> float:
	return level_km / capacity_km if capacity_km > 0.0 else 0.0


func is_empty() -> bool:
	return level_km <= 0.0


func is_full() -> bool:
	return level_km >= capacity_km
