class_name PlayerSpawner
extends MultiplayerSpawner

var next_player_id: int = 0


const WARN_MSG := "Tried to remove a player that doesn't exist."
var player_scene_path: String = "res://Player.tscn"
var bot_player_scene_path: String = "res://BotPlayer.tscn"

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
	return spawn([id, player_scene_path])
	
func spawn_bot_player() -> Player:
	return spawn ([1, bot_player_scene_path])

func _spawn_player_func(data: Array) -> Player:
	var id: int = data[0]
	var scene_path: String = data[1]
	var scene: PackedScene = load(scene_path)
	var player: Player = scene.instantiate()
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
		
