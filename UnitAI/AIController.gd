class_name AIController
extends Node


var base_state: AIState

func _init() -> void:
	name = "AIController"

func set_base_state(_base_state: AIState) -> void:
	base_state = _base_state
	add_child(base_state)

	
	
func _process(delta: float) -> void:
	if (base_state):
		base_state.state_tick()



#func add_state(name: String, tick_function: Callable, enter_function: Callable = Callable(), exit_function: Callable = Callable()) -> AIState:
	#var state: AIState = AIState.create(name, tick_function, enter_function, exit_function)
	#
	#
	#var state_idx: int = states.find_custom(func (state: AIState)->bool: return state.name == name)
	#assert(state_idx == -1, "Failed to add state " + name + ". AI Controller already has a state with this name")
	#if (state_idx != -1):
		#return
	#
	#states.append(state)
	#return state        
#
#
#func add_transition(from_state: AIState, to_state: AIState, condition: Callable) -> void:
	#if (!states.has(to_state)):
		#assert(false, "to_state " + to_state.name + " is not a state in this AI Controller. Transition could not be added.")
		#return
		#
	#if (!states.has(to_state)):
		#assert(false, "from_state " + to_state.name + " is not a state in this AI Controller. Transition could not be added.")
		#return
		#
	#from_state.add_transition(to_state, condition)
		#
		#
#func add_transition_by_name(from_state_name: String, to_state_name: String, condition: Callable) -> void:
	#var to_state_idx: int = states.find_custom(func (state: AIState)->bool: return state.name == to_state_name)
	#if (to_state_idx == -1):
		#assert(false, "to_state_name" + to_state_name + " could not be found in this AI Controller. Transition could not be added.")
	#
	#var from_state_idx: int = states.find_custom(func (state: AIState)->bool: return state.name == from_state_name)
	#if (from_state_idx == -1):
		#assert(false, "to_state_name " + from_state_name + " could not be found in this AI Controller. Transition could not be added.")
	#
	#add_transition(states[to_state_idx], states[from_state_idx], condition)
	#
	#
#func add_signal_transition(from_state: AIState, to_state: AIState, sig: Signal) -> void:
	#if (!states.has(to_state)):
		#assert(false, "to_state " + to_state.name + " is not a state in this AI Controller. Transition could not be added.")
		#return
		#
	#if (!states.has(to_state)):
		#assert(false, "from_state " + to_state.name + " is not a state in this AI Controller. Transition could not be added.")
		#return
		#
	#from_state.add_signal_transition(to_state, sig)
	#
	#
#func add_signal_transition_by_name(from_state_name: String, to_state_name: String, sig: Signal) -> void:
	#var to_state_idx: int = states.find_custom(func (state: AIState)->bool: return state.name == to_state_name)
	#if (to_state_idx == -1):
		#assert(false, "to_state_name" + to_state_name + " could not be found in this AI Controller. Transition could not be added.")
	#
	#var from_state_idx: int = states.find_custom(func (state: AIState)->bool: return state.name == from_state_name)
	#if (from_state_idx == -1):
		#assert(false, "to_state_name " + from_state_name + " could not be found in this AI Controller. Transition could not be added.")
	#
	#add_signal_transition(states[to_state_idx], states[from_state_idx], sig)	
	#
#func _transition_state(to_state: AIState) -> void:
	#active_state.exit_function.call()
	#to_state.enter_function.call()
	#to_state.signal_transition_triggered.connect(_on_signal_transition_triggered)
	#active_state.signal_transition_triggered.disconnect(_on_signal_transition_triggered)
	#active_state = to_state
	#
#func _on_signal_transition_triggered(to_state: AIState) -> void:
	#_transition_state(to_state)
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#
	#var should_transition: Dictionary = active_state.check_transition()
	#if (should_transition["should"]):
		#_transition_state(should_transition["to"])
