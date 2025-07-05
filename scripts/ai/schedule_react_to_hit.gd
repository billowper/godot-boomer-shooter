class_name Schedule_ReactToHit
extends AI_Schedule

var target_pos: Vector3

func _init(sound: AudioStream) -> void:
    var pos_getter = func() -> Vector3: 
        return target_pos		
    add_action(PlaySound.new(sound))
    add_action(LookInDirection.new(pos_getter, 0))
    add_action(AnimOneShot.new("on_hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE))
    super._init("React To Hit")
