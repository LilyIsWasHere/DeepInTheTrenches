extends Node3D

var rayLength : int = 100

var currentRect : Area3D
@onready var rectPrefab : PackedScene = preload("res://Nick/selection_rect.tscn")
@export var visibleDebugMesh : bool = false

@onready var actionsDropdown : Control = $Actions
var offset : Vector2 = Vector2(50,0)
var inDropdown : bool = false

var selectedUnits : Array = []
var isMoving : bool = false

var targetCursor : Texture2D = preload("res://Nick/target (1).png")
var normalCursor : Texture2D = preload("res://Nick/Cursor (1).png")

func _ready() -> void:
	Input.set_custom_mouse_cursor(normalCursor, Input.CURSOR_ARROW, Vector2(0, 0))
	actionsDropdown.visible = false

func _physics_process(_delta: float) -> void:
	#if we're in dropdown, don't process select
	if inDropdown:
		return
	
	if Input.is_action_just_pressed("ToolClick") && isMoving:
		var pos : Vector3 = get_world_pos()
		for unit : Unit in selectedUnits:
			unit.move_to_point(pos)
		handle_movement(false)
		return
	
	#have to put these methods in process in order to get persistent updates
	#(_input doesn't provide updates per frame, only on click and release)
	if Input.is_action_just_pressed("ToolClick"):
		var pos : Vector3 = get_world_pos()
		#initialize the selection rect
		if currentRect == null:
			currentRect = rectPrefab.instantiate()
			
			currentRect.set_debug_mesh_visibility(visibleDebugMesh)
			get_tree().current_scene.add_child(currentRect)
			#start pos is used to scale the rect later (need an origin)
			currentRect.set_start_pos(pos)
	elif Input.is_action_pressed("ToolClick") && currentRect != null:
		var pos : Vector3 = get_world_pos()
		#update the position and size of the selection rect to reach the current position
		currentRect.update_pos(pos)
		currentRect.update_size(pos)
	elif Input.is_action_just_released("ToolClick") && currentRect != null:
		#on release, get selected units from selection rect and get rid of it
		update_selected_units(currentRect.get_selected_units())
		
		#set currentRect to null immediately in case of a quick follow-up select
		var rect : Area3D = currentRect
		rect.queue_free()
		currentRect = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ToolAltClick"):
		print("1")
		actionsDropdown.visible = !actionsDropdown.visible
		inDropdown = !inDropdown
		
		var mousePos : Vector2 = get_viewport().get_mouse_position()
		actionsDropdown.position = mousePos + offset
		
		#debug (ensure the selected units are effected by dropdown)
		if inDropdown:
			print(selectedUnits)
	
	if event.is_action_released("ToolClick") && inDropdown:
		print("3")
		actionsDropdown.visible = !actionsDropdown.visible
		inDropdown = false

#	casts a ray from the camera (in view direction)
#	and returns the position where it first collides with an object
func get_world_pos() -> Vector3:
	var camera : Camera3D = get_viewport().get_camera_3d()
	var mousePos : Vector2 = get_viewport().get_mouse_position()
	
	var rayOrigin : Vector3 = camera.project_ray_origin(mousePos)
	var rayDir : Vector3 = camera.project_ray_normal(mousePos)
	var rayEnd : Vector3 = rayOrigin + rayDir * rayLength
	
	var spaceState := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
	var result := spaceState.intersect_ray(query)
	
	if result:
		return result["position"]
	else:
		return Vector3.ZERO

func update_selected_units(units : Array) -> void:
	#commented lines were for letting the unit know they were selected
	#(so that they can activate a highlight shader or however we wanna indicate it)
	
	#for unit in selectedUnits:
	#	unit.set_selected(false)
	
	selectedUnits = units.duplicate()
	
	#for unit in selectedUnits:
	#	unit.set_selected(true)

func handle_movement(moving : bool) -> void:
	isMoving = moving
	if moving:
		Input.set_custom_mouse_cursor(targetCursor, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(normalCursor, Input.CURSOR_ARROW, Vector2(0, 0))
