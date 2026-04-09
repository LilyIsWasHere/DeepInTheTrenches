class_name Shell
extends RigidBody3D

var is_shot: bool = false
var detonated: bool = false

var crater_scale: float = 1.0

var shrapnel_fragments: int = 100



func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 100
	body_entered.connect(detonate)
	$ExhaustParticles.emitting = false
	
	shoot(global_position, Vector3(1,3,1), 20)
	
func detonate(body: Node) -> void:
	
	if (is_shot && !detonated):
		detonated = true
		$AudioStreamPlayer3D.play()
		lock_rotation = true
		freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		linear_velocity = Vector3(0,0,0)
		
		await get_tree().create_timer(0.3).timeout
		
		$ExplosionParticles.emitting = true
		$ExhaustParticles.emitting = false
		
		
		if (is_multiplayer_authority()):
			GlobalTerrainManager.get_terrain().sculpt_terrain(global_position, 100, -2 * crater_scale, Vector2(-100, 100), null)
		
		for i in range(shrapnel_fragments):
			var rand_dir: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
			var rand_range: float = randfn(10, 3)
			var bullet: Bullet = Bullet.new()
			add_child(bullet)
			
			
			bullet.shoot(global_position, rand_dir, rand_range, 10)
			
		$MeshInstance3D.visible = false
		
		await get_tree().create_timer(5).timeout
		queue_free()

func _process(delta: float) -> void:

		
		
		var forward: Vector3 = -global_basis.z
		var angle_to_vel_dir: float = forward.signed_angle_to(linear_velocity.normalized(), linear_velocity.normalized().cross(forward))
		
		angular_velocity = linear_velocity.normalized().cross(forward) * angle_to_vel_dir * linear_velocity.length()
	




func shoot(origin: Vector3, _direction: Vector3, _velocity: float) -> void:
	look_at(_direction)
	
	global_position = origin
	
	linear_velocity = _direction.normalized() * _velocity
	$ExhaustParticles.emitting = true
	is_shot = true
	
	
