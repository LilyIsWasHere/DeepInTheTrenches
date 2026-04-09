extends Node3D
class_name Player

@export var terrain: Terrain
@export var player_id: int = 0
@export var Camera: Camera3D
var excavation_path_tool: ExcavationPathTool
#var Units: Array[Unit]

var CameraScene: PackedScene = preload("res://PlayerCamera.tscn")

var cursor : Cursor

@export var unit_spawner: UnitSpawner
@export var bullet_spawner: MultiplayerSpawner

var process_input: bool = true

@export var num_starting_units: int = 1

var foot_unit_scene_path: String = "res://Units/FootUnit.tscn"

@export var item_transport_blackboard: ItemBlackboard 

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
		spawn_starting_units()
		
		

func spawn_starting_units() -> void:
	
	var unit_spawn_pos: Vector3
	if (player_id == 0):
		unit_spawn_pos = $"../Player0UnitSpawnPos".global_position
	else:
		unit_spawn_pos = $"../Player1UnitSpawnPos".global_position
		
	

	for i in range(num_starting_units):
		var offset:  Vector3 = Vector3(randf_range(-30, 30), 10, randf_range(-30, 30))
		unit_spawner.spawn_unit(foot_unit_scene_path, unit_spawn_pos + offset, player_id)

	
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
