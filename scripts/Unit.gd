extends Node3D
class_name Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
		var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
