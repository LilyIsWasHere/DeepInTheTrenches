class_name PlayerSpawner
extends MultiplayerSpawner

var next_player_id: int = 0


const WARN_MSG := "Tried to remove a player that doesn't exist."
@onready var player_scene: PackedScene = preload("res://Player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MultiplayerSpawnerManager.player_spawner = self
	
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	spawn_function = _spawn_player_func

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_peer_connected(peer_id: int) -> void:
	if is_multiplayer_authority():
		var result := spawn(peer_id)
		print(result)

func _on_peer_disconnected(peer_id: int) -> void:
	if is_multiplayer_authority():
		remove_player(peer_id)

func spawn_player(id: int) -> Player:
	return spawn(id)

func _spawn_player_func(id: int) -> Player:
	var player: Player = player_scene.instantiate()
	player.set_multiplayer_authority(id, true)
	player.name = "Player_" + str(next_player_id)
	player.player_id = next_player_id
	player.terrain = $"../Terrain"
	player.owner = self
	
	next_player_id += 1
	return player
	

func remove_player(id: int) -> void:
	var player: Player = find_child(str(id))
	if player:
		player.queue_free()
	else:
		push_warning(WARN_MSG)
		
