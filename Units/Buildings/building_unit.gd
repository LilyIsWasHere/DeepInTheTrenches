class_name BuildingUnit
extends Unit


var is_constructed: bool = false
@export var is_placed: bool = false


@export var construction_inventory: Inventory
@export var under_construction_material: Material


func _ready() -> void:
	
	if (construction_inventory == null):
		is_constructed = true
	else:
		is_constructed = false
		_set_materials_under_construction()

	
	
func _input(event: InputEvent) -> void:
	
	if (event.is_action("RotateBuildingCW") && !is_placed):
		self.rotate_y(deg_to_rad(10))
		
	if (event.is_action("RotateBuildingCCW") && !is_placed):
		self.rotate_y(deg_to_rad(-10))
	
	if (event.is_action_pressed("PlaceBuilding") && !is_placed):
		is_placed = true
		on_placed()
	
func _process(delta: float) -> void:	
	
	if (is_constructed == false && are_construction_resource_requirements_met()):
		is_constructed = true

func _physics_process(delta: float) -> void:
	super(delta)
		
	if (!is_placed):
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = GlobalPlayerManager.get_player(team).Camera
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * 3000
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		
		
		query.collision_mask = 	(1 << 1 - 1)
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		
		if (!result): return	
		
		global_position = result["position"]
	
	
func are_construction_resource_requirements_met() -> bool:
	
	if construction_inventory == null:
		return true
		
	for item: InventoryItem in construction_inventory.item_slot_dict.keys():
		
		if (!construction_inventory.is_item_slot_full(item)):
			return false
	
	return true


# override me to set all the materials in this building
func _set_materials_under_construction() -> void:
	pass
	
# override me to set all the materials in this building
func _set_materials_constructed() -> void:
	pass
	
func on_placed() -> void:
	pass
