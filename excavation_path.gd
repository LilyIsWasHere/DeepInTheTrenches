extends Path3D
class_name ExcavationPath

var height_delta: float = -1.0
 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for point: Vector3 in curve.get_baked_points():
		var arrow_begin := Vector3(point.x, point.y + abs(height_delta), point.z) if height_delta < 0.0 else point
		var arrow_end := point if height_delta < 0.0 else Vector3(point.x, point.y + abs(height_delta), point.z)
		var arrow_color := Color(0.2, 0.2, 1) if height_delta < 0.0 else Color(1, 0.2, 0.2)
		
		DebugDraw3D.draw_arrow(arrow_begin, arrow_end, arrow_color, 0.1)
