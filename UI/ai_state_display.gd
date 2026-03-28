class_name AIStateDisplay
extends Control

var icon_scene: PackedScene = preload("res://UI/AIStateIcon.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_icons(icons: Array[Texture2D]) -> void:
	for child in $HBoxContainer.get_children():
		child.queue_free()
		
	for icon in icons:
		var icon_inst: TextureRect = icon_scene.instantiate()
		$HBoxContainer.add_child(icon_inst)
		icon_inst.texture = icon
		$"..".render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
		
