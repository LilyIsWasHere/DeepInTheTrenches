extends Node3D
class_name Cursor

var rayLength : int = 100

var currentRect : Area3D
@onready var rectPrefab : PackedScene = preload("res://Nick/selection_rect.tscn")
@export var visibleDebugMesh : bool = false

@onready var actionsDropdown : Control = $CanvasLayer/Actions
var offset : Vector2 = Vector2(50,0)
var inDropdown : bool = false

@onready var rolesDropdown : Control = $CanvasLayer/Roles

var selectedUnits : Array = []
var isMoving : bool = false
var moveMode : String = ""
var isAttacking : bool = false

var targetCursor : Texture2D = preload("res://Nick/target (1).png")
var normalCursor : Texture2D = preload("res://Nick/Cursor (1).png")

@onready var inventoryViewer : Control = $"Inventory Viewer"

var settingDigPath : bool = false

var isActive: bool
var teamID : int = 0

@onready var player : Player = get_parent()

func _ready() -> void:
	Input.set_custom_mouse_cursor(normalCursor, Input.CURSOR_ARROW, Vector2(0, 0))
	actionsDropdown.visible = false
	rolesDropdown.visible = false
	update_action_buttons()
	update_role_buttons()

func _physics_process(_delta: float) -> void:
	if !isActive:
		return
	
	for unit : Unit in selectedUnits:
		unit.is_selected(true)
	
	if inDropdown:
		return
	
	#pre select exit conditions
	# i.e. if these are occuring we don't want to handle select
	var preconditions : Array[bool]
	preconditions = [
		currentRect == null && Input.is_action_pressed("alt"),
		settingDigPath,
		isAttacking,
		isMoving
	]
	
	if preconditions.has(true):
		pass
	#have to put these methods in process in order to get persistent updates
	#(_input doesn't provide updates per frame, only on click and release)
	elif Input.is_action_just_pressed("ToolClick"):
		var pos : Vector3 = get_world_pos()
		#initialize the selection rect
		if currentRect == null:
			for unit : Unit in selectedUnits:
				unit.is_selected(false)
			selectedUnits = []
			
			currentRect = rectPrefab.instantiate()
			currentRect.teamID = teamID
			
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
		var units : Array = currentRect.get_selected_units()
		
		#set currentRect to null immediately in case of a quick follow-up select
		var rect : Area3D = currentRect
		rect.queue_free()
		currentRect = null
		
		update_selected_units(units)
	#bring up actions/roles
		if !(selectedUnits.is_empty()):
			rolesDropdown.visible = !actionsDropdown.visible
			actionsDropdown.visible = !actionsDropdown.visible
			inDropdown = !inDropdown
		
			var mousePos : Vector2 = get_viewport().get_mouse_position()
			actionsDropdown.position = mousePos + offset
			rolesDropdown.position = mousePos + offset*4
			
			#open relevant inventories
			handle_view_inventory()
		else:
			inventoryViewer.on_close()
	
	#Handle moving and attacking afterwards to avoid spawning a rect on moving/attack calls
	if Input.is_action_just_pressed("ToolClick") && isMoving:
		var pos : Vector3 = get_world_pos()
		for unit : Unit in selectedUnits:
			unit.move_order_destination = pos
			if moveMode == "safe":
				unit.active_order = FootUnit.DirectOrders.MOVE_SAFE
			elif moveMode == "direct":
				unit.active_order = FootUnit.DirectOrders.MOVE_DIRECT
		handle_movement(false, "")
	elif Input.is_action_just_pressed("ToolClick") && isAttacking:
		var pos : Vector3 = get_world_pos()
		for unit : Unit in selectedUnits:
			unit.shoot_at_point(pos)
		handle_attack(false)

