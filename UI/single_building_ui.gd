@tool

class_name SingleBuildingUI
extends HBoxContainer

var constructable_building: ConstructableBuilding

signal building_selected(building: ConstructableBuilding)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var button_up_sig: Signal = $Button.button_up
	button_up_sig.connect(func()->void: 
		print("Button Pressed") 
		building_selected.emit(constructable_building)
	)
	
	pass # Replace with function body.

func initialize(building: ConstructableBuilding) -> void:
	
	constructable_building = building
	
	$Button/HBoxContainer/BuildingIcon.texture = building.icon	
	$Button/HBoxContainer/VBoxContainer/BuildingName.text = building.name
	
	var item_cost_icon_scene: PackedScene = load("res://UI/ItemCostIcon.tscn")
	for item: InventoryItem in building.construction_cost.keys():
		var qty: int = building.construction_cost[item]
		
		var item_cost_icon_inst: ItemCostIcon = item_cost_icon_scene.instantiate()
		$Button/HBoxContainer/VBoxContainer/HBoxContainer.add_child(item_cost_icon_inst)
		item_cost_icon_inst.initialize(item, qty)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
