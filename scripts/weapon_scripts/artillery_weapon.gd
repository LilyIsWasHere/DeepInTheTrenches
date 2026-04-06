class_name ArtilleryWeapon
extends Weapon


var fixed_target: Vector3
@export var firing_velocity: float = 50.0
var owning_player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TargetDBG.visible = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TargetDBG.global_position = fixed_target

func set_target_pos_visibility(isVisible : bool) -> void:
	$TargetDBG.visible = isVisible

func shoot(target_pos : Vector3) -> void:
	fixed_target = target_pos
	if !enabled:
		return
	
	if !reloading and !inWeaponCooldown:
		# checks that the magazine has enough ammo loaded
		if $Magazine.get_item_quantity(magazineItem) >= ammo_per_shot:
			# check for missing bullets, shouldn't really be necessary but I'm leaving it in for now, incase we only want to check that there is one bullet on the line above
			var missing_shots : int = $Magazine.remove_items(magazineItem, ammo_per_shot)
			
			# instantiate a bullet for every shot, will need to setup some kind of spray pattern
			for i in range(ammo_per_shot - missing_shots):
				
				var direction: Vector3 = get_firing_direction(global_position + Vector3(0,3,0), target_pos, firing_velocity)
				var rand_direction: Vector3 = get_random_gaussian_direction(direction, deg_to_rad(inaccuracy))
				
				var shell_instance : Shell = bullet.instantiate()
				owning_player.add_child(shell_instance)
				await get_tree().process_frame
				fire_shell.rpc(shell_instance, rand_direction, firing_velocity)
			
			$CooldownTime.start()
			inWeaponCooldown = true
		else:
			reload() # Auto reload if there is no more ammo left in the mag when trying to shoot



func get_firing_direction(pos: Vector3, target_pos: Vector3, velocity: float) -> Vector3:
	var v: float = velocity
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var h: float = pos.y - target_pos.y
	var x: float = Vector2(pos.x, pos.z).distance_to(Vector2(target_pos.x, target_pos.z))
	
	
	var angle: float = acos(sqrt(
			(x*x * (v*v + g*h - sqrt(v*v*v*v + 2*v*v*g*h - x*x*g*g))) / (2*v*v*(x*x + h*h))
		))
		
	var dir: Vector3 = (target_pos - pos).normalized()
	dir.y = 0
	
	var axis: Vector3 = dir.normalized().cross(Vector3(0,1,0)).normalized()
	dir = dir.rotated(axis, angle)

	return dir
	
	
	


@rpc("any_peer", "call_local", "reliable") func fire_shell(shell: Shell, direction: Vector3, velocity: float) -> void:
	
	shell.shoot(global_position + Vector3(0,3,0), direction, velocity) # calls the shooting function for the bullet scene

	
