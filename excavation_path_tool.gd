extends Node3D
class_name ExcavationPathTool

const ExcavationPath  = preload("res://excavation_path.gd")

var ActivePath: ExcavationPath = null

@export var scroll_delta_amt: float = 0.3
@export var point_distance_interval: float = 1.0
@export var point_max_distance_delta: float = 10.0

var tool_active: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("BeginExcavationPath")):
		print("Excavation path tool active")
		tool_active = true
		if (ActivePath != null):
			ActivePath.queue_free()
			ActivePath = null
			
		ActivePath = ExcavationPath.new()
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
		ActivePath = null

	
	if (event.is_action_pressed("ScrollUp")):
		ActivePath.height_delta += scroll_delta_amt
	if (event.is_action_pressed("ScrollDown")):
		ActivePath.height_delta -= scroll_delta_amt
		

func _physics_process(delta: float) -> void:
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
			print("Adding point at " + str(result.position))
		
