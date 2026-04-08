class_name BuildingUnit
extends Unit


@export var is_constructed: bool = false
@export var is_placed: bool = false


@export var construction_inventory: Inventory
var under_construction_material: Material = preload("res://materials/building_under_construction_material.tres")


var original_materials: Dictionary[Node, Material] = {}

func _init() -> void:
	super()

func _ready() -> void:
	super()
	
	_unset_team_overlay_materials()


func initialize_building(construction_cost: Dictionary[InventoryItem, int]) -> void:
	
	print("initializing")
	#print("Initializing building on session " + str(multiplayer.get_unique_id()))
	
	is_placed = false
	ai_controller.process_mode = Node.PROCESS_MODE_DISABLED
	is_constructed = false
	
	for item: InventoryItem in construction_cost.keys():
		construction_inventory.add_slot(item, construction_cost.get(item))
	
	_set_materials_under_construction()
	_set_materials_under_construction.rpc()
		

	
	
func _input(event: InputEvent) -> void:
	
	if (event.is_action("RotateBuildingCW") && !is_placed):
		self.rotate_y(deg_to_rad(10))
		
	if (event.is_action("RotateBuildingCCW") && !is_placed):
		self.rotate_y(deg_to_rad(-10))
	
	if (event.is_action_pressed("PlaceBuilding") && !is_placed):
		is_placed = true
		on_placed()
	
func _process(_delta: float) -> void:	
	
	if (is_placed == true && is_constructed == false && are_construction_resource_requirements_met()):
		is_constructed = true
		_set_materials_constructed()
		for item: InventoryItem in construction_inventory.item_slot_dict.keys():
			construction_inventory.remove_items(item, construction_inventory.get_item_quantity(item))

func _physics_process(delta: float) -> void:
	super(delta)
		
	if (!is_multiplayer_authority()):
		return
		
	if (!is_placed):
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = GlobalPlayerManager.get_player(team).Camera
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * 3000
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		
		
		query.collision_mask = 	pow(2, 1-1)
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		
		if (!result): return	
		
		global_position = result["position"]
	


func are_construction_resource_requirements_met() -> bool:
	
	for item: InventoryItem in construction_inventory.item_slot_dict.keys():
		
		if (!construction_inventory.is_item_slot_full(item)):
			return false
	
	return true

func get_all_children(in_node: Node,arr: Array[Node] = []) -> Array[Node]:
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr

# override me to set all the materials in this building
@rpc("call_remote", "any_peer", "reliable") func _set_materials_under_construction() -> void:
	var children: Array[Node] = get_all_children(self)
	var m: MeshInstance3D
	for child in children:
		if child.has_method("set_surface_override_material"):
			original_materials.set(child, child.get_surface_override_material(0))
			child.set_surface_override_material(0, under_construction_material)
	
# override me to set all the materials in this building
func _set_materials_constructed() -> void:
	_set_team_overlay_materials()
	var children: Array[Node] = get_all_children(self)
	for child in children:
		if child.has_method("set_surface_override_material"):
			child.set_surface_override_material(0, original_materials.get(child))
	
func on_placed() -> void:
	ai_controller.process_mode = Node.PROCESS_MODE_INHERIT
	for item: InventoryItem in construction_inventory.item_slot_dict.keys():
		ItemTransportBlackboard.request_dropoff(construction_inventory, item, construction_inventory.item_slot_dict[item].max_num, ItemTransportRequest.RequestPriority.TOP)
