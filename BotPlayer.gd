extends Player


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CameraScene = load("res://BotPlayerCamera.tscn")
	super()
	process_input = false
	
