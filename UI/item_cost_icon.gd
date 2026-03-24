@tool
class_name ItemCostIcon
extends Control




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func initialize(item: InventoryItem, quantity: int) -> void:
	$HBoxContainer/Label.text = str(quantity)
	$HBoxContainer/TextureRect.texture = item.display_icon

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
