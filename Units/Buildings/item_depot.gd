class_name ItemDepot
extends BuildingUnit

@export var pickup: bool = false

var organic_item: InventoryItem = preload("res://Inventory/InventoryItems/organic_material_item.tres")
var energy_crystal_item: InventoryItem = preload("res://Inventory/InventoryItems/energy_crystal_item.tres")

func _ready() -> void:
	super()
	
	
func _process(_delta: float) -> void:
	super(_delta)
	if (is_constructed && is_placed):
		for item: InventoryItem in inventory.item_slot_dict.keys():
			ItemTransportBlackboard.request_dropoff(inventory, item, inventory.item_slot_dict[item].max_num, ItemTransportRequest.RequestPriority.LOW, true, true)
			ItemTransportBlackboard.request_pickup(inventory, item, inventory.item_slot_dict[item].max_num, ItemTransportRequest.RequestPriority.MEDIUM, true, true)
		
		
