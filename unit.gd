extends AnimatableBody3D
class_name Unit

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var LineOfSightTarget: Node3D
@export var BodyMesh: MeshInstance3D
@export var inventory: Inventory
@export var selectableArea : Area3D
@export var weapon : Node3D

@export var team: int = 0:
	set(value):
		LineOfSightManager.unregister_unit(self)
	
		team = value
		LineOfSightManager.register_unit(self, team)
		
		
		if (team == 0):
			BodyMesh.material_override.albedo_color = Color(0.2, 1, 0.2)
			selectableArea.collision_layer = 2
		else:
			BodyMesh.material_override.albedo_color = Color(1, 0.2, 0.2)
			selectableArea.process_mode = Node.PROCESS_MODE_DISABLED

@export var velocity: Vector3 = Vector3(1.0, 0.0, 1.0)

var slope_normal: Vector3 = Vector3(0.0, 1.0, 0.0)
var on_floor: bool = false

var targetPos : Vector3
var arrived : bool = false
@export var unitSpeed : float = 10.5

func _ready() -> void:
	if (team == 0):
		$MeshInstance3D.material_override.albedo_color = Color(0.2, 1, 0.2)
	else:
		$MeshInstance3D.material_override.albedo_color = Color(1, 0.2, 0.2)
	
	LineOfSightManager.register_unit(self, team)

func _physics_process(delta: float) -> void:
	if !on_floor:
		velocity += get_gravity() * delta
	
	move_along_terrain(delta)
	
	debug_movement(delta)

func debug_movement(delta : float) -> void:
	if global_position.distance_to(targetPos) > 0.5:
		global_position = global_position.move_toward(targetPos, unitSpeed * delta)
		arrived = false
	elif !arrived:
		print("arrived!")
		arrived = true

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

func set_hidden(hidden: bool) -> void:
	if (hidden):
		$MeshInstance3D.material_override.albedo_color.a = 0.35
	else:
		$MeshInstance3D.material_override.albedo_color.a = 1

func move_to_point(point : Vector3) -> void:
	targetPos = point

func shoot_to_point(point : Vector3) -> void:
	weapon.shoot(point)
