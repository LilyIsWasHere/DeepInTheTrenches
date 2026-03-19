class_name StateTransition
extends Object

var condition: Callable
var to_state: AIState

static func create(_to_state: AIState, _condition: Callable) -> StateTransition:
	var st: StateTransition = StateTransition.new()
	st.to_state = _to_state
	st.condition = _condition
	return st
