extends AnimatableBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var velocity: Vector3 = Vector3(1.0, 0.0, 1.0)

var slope_normal: Vector3 = Vector3(0.0, 1.0, 0.0)
var on_floor: bool = false

func _physics_process(delta: float) -> void:
	if !on_floor:
		velocity += get_gravity() * delta


	move_along_terrain(delta)

func get_slope_velocity_multiplier(normal: Vector3, vel_dir: Vector3) -> float:
	if (!on_floor):
		return 1.0
		
	return 1.0

func move_along_terrain(delta: float) -> void:
	
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var future_pos: Vector3 = global_position + velocity * delta * get_slope_velocity_multiplier(slope_normal, velocity.normalized())
	
	
	var neg_offset: float = 1.0 + velocity.y * delta
	var query := PhysicsRayQueryParameters3D.create(Vector3(future_pos.x, global_position.y + 5.0, future_pos.z), Vector3(future_pos.x, global_position.y - neg_offset, future_pos.z))
	var result: Dictionary = space_state.intersect_ray(query)
	
	if(result.is_empty()):
		global_position = future_pos
		
	else:
		global_position = result["position"]
		slope_normal = result["normal"]
		velocity.y = 0.0
		on_floor = true
	
	
		
		
		
		
		
		
		
