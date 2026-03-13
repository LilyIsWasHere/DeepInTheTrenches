extends Control

@onready var cursor : Node3D = get_parent()

func _on_move_button_down() -> void:
	cursor.handle_movement(true)

func _on_attack_button_down() -> void:
	pass # Replace with function body.

func _on_dig_button_down() -> void:
	pass # Replace with function body.
