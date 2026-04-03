extends Node3D

@export var test_agent_radius := 0.2
@export var test_agent_height := 1.7
@export var test_agent_max_slope_degrees := 40.0
@export var test_agent_max_step_height := 0.35
@export var test_agent_wall_climb_height := 0.25
@export var team: int = 0

@onready var camera := $"../Player/Camera3D"

var pending_probe := false
var pending_mouse_pos := Vector2.ZERO

const MAX_DEBUG_PATHS := 8
const DEBUG_PATH_COLORS: Array[Color] = [
	Color(0.2, 0.8, 1.0),
	Color(1.0, 0.6, 0.2),
	Color(0.5, 1.0, 0.4),
	Color(1.0, 0.3, 0.7),
	Color(0.9, 0.9, 0.3),
	Color(0.7, 0.5, 1.0),
	Color(0.2, 1.0, 0.8),
	Color(1.0, 0.8, 0.9)
]

var has_point_a := false
var has_point_b := false
var point_a := Vector3.ZERO
var point_b := Vector3.ZERO
var current_path := PackedVector3Array()
var completed_paths: Array[PackedVector3Array] = []


@export var nav_agent_config: NavAgentConfig
var nav_handles: Array[NavPlanHandle] = []

const DEBUG_HEIGHT := 0.25

func _physics_process(_delta: float) -> void:
	if pending_probe:
		pending_probe = false
		var from : Vector3 = camera.project_ray_origin(pending_mouse_pos)
		var to : Vector3 = from + camera.project_ray_normal(pending_mouse_pos) * 3000.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		var result : Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
		if not result.is_empty():
			_handle_probe_click(result.position)

func _process(_delta: float) -> void:
	var remaining_handles: Array[NavPlanHandle] = []
	for i in range(nav_handles.size()):
		var nav_handle: NavPlanHandle = nav_handles[i]
		if nav_handle == null:
			continue

		if nav_handle.status == NavPlanHandle.NavRequestStatus.READY:
			current_path = nav_handle.waypoints
			completed_paths.append(nav_handle.waypoints)
			while completed_paths.size() > MAX_DEBUG_PATHS:
				completed_paths.remove_at(0)
			print("Path points:", current_path.size())
		elif nav_handle.status == NavPlanHandle.NavRequestStatus.FAILED:
			print("Path request failed")
		else:
			remaining_handles.append(nav_handle)

	nav_handles = remaining_handles

	if has_point_a:
		DebugDraw3D.draw_text(point_a + Vector3.UP * 0.6, "A", 32, Color(0, 1, 0))
		DebugDraw3D.draw_arrow(point_a + Vector3.UP * 0.8, point_a, Color(0, 1, 0), 0.08)

	if has_point_b:
		DebugDraw3D.draw_text(point_b + Vector3.UP * 0.6, "B", 32, Color(1, 0, 0))
		DebugDraw3D.draw_arrow(point_b + Vector3.UP * 0.8, point_b, Color(1, 0, 0), 0.08)

	for i in range(completed_paths.size()):
		var path: PackedVector3Array = completed_paths[i]
		var color: Color = DEBUG_PATH_COLORS[i % DEBUG_PATH_COLORS.size()]
		for j in range(path.size()):
			var point: Vector3 = path[j] + Vector3.UP * DEBUG_HEIGHT
			DebugDraw3D.draw_sphere(point, 0.08, color)

		for j in range(path.size() - 1):
			var from: Vector3 = path[j] + Vector3.UP * DEBUG_HEIGHT
			var to: Vector3 = path[j + 1] + Vector3.UP * DEBUG_HEIGHT
			DebugDraw3D.draw_line(from, to, color, 0.03)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_MIDDLE and event.pressed:
		pending_probe = true
		pending_mouse_pos = event.position

func _handle_probe_click(hit_position: Vector3) -> void:
	if not has_point_a or has_point_b:
		point_a = hit_position
		point_b = Vector3.ZERO
		has_point_a = true
		has_point_b = false
		current_path = PackedVector3Array()
		print("Set A:", point_a)
		return

	# do the debug pathfinding request
	point_b = hit_position
	has_point_b = true
	print("Set B:", point_b)

	current_path = PackedVector3Array()
	var nav_handle: NavPlanHandle = Navigation.debug_request_path(point_a, point_b, self, nav_agent_config)
	if nav_handle != null:
		nav_handles.append(nav_handle)

func get_nav_agent_config() -> NavAgentConfig:
	return nav_agent_config
