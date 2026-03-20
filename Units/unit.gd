extends AnimatableBody3D
class_name Unit

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var LineOfSightTarget: Node3D
@export var BodyMesh: MeshInstance3D
@export var inventory: Inventory
@export var selectableArea : Area3D
var ai_controller: AIController
var resource_extractor: ResourceExtractor

var should_move: bool = false

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

@export var velocity: Vector3 = Vector3(0.0, 0.0, 0.0)

var slope_normal: Vector3 = Vector3(0.0, 1.0, 0.0)
var on_floor: bool = false


func _init() -> void:
	ai_controller = AIController.new()
	resource_extractor = ResourceExtractor.new()

func _ready() -> void:
	add_child(ai_controller)
	add_child(resource_extractor)
	
	if (team == 0):
		$MeshInstance3D.material_override.albedo_color = Color(0.2, 1, 0.2)
	else:
		$MeshInstance3D.material_override.albedo_color = Color(1, 0.2, 0.2)
	
	LineOfSightManager.register_unit(self, team)

func _physics_process(delta: float) -> void:
	if !on_floor:
		velocity += get_gravity() * delta
		
	move_along_terrain()

func get_slope_velocity_multiplier(_normal: Vector3, _vel_dir: Vector3) -> float:
	if (!on_floor): 
		return 1.0
		
	return 1.0

func move_along_terrain() -> void:
	var delta: float = get_physics_process_delta_time()
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var future_pos: Vector3 = global_position + velocity * delta * get_slope_velocity_multiplier(slope_normal, velocity.normalized())
	if (!should_move): future_pos = global_position + (velocity * Vector3(0, 1, 0)) * delta * get_slope_velocity_multiplier(slope_normal, velocity.normalized())
	
	var neg_offset: float = 1.0 + velocity.y * delta
	var query := PhysicsRayQueryParameters3D.create(Vector3(future_pos.x, global_position.y + 5.0, future_pos.z), Vector3(future_pos.x, global_position.y - neg_offset, future_pos.z))
	var result: Dictionary = space_state.intersect_ray(query)
	
	if(result.is_empty()):
		global_position = future_pos
		on_floor = false
		
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
