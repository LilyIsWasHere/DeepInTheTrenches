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

var enemy_overlay_mat: Material = preload("res://materials/enemy_overlay_material.tres")

var should_move: bool = false

var selectedArrowPrefab : PackedScene = preload("res://Nick/selected_arrow.tscn")
var selectedArrow : Sprite3D
@export var selectedArrowOffset : float = 2.75

@export var team: int = 0:
	set(value):
		LineOfSightManager.unregister_unit(self)
	
		team = value
		LineOfSightManager.register_unit(self, team)
		
		#put on selectable layer
		selectableArea.collision_layer = 2
		
		if (team == 0):
			BodyMesh.material_override.albedo_color = Color(0.2, 1, 0.2)
		else:
			BodyMesh.material_override.albedo_color = Color(1, 0.2, 0.2)

@export var velocity: Vector3 = Vector3(0.0, 0.0, 0.0)

var slope_normal: Vector3 = Vector3(0.0, 1.0, 0.0)
var on_floor: bool = false

func is_selected(isSelected : bool) -> void:
	selectedArrow.visible = isSelected

func get_all_children(in_node: Node,arr: Array[Node] = []) -> Array[Node]:
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr

func _init() -> void:
	ai_controller = AIController.new()
	resource_extractor = ResourceExtractor.new()
	sync_to_physics = false
	
	selectedArrow = selectedArrowPrefab.instantiate()
	add_child(selectedArrow)
	selectedArrow.visible = false
	selectedArrow.position = Vector3(0, selectedArrowOffset, 0)

func _ready() -> void:
	add_child(ai_controller)
	add_child(resource_extractor)
	
	resource_extractor.inventory_connection = inventory
	
	if (team == 0):
		pass
	else:
		var children: Array[Node] = get_all_children(self)
		for child in children:
			if child.is_class("MeshInstance3D"):
				child.material_overlay = enemy_overlay_mat
	
	LineOfSightManager.register_unit(self, team)

func _physics_process(delta: float) -> void:
	if !on_floor:
		velocity += get_gravity() * delta
		
	move_along_terrain()

func get_slope_velocity_multiplier(normal: Vector3, vel_dir: Vector3) -> float:
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
		visible = false
		$PrimaryMesh.material_override.albedo_color.a = 0.35
	else:
		visible = true
		$PrimaryMesh.material_override.albedo_color.a = 1
