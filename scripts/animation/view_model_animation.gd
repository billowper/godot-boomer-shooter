# ViewModelAnimation.gd
# Converted from ViewModelAnimation.cs

# This script aggregates various animation controllers for a view model.

class_name ViewModelAnimation
extends Resource # Extend Resource for easier saving/loading in Godot

@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO
@export var bob: SwayController = SwayController.new() # Instance of SwayController for bobbing
@export var lean: ValueLerper = ValueLerper.new() # Instance of ValueLerper for leaning
@export var horizontal_sway: ValueLerper = ValueLerper.new() # Instance of ValueLerper for horizontal sway
@export var vertical_sway: ValueLerper = ValueLerper.new() # Instance of ValueLerper for vertical sway

