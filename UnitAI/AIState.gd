class_name AIState
extends Node

static var dbg_print: bool = true

var state_name: String
var tick_function: Callable = Callable()
var enter_function: Callable = Callable()
var exit_function: Callable = Callable()

var tick_function_name: String = "None"
var enter_function_name: String = "None"
var exit_function_name: String = "None"

var transitions: Array[StateTransition]
var child_states: Array[AIState]
var default_child_state: AIState
var active_child_state: AIState

var transitions_dbg: Array[String]


var display_icon: Texture2D = null

func state_tick() -> void:
	
	if (active_child_state):
		var should_transition: Dictionary = active_child_state.check_transition()
		if (should_transition["should"]):
			_transition_state(should_transition["to"])
		
	if (tick_function.is_valid()):
		tick_function.call()
	
	if child_states.size() > 0:
		if (!default_child_state):
			default_child_state = child_states[0]
		if (!active_child_state):
			_transition_state(default_child_state)
			
		active_child_state.state_tick()
			
		

static func create(_name: String, _tick_function: Callable = Callable(), _enter_function: Callable = Callable(), _exit_function: Callable = Callable()) -> AIState:
	var ai_state: AIState = AIState.new()
	ai_state.state_name = _name
	ai_state.name = _name
	ai_state.set_tick_function(_tick_function)
	ai_state.set_enter_function(_enter_function)
	ai_state.set_exit_function(_exit_function)
	
	
	ai_state.transitions = []
	ai_state.child_states = []
	
	
	return ai_state



func get_display_icons_recursive(arr: Array[Texture2D]) -> void:
	if (display_icon):
		arr.append(display_icon)
	if (active_child_state):
		active_child_state.get_display_icons_recursive(arr)
	return

func set_display_icon(icon: Texture2D) -> AIState:
	display_icon = icon
	return self
	

func set_tick_function(f: Callable) -> AIState:
	tick_function = f
	if (f.is_valid()):
		tick_function_name = f.get_method()
	return self
	
func set_enter_function(f: Callable) -> AIState:
	enter_function = f
	if (f.is_valid()):
		enter_function_name = f.get_method()
	return self
	
func set_exit_function(f: Callable) -> AIState:
	exit_function = f
	if (f.is_valid()):
		exit_function_name = f.get_method()
	return self

func add_child_state(child_state: AIState) -> AIState:
	child_states.append(child_state)
	add_child(child_state)
	return child_state

func add_transition(to_state: AIState, condition: Callable) -> AIState:
	if (to_state == self):
		assert(false, "Cannot add a self->self state transition")
		return self
	transitions.append(StateTransition.create(to_state, condition))
	
	transitions_dbg.append(to_state.state_name + " if " + condition.get_method())
	
	return self
	
static func add_transition_to(add_to: Array[AIState], to_state: AIState, condition: Callable) -> void:
	for from_state in add_to:
		if from_state != to_state:
			from_state.add_transition(to_state, condition)

func check_transition() -> Dictionary:
	var should_transition: bool = false
	var to_state: AIState = null
	
	for t in transitions:
		var cond_result: bool = t.condition.call()
		if (cond_result):
			should_transition = true
			to_state = t.to_state
			break
	
	return {"should": should_transition, "to": to_state}
	
	
func _transition_state(to_state: AIState) -> void:
	print((active_child_state.state_name if active_child_state else "unset") + " -> " + to_state.state_name)
	if (active_child_state && active_child_state.exit_function.is_valid()):
		active_child_state.exit_function.call()
		
	if (to_state.enter_function.is_valid()):
		to_state.enter_function.call()
		
	active_child_state = to_state
