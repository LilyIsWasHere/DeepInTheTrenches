extends Control

@onready var ip_input: LineEdit = %"IPInput"
@onready var port_input: LineEdit = %"PortInput"
@onready var join_button: Button = %"JoinButton"

func _on_join_button_pressed() -> void:
	var ip: String = ip_input.text
	var port: int = int(port_input.text)
	if port <= 0 or port > 65535:
		return
	
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_file("res://Multiplayer/Multiplayer.tscn")
