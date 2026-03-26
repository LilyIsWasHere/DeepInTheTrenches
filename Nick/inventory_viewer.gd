extends Control

@onready var itemUIPrefab : PackedScene = preload("res://Nick/item_ui.tscn")
@onready var itemDirectory : VBoxContainer = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/MarginContainer/VBoxContainer
@onready var cursor : Cursor = get_parent()
var units : Array

func _ready() -> void:
	on_close()

func _process(_delta : float) -> void:
	if !(units.is_empty()):
		on_refresh()

func add_item(itemName : String, itemCount : int, itemTexture : Texture) -> void:
	var item : PanelContainer = itemUIPrefab.instantiate()
	itemDirectory.add_child(item)
	item.itemName = itemName
	item.itemAmount = itemCount
	item.itemLabel.text = itemName + " x" + str(itemCount)
	item.itemTexture.texture = itemTexture

func update_item() -> void:
	pass

func set_units(unitArray : Array) -> void:
	units = unitArray

func on_close() -> void:
	$CanvasLayer.visible = false
	units = []

func on_open() -> void:
	$CanvasLayer.visible = true

func on_refresh() -> void:
	cursor.handle_view_specific_inventory(units)

func clear() -> void:
	for i in itemDirectory.get_children().size():
		itemDirectory.get_children()[0].free()
