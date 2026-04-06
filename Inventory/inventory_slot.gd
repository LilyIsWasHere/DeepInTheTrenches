@tool
class_name InventorySlot
extends Node # or Object? Or Node?



@export var item: InventoryItem:
	set(value):
		if (Engine.is_editor_hint()):
			name = value.name + " Slot"
		item = value
	get:
		return item
		
@export var num: int
@export var max_num: int


func _init() -> void:
	item = null
	num = 0
	max_num = 1


#func add_quantity(quantity: int)
