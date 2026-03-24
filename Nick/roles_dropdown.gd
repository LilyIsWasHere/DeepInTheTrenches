extends Control

@onready var cursor : Node3D = get_parent()
@onready var buttons : Array = $PanelContainer/Options/Buttons.get_children()


func on_patrol_button() -> void:
	cursor.handle_patrol_role()

func on_excavate_button() -> void:
	cursor.handle_on_excavate_role()

func on_transport_role() -> void:
	cursor.handle_on_transport_role()

func enable_all() -> void:
	for button : Button in buttons:
		button.visible = true

func disable_all() -> void:
	for button : Button in buttons:
		button.visible = false

func disable_button(buttonName : String) -> void:
	match buttonName:
		"patrol":
			buttons[0].hide()
		"excavate":
			buttons[1].hide()
		"transport":
			buttons[2].hide()
