class_name Workstation
extends Node3D

var operator: FootUnit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func get_unit_position() -> Vector3:
	return $UnitPos.global_position

func is_occupied() -> bool:
	return operator != null
	
func eject_operator() -> void:
	if operator == null:
		return
	
	operator.weapon.enabled = true
	operator.disconnect("died", eject_operator)
	remove_child(operator)
	get_tree().current_scene.add_child(operator)
	operator.global_position = get_unit_position()
	operator = null
	
func operate(unit: FootUnit) -> void:
	eject_operator()
	
	
	operator = unit
	operator.weapon.enabled = false
	operator.connect("died", eject_operator)
	get_tree().current_scene.remove_child(operator)
	add_child(operator)
	operator.global_position = get_unit_position()
