extends Unit
class_name MoveableUnit

var move_target_pos : Vector3
var arrived : bool = true
func get_arrived()->bool:
	return arrived

func get_arrived_2D()->bool:
	return Vector2(global_position.x, global_position.z).distance_to(Vector2(move_target_pos.x, move_target_pos.z))

@export var unitSpeed : float = 4
@export var move_safe_config: NavAgentConfig = preload("res://hendry/navigation/agent_configs/follow_trenches_agent_config.tres")
@export var move_direct_config: NavAgentConfig = preload("res://hendry/navigation/agent_configs/move_direct_agent_config.tres")

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
	#var steer_result: NavSteeringResult = Navigation.sample_steering(self, nav_plan_handle, get_physics_process_delta_time(), true)
	var steer_result: NavSteeringResult = Navigation.sample_steering(self, nav_plan_handle, true)
	velocity.x = steer_result.desired_velocity.x
	velocity.z = steer_result.desired_velocity.z
	arrived = steer_result.arrived
	
func move_safe_tick_fn() -> void:
	#TODO: REPLACE THIS WITH NAVIGATION STEERING STUFF
	should_move = true
	var steer_result: NavSteeringResult = Navigation.sample_steering(self, nav_plan_handle, true)
	velocity.x = steer_result.desired_velocity.x
	velocity.z = steer_result.desired_velocity.z
	arrived = steer_result.arrived
	


func set_destination_point_safe(destination: Vector3) -> void:
	nav_plan_handle = Navigation.request_move(self, destination, move_safe_config)
	move_target_pos = destination
	
func set_destination_point_direct(destination: Vector3) -> void:
	nav_plan_handle = Navigation.request_move(self, destination, move_direct_config)
	move_target_pos = destination
	

func debug_movement(delta : float) -> void:
	if global_position.distance_to(move_target_pos) > 0.5:
		global_position = global_position.move_toward(move_target_pos, unitSpeed * delta)
		arrived = false
	elif !arrived:
		arrived = true

func move_to_point(point : Vector3) -> void:
	move_target_pos = point

# TODO: this is where the navigation agent config should be stored 
#func get_nav_agent_config() -> NavAgentConfig:
	#return nav_agent_config