func _input(event: InputEvent) -> void:
	if !isActive:
		return
	
	if event.is_action_pressed("BeginExcavationPath"):
		settingDigPath = true
	elif event.is_action_pressed("CommitTool"):
		settingDigPath = false
	
	if event.is_action_released("ToolClick") && inDropdown:
		rolesDropdown.visible = !actionsDropdown.visible
		actionsDropdown.visible = !actionsDropdown.visible
		inDropdown = false

func set_active(active : bool) -> void:
	isActive = active

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
	selectedUnits = units.duplicate()
	for unit : Unit in selectedUnits:
		unit.is_selected(true)
	update_action_buttons()
	update_role_buttons()

func update_action_buttons() -> void:
	actionsDropdown.disable_all()
	if selectedUnits.is_empty() == false:
		actionsDropdown.enable_all()
	
	for unit : Unit in selectedUnits:
		if !(unit.is_in_group("can_move")):
			actionsDropdown.disable_button("move")
		if !(unit.is_in_group("can_attack")):
			actionsDropdown.disable_button("attack")
		if !(unit.is_in_group("can_dig")):
			actionsDropdown.disable_button("dig")

func update_role_buttons() -> void:
	rolesDropdown.disable_all()
	if selectedUnits.is_empty() == false:
		rolesDropdown.enable_all()
	
	for unit: Unit in selectedUnits:
		if !(unit.is_in_group("foot_unit")):
			rolesDropdown.disable_all()

func handle_movement(moving : bool, mode : String) -> void:
	print(moving)
	isMoving = moving
	moveMode = mode
	isAttacking = false
	if moving:
		Input.set_custom_mouse_cursor(targetCursor, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(normalCursor, Input.CURSOR_ARROW, Vector2(0, 0))

func handle_attack(attacking : bool) -> void:
	isAttacking = attacking
	isMoving = false
	if attacking:
		Input.set_custom_mouse_cursor(targetCursor, Input.CURSOR_ARROW, Vector2(16, 16))
	else:
		Input.set_custom_mouse_cursor(normalCursor, Input.CURSOR_ARROW, Vector2(0, 0))

func handle_view_inventory() -> void:
	var resources : Dictionary
	var textures : Dictionary
	for unit : Unit in selectedUnits:
			for slot in unit.inventory.slots:
				if slot.item == null:
					pass
				elif slot.item.name == "" || slot.num == 0:
					pass
				elif resources.get(slot.item.name) == null:
					resources[slot.item.name] = slot.num
					textures[slot.item.name] = slot.item.display_icon
				else:
					resources[slot.item.name] += slot.num
	inventoryViewer.clear()
	for key : String in resources.keys():
		inventoryViewer.add_item(key, resources[key], textures[key])
	inventoryViewer.on_open()
	inventoryViewer.set_units(selectedUnits)

func handle_view_specific_inventory(unitArray : Array) -> void:
	var resources : Dictionary
	var textures : Dictionary
	for unit : Unit in unitArray:
			for slot in unit.inventory.slots:
				if slot.item == null:
					pass
				elif slot.item.name == "" || slot.num == 0:
					pass
				elif resources.get(slot.item.name) == null:
					resources[slot.item.name] = slot.num
					textures[slot.item.name] = slot.item.display_icon
				else:
					resources[slot.item.name] += slot.num
	inventoryViewer.clear()
	for key : String in resources.keys():
		inventoryViewer.add_item(key, resources[key], textures[key])
	inventoryViewer.on_open()

func handle_patrol_role() -> void:
	for unit : FootUnit in selectedUnits:
		print("Setting ", unit.name, " role to PATROL")
		unit.role = FootUnit.FootUnitRoles.PATROL

func handle_on_excavate_role() -> void:
	for unit : FootUnit in selectedUnits:
		print("Setting ", unit.name, " role to EXCAVATE")
		unit.role = FootUnit.FootUnitRoles.EXCAVATE

func handle_on_transport_role() -> void:
	for unit : FootUnit in selectedUnits:
		print("Setting ", unit.name, " role to TRANSPORT")
		unit.role = FootUnit.FootUnitRoles.RESOURCE_TRANSPORT
