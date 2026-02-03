extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

const RAY_LENGTH: float = 3000.0


@export var brush_radius: float = 100
@export var brush_height: float = 20


func _physics_process(delta: float) -> void:
	
	if (Input.is_action_pressed("AddMaterial") || Input.is_action_pressed("RemoveMaterial")):
		
		var sculpt_height: float = 0.0
		if Input.is_action_pressed("AddMaterial"): sculpt_height = brush_height * delta
		elif Input.is_action_pressed("RemoveMaterial"): sculpt_height = -brush_height * delta
		
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = $".."
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * RAY_LENGTH
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if result.is_empty():
			return
		
		$"../../Terrain".sculpt_terrain(result["position"], brush_radius, sculpt_height)
		
		if result["collider"].has_method("get_heightmap_viewport_tex"):
			$"../HeightmapDBGMesh".set_heightmap(result["collider"].get_heightmap_viewport_tex())
	
	
