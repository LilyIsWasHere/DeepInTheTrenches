extends Node3D


var start_position : Vector3
var target_position : Vector3
var direction : Vector3
var range : float
var target_area : float
var damage : float
var speed : float = 20.0
var own_unit : Unit

var target_pos: Vector3
var is_shot: bool = false



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if (is_shot):
		
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(global_position, target_pos)
		
		query.collision_mask = (1<<1-1) |	(1 << 3 - 1)
		
		query.hit_back_faces = false
		var result: Dictionary = space_state.intersect_ray(query)
		
		
		
		if (!result.is_empty()):
			var collider: Node3D = result["collider"] as Node3D
			
			
			
			DebugDraw3D.draw_line(global_position, result["position"], Color(1,0.7,0), 0.1)
			DebugDraw3D.draw_sphere(result["position"], 0.2, Color(1,0,0), 0.1)
			
			if (collider.has_method("deal_damage")):
				collider.deal_damage(damage)
			else:
				pass
		else:
			DebugDraw3D.draw_line(global_position, global_position + (direction * range), Color(1,0.7,0), 0.1)
			DebugDraw3D.draw_sphere(global_position + (direction * range), 0.2, Color(1,0,0), 0.1)
		is_shot = false	
		queue_free()



	
	
func shoot(origin: Vector3, _direction: Vector3, _range: float, _dmg: float) -> void:
	global_position = origin
	range = _range
	damage = _dmg
	direction = _direction.normalized()
	
	target_pos = global_position + (direction * range)
	is_shot = true
	
	

		
	
