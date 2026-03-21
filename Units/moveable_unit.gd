extends Unit
class_name MoveableUnit

var move_target_pos : Vector3
var arrived : bool = true
func get_arrived()->bool:
	return arrived

@export var unitSpeed : float = 4

var nav_plan_handle: NavPlanHandle

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
	should_move = true
	var steer_result: NavSteeringResult = Navigation.sample_steering(self, nav_plan_handle, get_physics_process_delta_time())
	velocity.x = steer_result.desired_velocity.x
	velocity.z = steer_result.desired_velocity.z
	arrived = steer_result.arrived
	


func set_destination_point(destination: Vector3, safe_or_direct: Navigation.NavProfileId = Navigation.NavProfileId.SAFE) -> void:
	nav_plan_handle = Navigation.request_move(self, team, destination, safe_or_direct)
	move_target_pos = destination

func debug_movement(delta : float) -> void:
	if global_position.distance_to(move_target_pos) > 0.5:
		global_position = global_position.move_toward(move_target_pos, unitSpeed * delta)
		arrived = false
	elif !arrived:
		arrived = true

func move_to_point(point : Vector3) -> void:
	move_target_pos = point
