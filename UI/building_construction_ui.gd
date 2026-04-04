@tool
class_name BuildingConstructionUI
extends Control




@export var buildings: Array[ConstructableBuilding]

# Called when the node enters the scene tree for the first time.
var building_ui_scene: PackedScene = preload("res://UI/SingleBuildingUI.tscn")



func spawn_building_to_place(building_type: ConstructableBuilding) -> void:
	
	var building: BuildingUnit = MultiplayerSpawnerManager.unit_spawners[GlobalPlayerManager.get_player_by_auth(multiplayer.get_unique_id()).player_id].spawn_unit(
		building_type.scene.resource_path, 
		Vector3(0,0,0), 
		GlobalPlayerManager.get_player_by_auth(multiplayer.get_unique_id()).player_id, 
	) as BuildingUnit
	
	var construction_cost: Dictionary[InventoryItem, int] = building_type.construction_cost if building_type.construction_cost != null else {}
	building.initialize_building(building_type.construction_cost)
	

		
	

func _ready() -> void:
	
	for b in buildings:
		var building_ui_inst: SingleBuildingUI = building_ui_scene.instantiate()
		$VBoxContainer.add_child(building_ui_inst)
		building_ui_inst.initialize(b)
		building_ui_inst.building_selected.connect(spawn_building_to_place)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
