extends Node2D

func _on_start_button_down() -> void:
	get_tree().change_scene_to_file("res://base.tscn")

func _on_quit_button_down() -> void:
	get_tree().quit()

func _on_credits_button_down() -> void:
	$CanvasLayer/MainMenu.visible = false
	$CanvasLayer/Credits.visible = true


func _on_back_button_down() -> void:
	$CanvasLayer/Credits.visible = false
	$CanvasLayer/MainMenu.visible = true
