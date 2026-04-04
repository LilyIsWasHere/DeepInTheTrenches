extends Node

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
		_on_host_pressed.call_deferred()
		


func _process(delta: float) -> void:
	if (!game_started):
		if (multiplayer.get_peers().size() > 0):
			game_started = true
			start_game()
		


func _on_host_pressed() -> void:
	# Start as server.
	print("Hosting")
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	
	hosting = true
	$CanvasLayer/UI/Net/Optitons.visible = false
	$CanvasLayer/UI/Net/Hosting.visible = true
	


func _on_connect_pressed() -> void:
	print("Connecting")
	# Start as client.
	var txt : String = $CanvasLayer/UI/Net/Optitons/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer


func start_game() -> void:
	print(multiplayer.get_peers())
	# Hide the UI and unpause to start the game.
	$CanvasLayer/UI.hide()
	get_tree().paused = false
	$GameScene.visible = true
	
	if (is_multiplayer_authority()):
		$"GameScene/PlayerSpawner".spawn_player(1)
		$"GameScene/PlayerSpawner".spawn_player(multiplayer.get_peers().get(0))


func _on_host_focus_entered() -> void:
	print("FOCUS") # Replace with function body.
