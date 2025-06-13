# ledge.gd
# holds information about a detected ledge.
class_name Ledge 

## The starting point of the ledge's center line.
@export var start: Vector3

## The ending point of the ledge's center line.
@export var end: Vector3

## The normal vector of the wall the ledge is attached to.
@export var normal: Vector3

## The distance from the ledge surface to the ground below.
@export var distance_from_ground: float

func get_midpoint() -> Vector3:
	return lerp(start, end, 0.5)    
