extends MoveableUnit
class_name FootUnit

@export var weapon : Weapon

var active_order: DirectOrders = DirectOrders.NONE
var role: FootUnitRoles = FootUnitRoles.RESOURCE_TRANSPORT

enum DirectOrders {
	NONE,
	MOVE_DIRECT,
	MOVE_SAFE,
	ATTACK,
	HOLD
}

enum FootUnitRoles {
	PATROL,
	EXCAVATE,
	RESOURCE_TRANSPORT,
}

var dig_point_info: Dictionary
var dig_timer: Timer = Timer.new()

const dig_point_range: float = 0.5
const dig_amount: float = 3
const dig_radius: float = 15
const dig_delay: float = 1

@export var item_transport_inventory: Inventory


func _ready() -> void:
	super()
	init_ai_states()
	add_to_group("can_attack")
	add_child(dig_timer)
	dig_timer.one_shot = true
	#uncomment this vvv when we get troops digging working
	#add_to_group("can_dig")


func init_ai_states() -> void:
	
		# States are created with a name
	var base_state := AIState.create("base")
	# In order for anthing to happen, you must set the base state of the ai_controller
	ai_controller.set_base_state(base_state)
	
	# This is a heirarchical finite state machine system. States can have child states
	# Only the tick funcitons of the active state, and it's active child, etc. will execute each frame
	# Generally (but with lots of exceptions), only leaf node states (states with no child state) will have tick functions
	var self_defense_state := base_state.add_child_state(AIState.create("self_defense")) \
		.set_tick_function(attack_enemy_tick_fn) \
		.set_enter_function(on_see_enemy) \
		.set_exit_function(on_enemy_gone)
	var direct_order_state := base_state.add_child_state(AIState.create("direct_order"))
	var execute_role_state := base_state.add_child_state(AIState.create("execute_role"))

	# State transitions will occur when the provided condition function evaluates to true (checked each frame)
	# State transitions should only ever occur between sibling states (states on the same level)
	# DON'T MAKE STATE TRANSITIONS THAT MOVE UP AND DOWN THE TREE IDK WHAT WILL HAPPEN BUT IT WILL BE BAD!1!
	# The condition f unction can be a regular function passed by name, or a lambda function
	# order that transitions are added determines priority (first is highest)
	direct_order_state.add_transition(execute_role_state, func()->bool: return (active_order == DirectOrders.NONE))
	
	self_defense_state.add_transition(direct_order_state, func()->bool: return (active_order != DirectOrders.NONE))
	self_defense_state.add_transition(execute_role_state, func()->bool: return !can_see_enemy())
	
	execute_role_state.add_transition(direct_order_state, func()->bool: return (active_order != DirectOrders.NONE))
	execute_role_state.add_transition(self_defense_state, can_see_enemy)
	
	
	#################################
	### DIRECT ORDER CHILD STATES ###
	#################################
	# tick funciton, entry function and exit funciton can also be set in the .create constructor
	var move_direct_order_state := direct_order_state.add_child_state(AIState.create("move_direct_order", move_direct_tick_fn)) 
	var move_safe_order_state := direct_order_state.add_child_state(AIState.create("move_safe_order", move_safe_tick_fn)) 
	var attack_order_state := direct_order_state.add_child_state(AIState.create("attack_order", attack_order_tick_fn))
	var hold_order_state := direct_order_state.add_child_state(AIState.create("hold_order", hold_tick_fn))
	
	# when many states share a transition, you can use the AIState.add_transition_to funciton to add a transition to many states at once
	# this function will skip adding a self-transition from A->A, for ease of use
	var order_states: Array[AIState] = [move_direct_order_state, move_safe_order_state, attack_order_state, hold_order_state]
	AIState.add_transition_to(order_states, move_direct_order_state, func()->bool:return active_order == DirectOrders.MOVE_DIRECT)
	AIState.add_transition_to(order_states, move_safe_order_state, func()->bool:return active_order == DirectOrders.MOVE_SAFE)
	AIState.add_transition_to(order_states, attack_order_state, func()->bool:return active_order == DirectOrders.ATTACK)
	AIState.add_transition_to(order_states, hold_order_state, func()->bool:return active_order == DirectOrders.HOLD)
	
	#################################
	### EXECUTE ROLE CHILD STATES ###
	#################################
	var patrol_role_state := execute_role_state.add_child_state(AIState.create("patrol_role")) \
		.set_enter_function(get_patrol_destination)
		
	var excavate_role_state := execute_role_state.add_child_state(AIState.create("excavate_role")) \
		.set_enter_function(fetch_nearest_dig_point_info)
		
	var resource_transport_role_state := execute_role_state.add_child_state(AIState.create("resource_transport_role"))
	
	var role_states: Array[AIState] = [patrol_role_state, excavate_role_state, resource_transport_role_state]
	AIState.add_transition_to(role_states, patrol_role_state, func()->bool: return role == FootUnitRoles.PATROL )
	AIState.add_transition_to(role_states, excavate_role_state, func()->bool: return role == FootUnitRoles.EXCAVATE )
	AIState.add_transition_to(role_states, resource_transport_role_state, func()->bool: return role == FootUnitRoles.RESOURCE_TRANSPORT )
	
	
	###########################################
	### RESOURCE_TRANSPORT ROLE CHILD STATES ##
	###########################################
	
	var resource_transport_idle_state := resource_transport_role_state.add_child_state(AIState.create("resouce_transport_idle")) \
		.set_tick_function(try_get_transport_plan)
		
	var resource_transport_move_to_pickup := resource_transport_role_state.add_child_state(AIState.create("move_to_pickup")) \
		.set_enter_function(func()->void: set_destination_point_safe(pickup_request.inventory.global_position)) \
		.set_tick_function(move_safe_tick_fn)
	
	var resource_transport_pickup_items := resource_transport_role_state.add_child_state(AIState.create("pickup_items")) \
		.set_enter_function(fulfill_pickup)
	
	var resource_transport_move_to_dropoff := resource_transport_role_state.add_child_state(AIState.create("move_to_dropoff")) \
		.set_enter_function(func()->void: set_destination_point_safe(dropoff_request.inventory.global_position))\
		.set_tick_function(move_safe_tick_fn)
	
	var resource_transport_dropoff_items := resource_transport_role_state.add_child_state(AIState.create("dropoff_items")) \
		.set_enter_function(fulfill_dropoff)
		
		
	resource_transport_idle_state.add_transition(resource_transport_move_to_pickup, func()->bool: return pickup_request != null && dropoff_request != null)
	resource_transport_move_to_pickup.add_transition(resource_transport_pickup_items, get_arrived)
	resource_transport_pickup_items.add_transition(resource_transport_move_to_dropoff, func()->bool: return pickup_request == null && dropoff_request != null)
	resource_transport_move_to_dropoff.add_transition(resource_transport_dropoff_items, get_arrived)
	
	AIState.add_transition_to(
		[resource_transport_move_to_pickup, resource_transport_pickup_items, resource_transport_move_to_dropoff, resource_transport_dropoff_items],
		resource_transport_idle_state, 
		func()->bool: return pickup_request == null && dropoff_request == null
	)
	
	
	#################################
	### EXCAVATE ROLE CHILD STATES ##
	#################################
	var move_to_dig_point_state := excavate_role_state.add_child_state(AIState.create("move_to_dig_point")) \
		.set_tick_function(move_safe_tick_fn) \
		# enter functions can be lambdas too
		.set_enter_function(set_destination_to_nearest_dig_point_if_exists)
		
	var dig_at_point_state := excavate_role_state.add_child_state(AIState.create("dig_at_point")) \
		.set_tick_function(dig_at_point_tick_fn) \
		.set_enter_function(func()->void: dig_timer.start(dig_delay))
		
	var dig_idle_state := excavate_role_state.add_child_state(AIState.create("dig_idle")) \
		.set_tick_function(set_destination_to_nearest_dig_point_if_exists)
		
	move_to_dig_point_state.add_transition(dig_at_point_state, get_arrived)
	dig_at_point_state.add_transition(dig_idle_state, func()->bool: return !dig_point_info["exists"])
	dig_at_point_state.add_transition(move_to_dig_point_state, is_dig_point_fully_excavated)
	
	move_to_dig_point_state.add_transition(dig_idle_state, func()->bool: return !dig_point_info["exists"])
	move_to_dig_point_state.add_transition(dig_idle_state, func()-> bool: return nav_plan_handle.status == NavPlanHandle.NavRequestStatus.FAILED)
	dig_idle_state.add_transition(move_to_dig_point_state, func()->bool: return dig_point_info["exists"])
	

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)


