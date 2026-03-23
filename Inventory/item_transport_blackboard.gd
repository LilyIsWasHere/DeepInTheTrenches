extends Node

enum RequestPriority {
	TOP,
	HIGH,
	MEDIUM,
	LOW
}

var pickup_requests: Array[Array]
var dropoff_requests: Array[Array]




func request_pickup(from_inventory: Inventory, item: InventoryItem, qty: int, priority: RequestPriority) -> void:
	pass
	
	
func request_dropoff(to_inventory: Inventory, item: InventoryItem, qty: int, priority: RequestPriority) -> void:
	pass


func claim_pickup_request(request: ItemTransportRequest, pickup_qty: int) -> void:
	#if pickup_qty >= request.quantity:
	pass
	
func claim_dropoff_request(request: ItemTransportRequest, pickup_qty: int) -> void:
	pass
