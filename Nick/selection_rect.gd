extends Area3D

var startPos : Vector3
var currentMin : float
var currentMax : float
var selectedUnits : Array = []

@export_range(1, 32) var selectablesLayer : int

#there are edge cases in which this implemenation would not detect a troop beneath the rect
#(i.e. if there is a deep hole containing the troop that the cursor does not mouse over
#if this is likely to be the case, set minimumHeight to the distance between the levels highest and lowest points
#(else just leave it at 1)
@export_range(1,9223372036854775807) var minimumHeight : float

func _ready() -> void:
	collision_mask = selectablesLayer

func update_pos(pos : Vector3) -> void:
	#when the cursor's raycast function fails it returns (0,0,0). Don't do anything in this case
	if pos == Vector3.ZERO:
		return
	
	currentMin = min(currentMin, min($CollisionShape3D.global_position.y, pos.y))
	currentMax = max(currentMax, max($CollisionShape3D.global_position.y, pos.y))
	
	var x : float = ((startPos + pos)/2).x
	var y : float = (currentMin + currentMax)/2
	var z : float = ((startPos + pos)/2).z
	#do y seperately (needs to be on lowest level we've seen to avoid glossing over stuff)
	
	#centers the selection rect between it's origin and the given position
	$CollisionShape3D.global_position = Vector3(x,y,z)
	$DebugMesh.global_position = Vector3(x,y,z)

func update_size(pos : Vector3) -> void:
	#when the cursor's raycast function fails it returns (0,0,0). Don't do anything in this case
	if pos == Vector3.ZERO:
		return
	
	#determines scale by finding the difference between the origin and current position
	# also adds a little buffer (i.e. don't want rect to stop right below ground, have it be a bit bigger)
	var x : float = abs(startPos.x - pos.x) + 0.5
	var y : float = abs(currentMax - currentMin) + 0.5
	var z : float = abs(startPos.z - pos.z) + 0.5
	$CollisionShape3D.shape.size = Vector3(max(x,1), max(y,minimumHeight), max(z,1))
	$DebugMesh.scale = Vector3(max(x,1), max(y,minimumHeight), max(z,1))

func set_start_pos(pos : Vector3) -> void:
	startPos = pos
	global_position = pos
	
	currentMin = pos.y
	currentMax = pos.y

func set_debug_mesh_visibility(isVisible : bool) -> void:
	$DebugMesh.visible = isVisible

func get_selected_units() -> Array:
	return selectedUnits


func _on_area_entered(area: Area3D) -> void:
	selectedUnits.push_back(area)


func _on_area_exited(area: Area3D) -> void:
	selectedUnits.erase(area)
