extends MoveableUnit
class_name AIControllerExampleUnit

@export var weapon : Weapon


enum DirectOrders {
	NONE,
	MOVE_DIRECT,
	MOVE_SAFE,
	ATTACK,
	HOLD
}

enum UnitRoles {
	PATROL,
	EXCAVATE,
	RESOURCE_TRANSPORT,
}

var active_order: DirectOrders = DirectOrders.NONE

var active_role: UnitRoles = UnitRoles.PATROL

var move_destination: Vector3

func _ready() -> void:
	super()
	
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
		.set_enter_function(get_nearest_dig_point)
		
	var resource_transport_role_state := execute_role_state.add_child_state(AIState.create("resource_transport_role"))
	
	var role_states: Array[AIState] = [patrol_role_state, excavate_role_state, resource_transport_role_state]
	AIState.add_transition_to(role_states, patrol_role_state, func()->bool: return active_role == UnitRoles.PATROL )
	AIState.add_transition_to(role_states, excavate_role_state, func()->bool: return active_role == UnitRoles.EXCAVATE )
	AIState.add_transition_to(role_states, resource_transport_role_state, func()->bool: return active_role == UnitRoles.RESOURCE_TRANSPORT )
	
	#################################
	### EXCAVATE ROLE CHILD STATES ##
	#################################
	var move_to_dig_point_state := excavate_role_state.add_child_state(AIState.create("move_to_dig_point")) \
		.set_tick_function(move_safe_tick_fn) \
		# enter functions can be lambdas too
		.set_enter_function(func() -> void: move_destination = get_nearest_dig_point())
		
	var dig_at_point_state := excavate_role_state.add_child_state(AIState.create("dig_at_point")) \
		.set_tick_function(dig_at_point_tick_fn)
		
	move_to_dig_point_state.add_transition(dig_at_point_state, within_range_of_dig_point)
	dig_at_point_state.add_transition(move_to_dig_point_state, func()->bool: return !within_range_of_dig_point())
		
	
	
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
	
func move_direct_tick_fn() -> void:
	pass
	
func move_safe_tick_fn() -> void:
	pass

func hold_tick_fn() -> void:
	pass
	
func get_patrol_destination() -> void:
	move_destination = Vector3(1,2,3)
	
func get_nearest_dig_point() -> Vector3:
	return Vector3()
	
func dig_at_point_tick_fn() -> void:
	pass

func within_range_of_dig_point() -> bool:
	return false
