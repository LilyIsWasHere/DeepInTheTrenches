extends Node3D

@export var damage : float = 5.0
@export var range : float = 10.0
@export var affected_area : float = 1.0

@export var ammo_per_shot : int = 1

const bullet : PackedScene = preload("res://scenes/bullet.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reload() -> void:
	var refill_amt : int = $Magazine.get_max_item_quantity("res://Inventory/InventoryItems/magazine_item.tres") - $Magazine.get_item_quantity("res://Inventory/InventoryItems/magazine_item.tres")
	var missing_ammo : int = $Magazine.remove_items("res://Inventory/InventoryItems/ammo_item.tres", refill_amt)
	$Magazine.add_items("res://Inventory/InventoryItems/magazine_item.tres", refill_amt - missing_ammo)
		
func shoot() -> void:
	if $Magazine.get_item_quantity("res://Inventory/InventoryItems/ammo_item.tres") >= ammo_per_shot:
		var missing_shots : int = $Magazine.remove_items("res://Inventory/InventoryItems/ammo_item.tres", ammo_per_shot)
		
		for i in range(ammo_per_shot - missing_shots):
			var bullet_instance : Node3D = bullet.instantiate()
			get_tree().current_scene.add_child(bullet_instance) # will need to pick a specific node location eventually, for now its putting it in the root node 
			
			bullet_instance.shoot($Weapon.global_position, Vector3.ZERO, affected_area, range, damage) # calls the shooting function for the bullet scene, will need to change the Vector3.ZERO to the target position

func deposit_ammo(amount : int) -> int:
	var refill_max : int = $Magazine.get_max_item_quantity("res://Inventory/InventoryItems/ammo_item.tres") - $Magazine.get_item_quantity("res://Inventory/InventoryItems/ammo_item.tres")
	return $Magazine.add_items("res://Inventory/InventoryItems/ammo_item.tres", amount - refill_max)
