extends Control

@onready var port_input: LineEdit = %"PortInput"
@onready var start_button: Button = %"StartButton"

func _on_start_button_pressed() -> void:
	var port := int(port_input.text)
	if port <= 0 or port > 65535:
		return

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		OS.alert("Failed to start server on port " + str(port) + ".")
		return
	
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_file("res://Multiplayer/Multiplayer.tscn")