extends Node3D

var start_position : Vector3
var target_position : Vector3
var direction : Vector3
var gun_range : float
var target_area : float
var damage : float
var speed : float = 20.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# should make the bullet die if it has moved further than it's range
	if $RigidBody3D.global_position.distance_to(start_position) >= gun_range:
		queue_free()
	
func shoot(start : Vector3, target : Vector3, area : float, range : float, dmg : float) -> void:
	start_position = start
	target_position = target
	target_area = area
	gun_range = range
	damage = dmg
	
	direction = (target_position - start_position).normalized()
	
	$RigidBody3D.linear_velocity = direction * speed

func _on_rigid_body_3d_body_entered(body: Node) -> void:
	if target_area > 1.0:
		pass
		# find all targets and deal damage to each
	else:
		pass
		# find target and deal damage
	queue_free()
