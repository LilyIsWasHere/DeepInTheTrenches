extends Node3D

const dimensions: Vector2i = Vector2i(1024, 1024)

var heightmap: HeightMapShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func check_line_of_sight(source: Vector3, dest: Vector3) -> bool:
	
	
	return false
