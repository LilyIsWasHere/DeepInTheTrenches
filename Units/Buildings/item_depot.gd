

class_name ItemDepot
extends BuildingUnit

@export var pickup: bool = false



func _ready() -> void:
	if (pickup):
		inventory.add_items(load("res://Inventory/InventoryItems/organic_material_item.tres"), 100)
		for i in range(10):
			ItemTransportBlackboard.request_pickup(inventory, load("res://Inventory/InventoryItems/organic_material_item.tres"), 10, ItemTransportRequest.RequestPriority.HIGH)
	else: 
		for i in range(10):
			ItemTransportBlackboard.request_dropoff(inventory, load("res://Inventory/InventoryItems/organic_material_item.tres"), 10, ItemTransportRequest.RequestPriority.HIGH)
