extends Node3D

@export var test_agent_radius := 0.2
@export var test_agent_max_slope_degrees := 45.0

@onready var camera := $"../Player/Camera3D"

var pending_probe := false
var pending_mouse_pos := Vector2.ZERO

var has_point_a := false
var has_point_b := false
var point_a := Vector3.ZERO
var point_b := Vector3.ZERO
var current_path := PackedVector3Array()

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
	if has_point_a:
		DebugDraw3D.draw_text(point_a + Vector3.UP * 0.6, "A", 32, Color(0, 1, 0))
		DebugDraw3D.draw_arrow(point_a + Vector3.UP * 0.8, point_a, Color(0, 1, 0), 0.08)

	if has_point_b:
		DebugDraw3D.draw_text(point_b + Vector3.UP * 0.6, "B", 32, Color(1, 0, 0))
		DebugDraw3D.draw_arrow(point_b + Vector3.UP * 0.8, point_b, Color(1, 0, 0), 0.08)

	for i in range(current_path.size() - 1):
		var from := current_path[i] + Vector3.UP * DEBUG_HEIGHT
		var to := current_path[i + 1] + Vector3.UP * DEBUG_HEIGHT
		DebugDraw3D.draw_arrow(from, to, Color(0.2, 0.8, 1.0), 0.06)

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

	point_b = hit_position
	has_point_b = true
	current_path = Navigation.debug_find_path(point_a, point_b, test_agent_radius, test_agent_max_slope_degrees)
	print("Set B:", point_b)
	print("Path points:", current_path.size())
