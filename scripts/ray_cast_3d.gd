@tool
extends RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	target_position = ($"../TestUnit2".global_position - global_position) * 10
	
	if is_colliding():
		debug_shape_custom_color = Color(255,0,0)
		$TestUnit1/MeshInstance3D.material_override.albedo_color =Color(255,0,0)
	else:
		debug_shape_custom_color = Color(0,255,0)
		$TestUnit1/MeshInstance3D.material_override.albedo_color =Color(0,255,0)

	
