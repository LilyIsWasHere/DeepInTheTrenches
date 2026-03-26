extends Node3D

var RAY_LENGTH: float = 3000
#spawnable unit is footUnit by default
var unit_scene : PackedScene
var footUnit := preload("res://Units/FootUnit.tscn")
var mortarUnit := preload("res://Units/Buildings/MortarUnit.tscn")
var turretUnit := preload("res://Units/Buildings/TurretUnit.tscn")
var productionUnit := preload("res://Units/Buildings/FactoryUnit.tscn")

var isActive : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	unit_scene = footUnit


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if !isActive:
		return
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
			#if unit.is_in_group("can_move"):
				#unit.move_target_pos = result.position

func _input(event: InputEvent) -> void:
	if !isActive:
		return
	
	if event.is_action_pressed("1"):
		unit_scene = footUnit
	elif event.is_action_pressed("2"):
		unit_scene = mortarUnit
	elif event.is_action_pressed("3"):
		unit_scene = turretUnit
	elif event.is_action_pressed("4"):
		unit_scene = productionUnit
