extends Resource # or Object? Or Node?
class_name InventorySlot


@export var item: InventoryItem # A set of these are already created, exist in file system 
@export var num: int
@export var max_num: int


func _init() -> void:
	item = null
	num = 0
	max_num = 1


#func add_quantity(quantity: int)
