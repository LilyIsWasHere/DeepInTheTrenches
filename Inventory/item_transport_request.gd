class_name ItemTransportRequest
extends Object

enum RequestPriority {
	TOP = 0,
	HIGH = 1,
	MEDIUM = 2,
	LOW = 3,
	SIZE = 4
}
enum RequestType {
	PICKUP,
	DROPOFF
}

var local: bool = false

var inventory: Inventory:
	get():
		assert(_valid)
		return inventory
		
var item: InventoryItem:
	get():
		assert(_valid)
		return item
		
var quantity: int:
	get():
		assert(_valid)
		return quantity
		
var priority: RequestPriority:
	get():
		assert(_valid)
		return priority
		
var type: RequestType:
	get():
		assert(_valid)
		return type

var _valid: bool = true


func fulfill(fulfilled_quantity: int) -> void:
	assert(_valid)
	if (fulfilled_quantity >= quantity):
		pass
		
	else:
		quantity -= fulfilled_quantity
		match (type):
			RequestType.PICKUP:
				ItemTransportBlackboard._unclaim_pickup_request(self)
			RequestType.DROPOFF:
				ItemTransportBlackboard._unclaim_dropoff_request(self)
				
	# DO NOT TOUCH A REQUEST AFTER FULFULLING IT!
	_valid = false

	
func unclaim() -> void:
	assert(_valid)
	
	match (type):
		RequestType.PICKUP:
			ItemTransportBlackboard._unclaim_pickup_request(self)
		RequestType.DROPOFF:
			ItemTransportBlackboard._unclaim_dropoff_request(self)
	
	_valid = false

func abandon() -> void:
	assert(_valid)
	_valid = false
