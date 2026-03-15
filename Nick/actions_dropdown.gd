extends Control

@onready var cursor : Node3D = get_parent()
@onready var buttons : Array = $PanelContainer/Options/Buttons.get_children()

func _on_move_button_down() -> void:
	cursor.handle_movement(true)

func _on_attack_button_down() -> void:
	cursor.handle_attack(true)

func _on_dig_button_down() -> void:
	pass # Replace with function body.

func enable_all() -> void:
	for button : Button in buttons:
		button.visible = true

func disable_all() -> void:
	for button : Button in buttons:
		button.visible = false
