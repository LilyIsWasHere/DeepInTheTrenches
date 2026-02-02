@tool
extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var cam: Camera3D = $"../SubViewport/Camera3D"
	cam.compositor.compositor_effects[0].location = mouse_pos
