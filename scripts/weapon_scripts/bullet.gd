extends Node3D

var curr_position : Vector3
var target_position : Vector3
var direction : Vector3
var target_area : float
var damage : float
var speed : float = 20.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func shoot(start : Vector3, target : Vector3, area : float, dmg : float) -> void:
	curr_position = start
	target_position = target
	target_area = area
	damage = dmg
	
	direction = (target_position - curr_position).normalized()
	
	$RigidBody3D.linear_velocity = direction * speed

func _on_rigid_body_3d_body_entered(body: Node) -> void:
	if target_area > 1.0:
		pass
		# find all targets and deal damage to each
	else:
		pass
		# find target and deal damage
	queue_free()
