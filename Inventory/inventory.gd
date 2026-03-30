extends Node3D
class_name Inventory

@export var slots: Array[InventorySlot]

var item_slot_dict: Dictionary[InventoryItem, InventorySlot] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for slot in slots:
		item_slot_dict[slot.item] = slot
 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	

static func transfer_items(from_inventory: Inventory, to_inventory: Inventory, item: InventoryItem, quantity: int) -> Dictionary:
	assert(from_inventory.has_slot_for_item(item))
	assert(to_inventory.has_slot_for_item(item))
	var from_underflow: int = from_inventory.remove_items(item, quantity)
	var to_overflow: int = to_inventory.add_items(item, quantity - from_underflow)
	
	from_inventory.add_items(item, to_overflow)
	
	return {"from_underflow": from_underflow, "to_overflow": to_overflow}
	
	
	
func add_slot(item: InventoryItem, max_quantity: int) -> void:
	var slot: InventorySlot = InventorySlot.new()
	slot.item = item
	slot.num = 0
	slot.max_num = max_quantity
	slots.append(slot)
	item_slot_dict.set(item, slot)
	
# adds the specified quantity of the item to the relevant inventory slot, returning any overflow above slot max_quantity
# returns -1 if the inventory lacks a slot for the specified item type, or the quantity < 0
func add_items(item: InventoryItem, quantity: int) -> int:
	var slot: InventorySlot = item_slot_dict.get(item)

	if (slot == null || quantity < 0):
		return -1
		
	slot.num += quantity

	var overflow: int = slot.num - slot.max_num
	if overflow < 0: overflow = 0
	slot.num = min(slot.num, slot.max_num)
	
	return overflow
	
# removes the specified quantity of the item from the relevant inventory slot, returning any underflow below zero (positive value)
# returns -1 if the inventory lacks a slot for the specified item type, or the quantity < 0
func remove_items(item: InventoryItem, quantity: int) -> int:
	
	var slot: InventorySlot = item_slot_dict.get(item)
	
	if (slot == null || quantity < 0):
		return -1

	slot.num -= quantity
	var underflow: int = abs(slot.num) if slot.num < 0 else 0
	slot.num = max(slot.num, 0)
	
	return underflow
	
# returns -1 if the inventory lacks a slot for the specified item type
func get_item_quantity(item: InventoryItem) -> int:
	var slot: InventorySlot = item_slot_dict.get(item)
	
	if (slot == null):
		return -1
		
	return slot.num
	
func get_max_item_quantity(item: InventoryItem) -> int:
	var slot: InventorySlot = item_slot_dict.get(item)
	
	if (slot == null):
		return -1
		
	return slot.max_num
	
# returns true if slot does not exist
func is_item_slot_full(item: InventoryItem) -> bool:
	var slot: InventorySlot = item_slot_dict.get(item)
	
	if (slot == null):
		return true
		
	return slot.num >= slot.max_num

func has_item(item: InventoryItem) -> bool:
	var slot: InventorySlot = item_slot_dict.get(item)
	
	if (slot == null):
		return false
		
	return slot.num > 0
	
func has_slot_for_item(item: InventoryItem) -> bool:
	var slot: InventorySlot = item_slot_dict.get(item)
	return (slot != null)


	
	
