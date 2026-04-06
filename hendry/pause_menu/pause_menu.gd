extends Control

# quit to title
func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Title/Title.tscn")

func _on_resume_button_pressed() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			hide()
		else:
			show()
