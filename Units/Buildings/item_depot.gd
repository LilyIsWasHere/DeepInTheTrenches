

class_name ItemDepot
extends BuildingUnit

@export var pickup: bool = false

var organic_item: InventoryItem = preload("res://Inventory/InventoryItems/organic_material_item.tres")
var energy_crystal_item: InventoryItem = preload("res://Inventory/InventoryItems/organic_material_item.tres")

func _ready() -> void:
	for i in range(10):
		ItemTransportBlackboard.request_dropoff(inventory, organic_item, 10, ItemTransportRequest.RequestPriority.LOW, true)
		ItemTransportBlackboard.request_dropoff(inventory, energy_crystal_item, 10, ItemTransportRequest.RequestPriority.LOW, true)
			
		ItemTransportBlackboard.request_pickup(inventory, organic_item, 10, ItemTransportRequest.RequestPriority.HIGH)
		ItemTransportBlackboard.request_pickup(inventory, energy_crystal_item, 10, ItemTransportRequest.RequestPriority.HIGH)