func attack_enemy_tick_fn() -> void:
	pass	

func can_see_enemy() -> bool:
	return false
	
func on_see_enemy() -> void:
	print("ENEMY IN SIGHT!")
	
func on_enemy_gone() -> void:
	print("Must've been the wind")
	

func attack_order_tick_fn() -> void:
	pass 
	
func hold_tick_fn() -> void:
	pass
	
func get_patrol_destination() -> void:
	move_target_pos = Vector3(1,2,3)
	
func fetch_nearest_dig_point_info() -> void:
	var player: Player = GlobalPlayerManager.get_player(team)
	dig_point_info = player.excavation_path_tool.get_closest_unexcavated_path_point(global_position)
		
	
func set_destination_to_nearest_dig_point_if_exists() -> void:
	fetch_nearest_dig_point_info()
	if (dig_point_info["exists"]):
		set_destination_point_safe(dig_point_info["location"])

func dig_at_point_tick_fn() -> void:
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	if (!dig_point_info["exists"]): return
	var height_delta: float = dig_point_info["height_delta"]
	
	if (dig_timer.is_stopped()):
		terrain.sculpt_terrain(dig_point_info["location"], dig_radius, dig_amount * sign(height_delta), Vector2(min(height_delta, 0), abs(height_delta)), resource_extractor)
		dig_timer.start(dig_delay)

	
