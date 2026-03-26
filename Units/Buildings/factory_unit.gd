class_name FactoryUnit
extends BuildingUnit

@export var output_item: InventoryItem
@export var output_stockpile_size: int

@export var output_batch_size: int
@export var input_ingredients: Dictionary[InventoryItem, int]




func _ready() -> void:
	super()
	
	inventory.add_slot(output_item, 9999)
	
	for item: InventoryItem in input_ingredients.keys():
		inventory.add_slot(item, 9999)
		
		
func _process(delta: float) -> void:
	pass
	
	
		
	
