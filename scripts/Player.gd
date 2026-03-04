extends Node3D
class_name Player

@export var terrain: Terrain
@export var player_id: int = 0

#var Units: Array[Unit]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Camera3D/SculptBrush.terrain = terrain
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Update visibility of enemy units
	LineOfSightManager.set_unit_vis_from_los(player_id)
