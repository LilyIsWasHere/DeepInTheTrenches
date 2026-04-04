extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	#if (event.is_action_pressed("ToolClick")):
		#print_once_per_client.rpc()
	pass
		


@rpc("any_peer", "call_local", "reliable") func print_once_per_client() -> void:
	print(multiplayer.get_peers())
	print("I will be printed to the console once per each connected client.")
	print(is_multiplayer_authority())
