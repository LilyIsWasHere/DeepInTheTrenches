extends Node3D
class_name ExcavationPathTool

const ExcavationPath  = preload("res://excavation_path.gd")

var ActivePath: ExcavationPath = null
var CreatedPaths: Array[ExcavationPath]

@export var scroll_delta_amt: float = 0.3
@export var point_distance_interval: float = 1.0
@export var point_max_distance_delta: float = 10.0



var tool_active: bool = false

func get_closest_unexcavated_path_point(position: Vector3) -> Dictionary:
	var closest: Vector3 = Vector3(9999, 9999, 9999)
	var path_of_closest: ExcavationPath = null
	var exists: bool = false
	for path in CreatedPaths:
		var path_closest: Vector3 = path.get_closest_unexcavated_point(position)[1]
		if (position.distance_to(path_closest) < position.distance_to(closest)):
			closest = path_closest
			path_of_closest = path
			exists = true
			
			
	var dig_point_info: Dictionary 
	dig_point_info["exists"] = exists
	dig_point_info["location"] = closest
	dig_point_info["height_delta"] = path_of_closest.height_delta if path_of_closest else null
	return dig_point_info
		
	
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("BeginExcavationPath")):
		print("Excavation path tool active")
		tool_active = true
		if (ActivePath != null):
			ActivePath.queue_free()
			ActivePath = null
			
		ActivePath = ExcavationPath.new()
		ActivePath.owning_camera = $"../Camera3D"
		ActivePath.curve = Curve3D.new()
		ActivePath.curve.bake_interval = point_distance_interval
		add_child(ActivePath)

		
	if (!tool_active):
		return
		
	if (event.is_action_pressed("CancelTool")):
		tool_active = false
		ActivePath.queue_free()
		ActivePath = null
		
	if (event.is_action_pressed("CommitTool")):
		tool_active = false
		CreatedPaths.append(ActivePath)
		ActivePath = null
		

	
	if (event.is_action_pressed("ScrollUp")):
		ActivePath.height_delta += scroll_delta_amt
	if (event.is_action_pressed("ScrollDown")):
		ActivePath.height_delta -= scroll_delta_amt
		

func _physics_process(_delta: float) -> void:
	if (tool_active && Input.is_action_pressed("ToolClick")):
		
		
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = $"../Camera3D"
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * 3000
		

		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if result.is_empty():
			return
			
		var points: PackedVector3Array = ActivePath.curve.get_baked_points()
		var prev_point: Vector3 = points.get(points.size()-1)
			
		var pos_xz: Vector2 = Vector2(result.position.x, result.position.z)
		var prev_pos_xz: Vector2 = Vector2(prev_point.x, prev_point.z) if points.size() > 0 else Vector2(9999, 9999)
		
		var dist_2D: float = pos_xz.distance_to(prev_pos_xz)
		if (dist_2D >= point_distance_interval && (dist_2D <= point_max_distance_delta || points.size() == 0)):
			ActivePath.curve.add_point(result.position)
		
