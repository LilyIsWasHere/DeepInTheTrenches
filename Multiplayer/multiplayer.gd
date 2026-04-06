extends Node

@export var auto_connect: bool = true

const PORT = 4433
var hosting: bool = false
var game_started: bool = false

func _ready() -> void:
	
	# Start paused.
	get_tree().paused = true
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false
	

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		var peer := ENetMultiplayerPeer.new()
		peer.create_server(PORT)
		multiplayer.multiplayer_peer = peer
		
func _process(delta: float) -> void:
	if (!game_started):
		if (multiplayer.get_peers().size() > 0):
			game_started = true
			start_game()

func start_game(local: bool = false) -> void:
	print(multiplayer.get_peers())
	get_tree().paused = false
	$GameScene.visible = true
	
	if (is_multiplayer_authority()):
		$"GameScene/PlayerSpawner".spawn_player(1)
		if (!local): $"GameScene/PlayerSpawner".spawn_player(multiplayer.get_peers().get(0))
		else: $"GameScene/PlayerSpawner".spawn_player(2)
