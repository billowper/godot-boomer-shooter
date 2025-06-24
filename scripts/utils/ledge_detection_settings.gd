# ledge_detection_settings.gd
# A resource that holds all the configuration for the ledge detection algorithm.
# You can create and save this resource in the Inspector to easily manage different settings.
@tool
class_name LedgeDetectionSettings extends Resource

## The minimum width a ledge must have to be considered valid.
@export var min_ledge_width: float = 1.0

## The maximum number of steps to take up a wall when searching for a surface.
@export var max_surface_raycast_steps: int = 5

## The distance to move up the wall for each step.
@export var max_surface_raycast_step_interval: float = 2.0

## A ledge must be at least this far from the ground to be valid.
@export var min_distance_to_ground: float = 2.0

## The vertical space required above the ledge for a character to stand.
@export var clearance_height: float = 4.0

## The width and depth of the box used to check for clearance obstructions.
@export var obstruction_check_size: float = 0.5

## The physics layers that are considered obstructions for the clearance check.
@export_flags_3d_physics var obstruction_layers: int = 1
