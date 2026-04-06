extends FactoryUnit

@export var FootUnitSpawnPos : Node3D

func spawn_foot_unit() -> void:
	MultiplayerSpawnerManager.unit_spawners[team].spawn_unit("res://Units/FootUnit.tscn", FootUnitSpawnPos.global_position, team)

func start_production() -> void:
	if !is_constructed:
		#only produce stuff if the building has been constructed
		return
	
	if !(productionTimer.is_stopped()):
		#already processing production, don't double craft
		return
	
	#Otherwise, check if we have enough to create batch_size of output_item
	for item : InventoryItem in input_ingredients.keys():
		if inventory.get_item_quantity(item) < input_ingredients[item]:
			#if we don't have enough of something, get out of there
			print("Insufficient ", item.name, " in ", name)
			print(inventory.get_item_quantity(item), " < ", input_ingredients[item])
			return
	
	#otherwise, there is enough to craft at least 1 of the output item\
	#remove required input items
	for item : InventoryItem in input_ingredients.keys():
		print("Removing ", item.name)
		inventory.remove_items(item, input_ingredients[item])
	#spawn a foot unit
	spawn_foot_unit()
	
	#Check if we can make another one (to know if we restart the timer)
	for item : InventoryItem in input_ingredients.keys():
		if inventory.get_item_quantity(item) < input_ingredients[item]:
			#if we don't have enough of something, get out of there
			print("Insufficient ", item.name, " in ", name)
			print(inventory.get_item_quantity(item), " < ", input_ingredients[item])
			productionTimer.stop()
			return
	
	#restart production timer to try again later
	productionTimer.start(max(productionLength, 0.05))
