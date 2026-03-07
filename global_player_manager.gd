extends Node


var players: Dictionary[int, Player]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func register_player(player: Player) -> void:
	players[player.player_id] = player

func get_player(id: int) -> Player:
	return players[id]
