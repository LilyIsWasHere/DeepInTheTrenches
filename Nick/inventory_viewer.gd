extends Control

@onready var itemUIPrefab : PackedScene = preload("res://Nick/item_ui.tscn")
@onready var itemDirectory : VBoxContainer = $CanvasLayer/PanelContainer/MarginContainer/ScrollContainer/MarginContainer/VBoxContainer

func _ready() -> void:
	on_close()

func add_item(itemDesc : String, itemTexture : Texture) -> void:
	var item : PanelContainer = itemUIPrefab.instantiate()
	itemDirectory.add_child(item)
	item.itemLabel.text = itemDesc
	item.itemTexture.texture = itemTexture

func on_close() -> void:
	$CanvasLayer.visible = false

func on_open() -> void:
	$CanvasLayer.visible = true

func clear() -> void:
	for i in itemDirectory.get_children().size():
		itemDirectory.get_children()[0].free()
