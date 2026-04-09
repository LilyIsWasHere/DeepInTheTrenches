extends Node3D
class_name Weapon

# variables for weapon
@export var damage : float = 30
@export var range : float = 10.0 # how far it can shoot
@export var affected_area : float = 1.0 # the zone the shot will hit (e.g. cannon hits a multiple targets, bullet only hits one target)

@export var ammo_per_shot : int = 1

# loading the bullet scene
@export var bullet : PackedScene;

# ammo/mag stuff
var inventory : Node = null
const magazineItem : InventoryItem = preload("res://Inventory/InventoryItems/magazine_item.tres")
const ammoItem : InventoryItem = preload("res://Inventory/InventoryItems/ammo_item.tres")

var reloading : bool = false
var inWeaponCooldown : bool = false
@export var inaccuracy: float = 5 # Gaussian standard deviation in degrees
@export var fire_delay: float = 0.5
@export var reload_delay: float = 3

var enabled : bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ReloadTime.wait_time = reload_delay
	$CooldownTime.wait_time = fire_delay
	
	# get parent inventory
	inventory = get_parent().get_node("Inventory")
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# Reloads the magazine using ammo from storage
func reload() -> void:
	if inventory.get_item_quantity(magazineItem) > 0:
		# Remove one magazine from unit inventory and load it into the weapon's ammo
		inventory.remove_items(magazineItem, 1)
		$Magazine.add_items(ammoItem, $Magazine.get_max_item_quantity(ammoItem))
		# Start reload timer to avoid shooting while reloading
		reloading = true
		$ReloadTime.start()
		
func shoot(target_pos : Vector3) -> void:
	
	if !enabled:
		return
	
	if !reloading and !inWeaponCooldown:
		# checks that the magazine has enough ammo loaded
		if can_shoot():
			# check for missing bullets, shouldn't really be necessary but I'm leaving it in for now, incase we only want to check that there is one bullet on the line above
			var missing_shots : int = $Magazine.remove_items(ammoItem, ammo_per_shot)
			
			# instantiate a bullet for every shot, will need to setup some kind of spray pattern
			for i in range(ammo_per_shot - missing_shots):
				var direction: Vector3 = (target_pos - global_position).normalized()
				var rand_direction: Vector3 = get_random_gaussian_direction(direction, deg_to_rad(inaccuracy))
				fire_bullet.rpc(rand_direction)
			
			$CooldownTime.start()
			inWeaponCooldown = true
		else:
			reload() # Auto reload if there is no more ammo left in the mag when trying to shoot

@rpc("any_peer", "call_local", "reliable") func fire_bullet(direction: Vector3) -> void:
	$FireAudioPlayer.play()
	var bullet_instance : Bullet = bullet.instantiate()
	get_tree().current_scene.add_child(bullet_instance) # will need to pick a specific node location eventually, for now its putting it in the root node 
	bullet_instance.global_position = global_position
	
	bullet_instance.shoot(global_position, direction, range, damage) # calls the shooting function for the bullet scene

	


func get_random_gaussian_direction(dir: Vector3, sigma: float) -> Vector3:
	var newDir : Vector3 = dir.normalized()
	
	var rand_gaussian: float = randfn(0, sigma)
	
	var perpendicular: Vector3 = ((newDir + Vector3(1,1,1)).cross(newDir)).normalized()
	
	var rand_angle: float = randf_range(0, 2*PI)
	
	var rand_perp: Vector3 = perpendicular.rotated(newDir, rand_angle)
	
	return newDir.rotated(rand_perp, rand_gaussian)


func _on_reload_time_timeout() -> void:
	reloading = false
	
func can_shoot() -> bool:
	if $Magazine.get_item_quantity(ammoItem) > 0:
		return true
	else:
		return false 

func _on_cooldown_time_timeout() -> void:
	inWeaponCooldown = false
