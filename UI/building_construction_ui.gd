@tool
class_name BuildingConstructionUI
extends Control




@export var buildings: Array[ConstructableBuilding]

# Called when the node enters the scene tree for the first time.
var building_ui_scene: PackedScene = preload("res://UI/SingleBuildingUI.tscn")



func spawn_building_to_place(building_type: ConstructableBuilding) -> void:
	var building_inst: BuildingUnit = building_type.scene.instantiate()
	$"../../..".add_child(building_inst)
	building_inst.initialize(building_type.construction_cost)
	print("spawning " + str(building_inst))
	

func _ready() -> void:
	
	for b in buildings:
		var building_ui_inst: SingleBuildingUI = building_ui_scene.instantiate()
		$VBoxContainer.add_child(building_ui_inst)
		building_ui_inst.initialize(b)
		building_ui_inst.building_selected.connect(spawn_building_to_place)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
