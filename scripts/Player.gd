extends Node3D
class_name Player

@export var terrain: Terrain
@export var player_id: int = 0
@export var Camera: Camera3D
@export var excavation_path_tool: ExcavationPathTool
#var Units: Array[Unit]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalPlayerManager.register_player(self)
	
	var sculpt_brush: SculptBrush = $Camera3D/SculptBrush
	sculpt_brush.terrain = terrain



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Update visibility of enemy units
	LineOfSightManager.set_unit_vis_from_los(player_id)
