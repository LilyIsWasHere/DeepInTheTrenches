extends Unit
class_name MoveableUnit

var targetPos : Vector3
var arrived : bool = true
@export var unitSpeed : float = 10.5

func _ready() -> void:
	super()
	targetPos = global_position

func _physics_process(delta: float) -> void:
	super(delta)
	debug_movement(delta)

func debug_movement(delta : float) -> void:
	if global_position.distance_to(targetPos) > 0.5:
		global_position = global_position.move_toward(targetPos, unitSpeed * delta)
		arrived = false
	elif !arrived:
		arrived = true

func move_to_point(point : Vector3) -> void:
	targetPos = point
