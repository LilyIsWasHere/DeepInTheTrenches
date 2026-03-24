class_name BuildingUnit
extends Unit


var is_constructed: bool = false

@export var resource_requirements: Dictionary[InventoryItem, int]
@export var under_construction_material: Material


func _ready() -> void:
	_set_materials_under_construction()
	
	
	

func _process(delta: float) -> void:
	if (is_constructed == false && are_construction_resource_requirements_met()):
		is_constructed = true
		
	
func are_construction_resource_requirements_met() -> bool:
	
	if resource_requirements.is_empty():
		return true
		
	for item: InventoryItem in resource_requirements.keys():
		var req_qty: int = resource_requirements[item]
		
		if (inventory.get_item_quantity(item) > req_qty):
			return true
			
	return false

# override me to set all the materials in this building
func _set_materials_under_construction() -> void:
	pass
	
# override me to set all the materials in this building
func _set_materials_constructed() -> void:
	pass
