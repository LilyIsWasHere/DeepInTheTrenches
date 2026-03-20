extends MoveableUnit
class_name FootUnit

@export var weapon : Weapon

var active_order: DirectOrders = DirectOrders.NONE
var role: FootUnitRoles = FootUnitRoles.EXCAVATE

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
const dig_delay: float = 0.25


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
		
	move_to_dig_point_state.add_transition(dig_at_point_state, within_range_of_dig_point)
	dig_at_point_state.add_transition(move_to_dig_point_state, is_dig_point_fully_excavated)
	
	move_to_dig_point_state.add_transition(dig_idle_state, func()->bool: return !dig_point_info["exists"])
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
		move_target_pos = dig_point_info["location"]

func dig_at_point_tick_fn() -> void:
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	var height_delta: float = dig_point_info["height_delta"]
	
	if (dig_timer.is_stopped()):
		terrain.sculpt_terrain(dig_point_info["location"], dig_radius, dig_amount * sign(height_delta), Vector2(min(height_delta, 0), abs(height_delta)), resource_extractor)
		dig_timer.start(dig_delay)

func within_range_of_dig_point() -> bool:
	var pos: Vector3 = global_position
	var distance: float = Vector2(dig_point_info["location"].x, dig_point_info["location"].z).distance_to(Vector2(pos.x, pos.z)) 
	return distance <= dig_point_range
	
func is_dig_point_fully_excavated() -> bool:
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	var point: Vector3 = dig_point_info["location"]
	
	var data: Dictionary = terrain.get_terrain_data(point)
	if (dig_point_info["height_delta"] >= 0.0):
		return data.height - data.initial_height >= dig_point_info["height_delta"] - 0.01
	else:
		return data.height - data.initial_height <= dig_point_info["height_delta"] + 0.01
	
