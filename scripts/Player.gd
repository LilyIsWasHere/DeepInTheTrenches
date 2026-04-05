extends Node3D
class_name Player

@export var terrain: Terrain
@export var player_id: int = 0
@export var Camera: Camera3D
var excavation_path_tool: ExcavationPathTool
#var Units: Array[Unit]

var CameraScene: PackedScene = preload("res://PlayerCamera.tscn")

var cursor : Cursor


func _input(event: InputEvent) -> void:
	#if (event.is_action_pressed("ToolClick")):
		#MultiplayerSpawnerManager.player_spawner.spawn_player(3)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalPlayerManager.register_player(self, player_id)
	
	print("required authority: " + str(get_multiplayer_authority()))
	print("peer id: " + str(multiplayer.get_unique_id()))
	
	#UnitSpawner.spawn_path = $"../..".get_path()
	
	
	if (is_multiplayer_authority()):
		attach_camera()
		

	
	

	
func attach_camera() -> void:
	
	
	
	var cam_inst: FreeLookCamera = CameraScene.instantiate()
	Camera = cam_inst
	
	if (player_id == 0):
		cam_inst.global_transform = $"../Player0CamOrigin".global_transform
	else:
		cam_inst.global_transform = $"../Player1CamOrigin".global_transform
	
	cam_inst.set_multiplayer_authority(get_multiplayer_authority())
	cam_inst.set_multiplayer_authority.call_deferred(get_multiplayer_authority())
	cam_inst.unit_spawner.owning_player = self
	cam_inst.owning_player = self
	$CamAnchor.add_child(cam_inst)
	excavation_path_tool = cam_inst.excavation_path_tool

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	pass
	# Update visibility of enemy units
	#LineOfSightManager.set_unit_vis_from_los(player_id)
	
	
func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
