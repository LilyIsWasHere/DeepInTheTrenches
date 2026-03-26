extends Node

var players: Dictionary[int, Player]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func register_player(player: Player) -> void:
	players[player.player_id] = player

func get_player(id: int) -> Player:
	return players[id]

func set_active_player(id : int) -> void:
	for i in players.size():
		players[i].set_active(false)
	print("Player ", id, " is active")
	players[id].set_active(true)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("player1"):
		set_active_player(0)
	elif event.is_action_pressed("player2"):
		set_active_player(1)
