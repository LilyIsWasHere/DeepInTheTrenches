extends Node3D
class_name Player

@export var terrain: Terrain
@export var player_id: int = 0
@export var Camera: Camera3D
@export var excavation_path_tool: ExcavationPathTool
#var Units: Array[Unit]

@export var startActive : bool
var isActive : bool

var cursor : Cursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalPlayerManager.register_player(self)
	cursor = $Cursor
	cursor.teamID = player_id
	
	set_active(false)
	
	if startActive:
		get_tree().create_timer(1.0).timeout.connect(GlobalPlayerManager.set_active_player.bind(player_id))
	
	var sculpt_brush: SculptBrush = $Camera3D/SculptBrush
	sculpt_brush.terrain = terrain

func set_active(active : bool) -> void:
	print(name, " ", active)
	isActive = active
	cursor.set_active(active)
	Camera.current = active
	Camera.isActive = active
	excavation_path_tool.player_active = active
	$Camera3D/UnitSpawner.isActive = active

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	pass
	# Update visibility of enemy units
	#LineOfSightManager.set_unit_vis_from_los(player_id)
