extends StaticBody3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_heightmap_viewport_tex() -> Texture2D:
	var viewport_tex: Texture2D = $"..".heightmap_tex
	return viewport_tex




	#var world_to_local: Transform3D = global_transform.inverse()
	#var local_pos: Vector3 = world_to_local * global_pos
	#print("Local pos: " + str(local_pos))
	#print(scale)
