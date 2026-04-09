extends Button

func _ready() -> void:
	connect("button_down", return_to_menu)

func return_to_menu() -> void:
	get_tree().change_scene_to_file("res://UI/Title/title.tscn")
