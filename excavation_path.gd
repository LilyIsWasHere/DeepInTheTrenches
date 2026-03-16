extends Path3D
class_name ExcavationPath

var height_delta: float = -1.0

var owning_camera: Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	var points := curve.get_baked_points()
	if (points.size() > 0):
		DebugDraw3D.draw_text(points[0] + Vector3(0.0, abs(height_delta) + 1.0, 0.0), str(height_delta), 64, Color(1, 1, 0))
	
	var closest_unexcavated_to_player: Array = get_closest_unexcavated_point(owning_camera.global_position)
	var closest_idx: int = closest_unexcavated_to_player[0]
	
	var idx: int = 0
	for point: Vector3 in points:
		var arrow_begin := Vector3(point.x, point.y + abs(height_delta), point.z) if height_delta < 0.0 else point
		var arrow_end := point if height_delta < 0.0 else Vector3(point.x, point.y + abs(height_delta), point.z)
		var arrow_color := Color(0.2, 0.2, 1) if height_delta < 0.0 else Color(1, 0.2, 0.2)
		
		if (is_point_excavated(idx)):
			arrow_color = Color(0.2, 1.0, 0.2)
		if (idx == closest_idx):
			arrow_color = Color(1, 0, 1)
		
		DebugDraw3D.draw_arrow(arrow_begin, arrow_end, arrow_color, 0.1)
		DebugDraw3D.draw_text(arrow_begin, "%.2f" % (GlobalTerrainManager.get_terrain().get_terrain_data(point).height - GlobalTerrainManager.get_terrain().get_terrain_data(point).initial_height))
		idx += 1


func is_point_excavated(idx: int) -> bool: 
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	var points: PackedVector3Array = curve.get_baked_points()
	var point: Vector3 = points[idx]
	
	var data: Dictionary = terrain.get_terrain_data(point)
	if (height_delta >= 0.0):
		return data.height - data.initial_height >= height_delta - 0.01
	else:
		return data.height - data.initial_height <= height_delta + 0.01
	


func get_closest_unexcavated_point(position: Vector3) -> Array:
	var points := curve.get_baked_points()
	
	var closest_point: Vector3 = Vector3(9999, 9999, 9999)
	var closest_idx: int = -1
	
	for i in range(points.size()):
		var point: Vector3 = points[i]
		if (is_point_excavated(i)):
			continue
			
		if (position.distance_to(point) < position.distance_to(closest_point)):
			closest_point = point
			closest_idx = i
			
	
	return [closest_idx, closest_point]
		
	
	
