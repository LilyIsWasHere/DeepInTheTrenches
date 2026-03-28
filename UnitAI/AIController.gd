class_name AIController
extends Node


var base_state: AIState

func _init() -> void:
	name = "AIController"

func set_base_state(_base_state: AIState) -> void:
	base_state = _base_state
	add_child(base_state)

	
	
func _process(_delta: float) -> void:
	var parent: Unit = get_parent() as Unit
	if (parent && parent.alive):
		if (base_state):
			base_state.state_tick()
