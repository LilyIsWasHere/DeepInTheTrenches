class_name Workstation
extends Node3D

var operator: FootUnit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass	
	
	
func is_occupied() -> bool:
	return operator != null
	
func eject_operator() -> void:
	
	remove_child(operator)
	get_tree().current_scene.add_child(operator)
	operator = null
	
func operate(unit: FootUnit) -> void:
	eject_operator()
	
	operator = unit
	get_tree().current_scene.remove_child(operator)
	add_child(operator)
	
	
