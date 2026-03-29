extends Control

@onready var cursor : Node3D = get_parent().get_parent()
@onready var buttons : Array = $PanelContainer/Options/Buttons.get_children()

func _on_move_safe_button_down() -> void:
	cursor.handle_movement(true, "safe")

func _on_move_direct_button_down() -> void:
	cursor.handle_movement(true, "direct")

func _on_attack_button_down() -> void:
	cursor.handle_attack(true)

func on_view_inventory_down() -> void:
	cursor.handle_view_inventory()

func on_operate_button_down() -> void:
	cursor.handle_operate()

func _on_dig_button_down() -> void:
	pass # Replace with function body.

func enable_all() -> void:
	for button : Button in buttons:
		button.visible = true

func disable_all() -> void:
	for button : Button in buttons:
		button.visible = false

func disable_button(buttonName : String) -> void:
	match buttonName:
		"move":
			buttons[0].hide()
			buttons[1].hide()
		"attack":
			buttons[2].hide()
		"operate":
			buttons[3].hide()
		"dig":
			buttons[4].hide()
