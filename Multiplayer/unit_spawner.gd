class_name UnitSpawner
extends MultiplayerSpawner

signal spawned_unit(unit: Unit)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var team: int = 0 if get_multiplayer_authority() == 1 else 1
	MultiplayerSpawnerManager.unit_spawners[team] = self
	
	spawn_function = _spawn_unit_func
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func spawn_unit(scene_path: String, pos: Vector3, team: int) -> Unit:
	return spawn([scene_path, pos, team])
	



func _spawn_unit_func(data: Array) -> Unit:
	var scene_path: String = data[0]
	var pos: Vector3 = data[1]
	var team: int = data[2]
	var scene: PackedScene = load(scene_path)
	
	var unit: Unit = scene.instantiate()
	unit.initialize(team)
	(func()->void: unit.global_position = pos).call_deferred()
	unit.global_position = pos
	unit.set_multiplayer_authority(get_multiplayer_authority())
	spawned_unit.emit(unit)
		
	
	return unit
