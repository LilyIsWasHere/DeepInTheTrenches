class_name FactoryUnit
extends BuildingUnit

##What item does this factory output? (i.e. bullet factory = ammo)
@export var output_item: InventoryItem

#not sure what the intended use for this variable was vvv
#@export var output_stockpile_size: int
#current implementation doesn't use it so it's commented out for simplicity

##How much of the output item is created at once?
## (like how 1 log makes 4 planks in minecraft, output_batch_size for planks = 4)
@export var output_batch_size: int
##What ingrendients are required to make the output_item? And how many of each?
##(i.e. to make an iron shovel you need [(Iron, 1), (Sticks, 2)]
@export var input_ingredients: Dictionary[InventoryItem, int]

@export_category("Production Timing")
##Timer for triggering production (on timeout, item is created)
@export var productionTimer: Timer
##How long does the creation of one batch of output_items take? (i.e. create a batch of bullets every productionLength seconds)
@export var productionLength : float = 3.0 #production takes 3 seconds by default
##The progress bar that displays how far along this batch is (should be a child of SubViewport)
@export var productionProgressBar : ProgressBar
#i.e. 3 seconds between production of output_items



func _ready() -> void:
	super()
	
	productionTimer.connect("timeout", start_production)
	inventory.connect("itemAdded", productionTimer.start.bind(productionLength))
	if output_item:
		inventory.add_slot(output_item, 9999)
	
	for item: InventoryItem in input_ingredients.keys():
		inventory.add_slot(item, input_ingredients[item] * 100)

func _input(event: InputEvent) -> void:
	super(event)
	if event.is_action_pressed("debug_factory"):
		debug_inventory()

func _process(delta: float) -> void:
	super(delta)
	
	if (is_placed && is_constructed):
		for ingredient: InventoryItem in input_ingredients.keys():
			if (!inventory.is_item_slot_full(ingredient)):
				owning_player.item_transport_blackboard.request_dropoff(inventory, ingredient, inventory.item_slot_dict[ingredient].max_num, ItemTransportRequest.RequestPriority.HIGH, false, true)
		
	
	
	#this fills the production progress bar
	#ONLY if the production timer is running and the building has been constructed
	if productionTimer.is_stopped():
		productionProgressBar.visible = false
	elif is_constructed:
		productionProgressBar.visible = true
		var num : float = productionTimer.time_left
		var denom : float = max(productionLength, 0.05)
		productionProgressBar.value = 100 - ((num/denom) * 100)

#call this function by pressing \ (backslash)
func debug_inventory() -> void:
	print("debug inventory")
	print(input_ingredients)
	for item: InventoryItem in input_ingredients.keys():
		print("adding ", item.name)
		inventory.add_items(item, 200)


func consume_ingredients() -> void:
	for item : InventoryItem in input_ingredients.keys():
		print("Removing ", item.name)
		inventory.remove_items(item, input_ingredients[item])

func produce_output() -> void:
	if output_item != null:
		print("Creating ", output_item.name)
		var overflow: int = inventory.add_items(output_item, output_batch_size)
		owning_player.item_transport_blackboard.request_pickup(inventory, output_item, output_batch_size - overflow, ItemTransportRequest.RequestPriority.MEDIUM)

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
			#print("Insufficient ", item.name, " in ", name)
			#print(inventory.get_item_quantity(item), " < ", input_ingredients[item])
			return
	
	#otherwise, there is enough to craft at least 1 of the output item\
	#remove required input items
	consume_ingredients()
	
	#add output_batch_size worth of output_item
	produce_output()
	
	#Check if we can make another one (to know if we restart the timer)
	for item : InventoryItem in input_ingredients.keys():
		if inventory.get_item_quantity(item) < input_ingredients[item]:
			#if we don't have enough of something, get out of there
			print("Insufficient ", item.name, " in ", name)
			print(inventory.get_item_quantity(item), " < ", input_ingredients[item])
			productionTimer.stop()
			return
	
	#restart production timer to try again later
	productionTimer.start(productionLength)
