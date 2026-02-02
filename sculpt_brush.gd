extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

const RAY_LENGTH: float = 3000.0


func _process(delta: float) -> void:
	
	if (Input.is_action_pressed("AddMaterial")):
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = $".."
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * RAY_LENGTH
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if result.is_empty():
			return
		
		if result["collider"].has_method("add_terrain"):
			result["collider"].add_terrain(result["position"])
			$"../HeightmapDBGMesh".set_heightmap(result["collider"].get_heightmap_viewport_tex())
	
	
	
	
	
	if (Input.is_action_pressed("RemoveMaterial")):
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = $".."
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * RAY_LENGTH
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if result.is_empty():
			return
		
		if result["collider"].has_method("add_terrain"):
			result["collider"].remove_terrain(result["position"])
			$"../HeightmapDBGMesh".set_heightmap(result["collider"].get_heightmap_viewport_tex())
