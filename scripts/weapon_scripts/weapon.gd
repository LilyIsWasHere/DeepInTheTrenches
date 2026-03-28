extends Node3D
class_name Weapon

# variables for weapon
@export var damage : float = 30
@export var range : float = 10.0 # how far it can shoot
@export var affected_area : float = 1.0 # the zone the shot will hit (e.g. cannon hits a multiple targets, bullet only hits one target)

@export var ammo_per_shot : int = 1

# loading the bullet scene
const bullet : PackedScene = preload("res://scenes/weapon_scenes/bullet.tscn")
const magazineItem : InventoryItem = preload("res://Inventory/InventoryItems/magazine_item.tres")
const ammoItem : InventoryItem = preload("res://Inventory/InventoryItems/ammo_item.tres")

var reloading : bool = false
var inWeaponCooldown : bool = false
@export var inaccuracy: float = 5 # Gaussian standard deviation in degrees

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# Reloads the magazine using ammo from storage
func reload() -> void:
	# Get the amount that needs to be refilled using inventory's max quantity and current quantity
	var refill_amt : int = $Magazine.get_max_item_quantity(magazineItem) - $Magazine.get_item_quantity(magazineItem)
	
	# Get the missing ammo from the storage, this will return 0 if it has enough to fill the mag or return the amount it is missing
	var missing_ammo : int = $Magazine.remove_items(ammoItem, refill_amt)
	
	if missing_ammo < refill_amt:
		# Add the refill amount - the missing ammo from storage to the magazine (avoids refilling with ammo that isn't there)
		$Magazine.add_items(magazineItem, refill_amt - missing_ammo)
		# Start reload timer to avoid shooting while reloading
		reloading = true
		$ReloadTime.start()
		
func shoot(target_pos : Vector3) -> void:
	if !reloading and !inWeaponCooldown:
		# checks that the magazine has enough ammo loaded
		if $Magazine.get_item_quantity(magazineItem) >= ammo_per_shot:
			# check for missing bullets, shouldn't really be necessary but I'm leaving it in for now, incase we only want to check that there is one bullet on the line above
			var missing_shots : int = $Magazine.remove_items(magazineItem, ammo_per_shot)
			
			# instantiate a bullet for every shot, will need to setup some kind of spray pattern
			for i in range(ammo_per_shot - missing_shots):
				var bullet_instance : Node3D = bullet.instantiate()
				get_tree().current_scene.add_child(bullet_instance) # will need to pick a specific node location eventually, for now its putting it in the root node 
				bullet_instance.global_position = global_position
				# MISSING: spray pattern calculation for target position, before sending it to the bullet
				
				var global_pos: Vector3 = global_position
				var direction: Vector3 = (target_pos - global_pos).normalized()
				var rand_direction: Vector3 = get_random_gaussian_direction(direction, deg_to_rad(inaccuracy))
				bullet_instance.shoot(global_pos, rand_direction, range, damage) # calls the shooting function for the bullet scene
			
			$CooldownTime.start()
			inWeaponCooldown = true
		else:
			reload() # Auto reload if there is no more ammo left in the mag when trying to shoot


func get_random_gaussian_direction(dir: Vector3, sigma: float) -> Vector3:
	
	var rand_gaussian: float = randfn(0, sigma)
	
	var perpendicular: Vector3 = ((dir + Vector3(1,1,1)).cross(dir)).normalized()
	
	var rand_angle: float = randf_range(0, 2*PI)
	
	var rand_perp: Vector3 = perpendicular.rotated(dir, rand_angle)
	
	return dir.rotated(rand_perp, rand_gaussian)
	

# for loading resources into the weapon inventory, will load ammo into the reserves
func deposit_ammo(amount : int) -> int:
	var refill_max : int = $Magazine.get_max_item_quantity(ammoItem) - $Magazine.get_item_quantity(ammoItem)
	return $Magazine.add_items(ammoItem, amount - refill_max) # return the ammo that doesn't fit in the inventory


func _on_reload_time_timeout() -> void:
	reloading = false
	
func can_shoot() -> bool:
	if $Magazine.get_item_quantity(magazineItem) > 0 or $Magazine.get_item_quantity(ammoItem) > 0:
		return true
	else:
		return false 

func _on_cooldown_time_timeout() -> void:
	inWeaponCooldown = false
