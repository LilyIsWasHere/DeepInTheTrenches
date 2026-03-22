extends Unit
class_name MoveableUnit

var move_target_pos : Vector3
var arrived : bool = true
@export var unitSpeed : float = 4
@export var nav_agent_config: NavAgentConfig

func _ready() -> void:
	super()
	move_target_pos = global_position
	add_to_group("can_move")



func _process(delta: float) -> void:
	#velocity.x = 0
	#velocity.z = 0
	should_move = false
	pass

func move_direct_tick_fn() -> void:
	should_move = true
	var dir: Vector2 = Vector2((move_target_pos - global_position).x, (move_target_pos - global_position).z).normalized()
	var xz_vel: Vector2 = dir * unitSpeed
	velocity.x = xz_vel.x
	velocity.z = xz_vel.y
	
func move_safe_tick_fn() -> void:
	#TODO: REPLACE THIS WITH NAVIGATION STEERING STUFF
	move_direct_tick_fn()

func debug_movement(delta : float) -> void:
	if global_position.distance_to(move_target_pos) > 0.5:
		global_position = global_position.move_toward(move_target_pos, unitSpeed * delta)
		arrived = false
	elif !arrived:
		arrived = true

func move_to_point(point : Vector3) -> void:
	move_target_pos = point

# TODO: this is where the navigation agent config should be stored 
func get_nav_agent_config() -> NavAgentConfig:
	return nav_agent_config
