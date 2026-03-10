extends Node3D

@export var range : float = 10.0
@export var damage : float = 5.0
@export var affected_area : float = 1.0

@export var mag_size : int = 30
@export var ammo_in_mag : int = 30
@export var ammo_in_reserve : int = 300
@export var ammo_per_shot : int = 1

const bullet : PackedScene = preload("res://scenes/bullet.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reload() -> void:
	var refill_amt : int = mag_size - ammo_in_mag
	
	# refills either the entire mag or as much as possible if there is not enough ammo in storage
	if ammo_in_reserve >= refill_amt:
		ammo_in_reserve -= refill_amt
		ammo_in_mag += refill_amt
	else:
		refill_amt = ammo_in_reserve
		ammo_in_reserve -= refill_amt
		ammo_in_mag += refill_amt
		
func shoot() -> void:
	if ammo_in_mag >= ammo_per_shot:
		ammo_in_mag -= ammo_per_shot
		
		for i in range(ammo_per_shot):
			var bullet_instance : Node3D = bullet.instantiate()
			get_tree().current_scene.add_child(bullet_instance) # will need to pick a specific node location eventually, for now its putting it in the root node 
		
			bullet_instance.shoot($Weapon.global_position, Vector3.ZERO) # calls the shooting function for the bullet scene, will need to change the Vector3.ZERO to the target position
		
