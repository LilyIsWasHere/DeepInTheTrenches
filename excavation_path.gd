extends Path3D
class_name ExcavationPath

var height_delta: float = -2.0

var owning_camera: Camera3D

var path_fully_excavated: bool = false

var point_fully_excavated: Dictionary[int, bool]

# Called when the node enters the scene tree for tdhe first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	var points := curve.get_baked_points()
	if (points.size() > 0):
		
		
		var cam: Camera3D = get_parent().get_parent() # ew gross
		var dist: float = points[0].distance_to(cam.global_position)
		
		DebugDraw3D.draw_text(points[0] + Vector3(0.0, abs(height_delta) + 1.0, 0.0), str(height_delta), 3 * dist, Color(1, 1, 0))
	

	
	var idx: int = 0
	for point: Vector3 in points:
		var arrow_begin := Vector3(point.x, point.y + abs(height_delta), point.z) if height_delta < 0.0 else point
		var arrow_end := point if height_delta < 0.0 else Vector3(point.x, point.y + abs(height_delta), point.z)
		var arrow_color := Color(0.2, 0.2, 1) if height_delta < 0.0 else Color(1, 0.2, 0.2)
		
		if (is_point_excavated(idx)):
			arrow_color = Color(0.2, 1.0, 0.2)
		
		DebugDraw3D.draw_arrow(arrow_begin, arrow_end, arrow_color, 0.1)
		idx += 1


func is_point_excavated(idx: int) -> bool: 
	
	if (point_fully_excavated.has(idx) && point_fully_excavated[idx]):
		return point_fully_excavated[idx]
	
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	var points: PackedVector3Array = curve.get_baked_points()
	var point: Vector3 = points[idx]
	
	var data: Dictionary = terrain.get_terrain_data(point)
	
	var fully_excavated: bool = false
	if (height_delta >= 0.0):
		fully_excavated = data.height - data.initial_height >= height_delta - 0.01
	else:
		fully_excavated = data.height - data.initial_height <= height_delta + 0.01
		
	point_fully_excavated[idx] = fully_excavated
	return fully_excavated
	


func get_closest_unexcavated_point(position: Vector3) -> Array:
	
	var closest_point: Vector3 = Vector3(9999, 9999, 9999)
	var closest_idx: int = -1
	
	if (path_fully_excavated):
		return [closest_idx, closest_point]
	
	var points := curve.get_baked_points()
	for i in range(points.size()):
		var point: Vector3 = points[i]
		if (is_point_excavated(i)):
			continue
			
		if (position.distance_to(point) < position.distance_to(closest_point)):
			closest_point = point
			closest_idx = i
			
	
	return [closest_idx, closest_point]
	




	
func get_closest_fully_excavated_point(position: Vector3) -> Array:
	var points := curve.get_baked_points()
	
	var closest_point: Vector3 = Vector3(9999, 9999, 9999)
	var closest_idx: int = -1
	
	
	var all_fully_excavated: bool = true
	for i in range(points.size()):
		var point: Vector3 = points[i]
		if (not is_point_excavated(i)):
			all_fully_excavated = false
			continue
			
		if (position.distance_to(point) < position.distance_to(closest_point)):
			closest_point = point
			closest_idx = i
			
	if (all_fully_excavated):
		path_fully_excavated = true

	return [closest_idx, closest_point]
