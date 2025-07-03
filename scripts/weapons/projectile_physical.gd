class_name ProjectilePhysical
extends ProjectileType

@export var force: float = 10.0
@export var gravity_scale: float = 1.0
@export var initial_speed: float = 10.0
@export var max_speed: float = 100.0
@export var life_time: float = 5.0
@export var mass: float = 1.0
@export var friction: float = 1.0
@export var bounce: float = 0.0
@export var model: Resource = null

func create(
    origin: Vector3,
    direction: Vector3,
    owner: Actor
) -> void:
    var projectile_instance = model.instantiate() as Node3D
    projectile_instance.global_transform.origin = origin
    projectile_instance.global_transform.basis = Basis().looking_at(direction, Vector3.UP)
    
    var body = projectile_instance.get_node("Body")
    body.mass = mass
    body.friction = friction
    body.bounce = bounce
    body.linear_velocity = direction.normalized() * initial_speed
    
    owner.get_tree().root.add_child(projectile_instance)
    
    # Set up the life timer for the projectile
    var timer = Timer.new()
    timer.wait_time = life_time
    timer.one_shot = true
    timer.connect("timeout", projectile_instance)
    owner.add_child(timer)
    timer.start()
