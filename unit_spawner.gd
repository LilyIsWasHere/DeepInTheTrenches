extends Node3D

var RAY_LENGTH: float = 3000
var unit_scene := preload("res://Unit.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if (Input.is_action_just_pressed("SpawnPlayerUnit") || Input.is_action_just_pressed("SpawnEnemyUnit")):
		var unit_team: int = 0 if Input.is_action_pressed("SpawnPlayerUnit") else 1
		
		var mouse_pos := get_viewport().get_mouse_position()
		var cam: Camera3D = $".."
		var from := cam.project_ray_origin(mouse_pos)
		var to := from + cam.project_ray_normal(mouse_pos) * RAY_LENGTH
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if result.is_empty():
			return
			
		else:
			
			
			var unit: Unit = unit_scene.instantiate()
			unit.team = unit_team
			
			var attach_node: Node3D = $"../..".get_parent_node_3d()
			attach_node.add_child(unit)
			unit.global_position = result.position
			
