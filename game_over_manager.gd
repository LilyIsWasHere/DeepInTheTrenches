extends Node3D

@export var loseScreen : Node3D
@export var winScreen : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loseScreen.get_child(0).get_child(0).hide()
	winScreen.get_child(0).get_child(0).hide()
	LineOfSightManager.connect("gameOver", toggle_game_over)

func toggle_game_over(hasWon : bool) -> void:
	if hasWon:
		winScreen.get_child(0).get_child(0).show()
	else:
		loseScreen.get_child(0).get_child(0).show()
