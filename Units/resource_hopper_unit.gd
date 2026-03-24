class_name ResourceHopperUnit
extends BuildingUnit

@export var can_give_items: bool = true
@export var can_take_items: bool = true

func get_relevant_items() -> Array[InventoryItem]:
	return inventory.item_slot_dict.keys()