func is_dig_point_fully_excavated() -> bool:
	
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	var point: Vector3 = dig_point_info["location"]
	
	var data: Dictionary = terrain.get_terrain_data(point)
	if (dig_point_info["height_delta"] >= 0.0):
		return data.height - data.initial_height >= dig_point_info["height_delta"] - 0.01
	else:
		return data.height - data.initial_height <= dig_point_info["height_delta"] + 0.01
	
	
	
######################################
#### Resource Transport Functions ####
######################################
var pickup_request: ItemTransportRequest = null
var dropoff_request: ItemTransportRequest = null

func is_transport_plan_set() -> bool:
	return (pickup_request && dropoff_request)
	

func try_get_transport_plan() -> void:
	var pickup_dropoff: Array[ItemTransportRequest] = ItemTransportBlackboard.get_pickup_dropoff_pair(global_position)
	
	if (!pickup_dropoff.is_empty()):
		pickup_request = pickup_dropoff[0]
		dropoff_request = pickup_dropoff[1]
	
func fulfill_pickup() -> void:
	var item: InventoryItem = pickup_request.item
	
	if (!is_instance_valid(pickup_request.inventory)):
		pickup_request.abandon()
		dropoff_request.unclaim()
		pickup_request = null
		dropoff_request = null
		return
	
	
	if (!item_transport_inventory.has_slot_for_item(item)):
		item_transport_inventory.add_slot(item, item.default_inventory_capacity)
		print("WARNING: item transport inventory has no slot for " + str(item.name) + ". Creating one with default capacity of " + str(item.default_inventory_capacity))
	
	assert(pickup_request.inventory.has_slot_for_item(item))
	
	if (!pickup_request.inventory.has_item(item)):
		assert(false)
		pickup_request.abandon()
		pickup_request = null
		dropoff_request.abandon()
		dropoff_request = null
		return
			
	var transfer_result: Dictionary = Inventory.transfer_items(pickup_request.inventory, item_transport_inventory, item, pickup_request.quantity)
	
	pickup_request.fulfill(pickup_request.quantity - transfer_result["to_overflow"])
	pickup_request = null
	
	
func fulfill_dropoff() -> void:
	var item: InventoryItem = dropoff_request.item
	
	if (!is_instance_valid(dropoff_request)):
		dropoff_request.abandon()
		return
	
	assert(item_transport_inventory.has_slot_for_item(item))
	if (!dropoff_request.inventory.has_slot_for_item(item)):
		assert(false)
		print("WARNING: resource transport dropoff inventory has no slot for " + str(item.name) + ". Abandoning dropoff request.")
		dropoff_request.abandon()
		dropoff_request = null
		return
		
	var transfer_result: Dictionary = Inventory.transfer_items(item_transport_inventory, dropoff_request.inventory, item, dropoff_request.quantity)
		
	dropoff_request.fulfill(dropoff_request.quantity - transfer_result["from_underflow"])
	dropoff_request = null
	
	
	
	
	
	
	

	
	
