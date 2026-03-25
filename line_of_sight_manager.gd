extends Node3D

@export var visualize_los: bool = true
@export var max_raycasts_per_tick: int = 100

var raycasts_this_tick: int = 0

var last_los_idx_player: int = 0
var last_los_idx_enemy: int = 0


var unit_arrs: Array[Array] = []

var unit_last_seen_by: Dictionary[Unit, Unit]

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	var arr0: Array[Unit]
	var arr1: Array[Unit]
	unit_arrs.append(arr0)
	unit_arrs.append(arr1)


# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(_delta: float) -> void:
	pass


func register_unit(unit: Unit, player_id: int) -> void:
	unit_arrs[player_id].append(unit)
	
	
	

func unregister_unit(unit: Unit) -> void:
	unit_arrs[0].erase(unit)
	unit_arrs[1].erase(unit)

	
func check_los(a: Unit, b: Unit) -> bool:
	raycasts_this_tick += 1
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var origin: Vector3 = a.LineOfSightTarget.global_position
	var target: Vector3 = b.LineOfSightTarget.global_position
	
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.hit_back_faces = false
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	else:
		# maybe there's some collisions that are ok? Probably wanna manage that with channels though
		return false


func get_enemy_unit_visibility(player_id: int) -> Array[Array]:
	var player_arr: Array = unit_arrs[player_id]
	var enemy_arr: Array = unit_arrs[(player_id + 1) % 2]
	
	var visible_units: Array[Unit]
	var hidden_units: Array[Unit]
	
	raycasts_this_tick = 0
	
	var last_e: int = last_los_idx_enemy
	var last_p: int = last_los_idx_player
	
	var break_enemy: bool = false
	var first_enemy_iter_this_tick: bool = true
	
	for i in range(last_los_idx_enemy, unit_arrs[1].size()):
		last_e = i
		var eu: Unit = unit_arrs[1][i]
		var is_visible: bool = false
		
		
		if (unit_last_seen_by.has(eu) && unit_last_seen_by[eu] != null):
			if (check_los(unit_last_seen_by[eu], eu)):
				visible_units.append(eu)
				is_visible = true
				if (visualize_los):
					DebugDraw3D.draw_line(unit_last_seen_by[eu].LineOfSightTarget.global_position, eu.LineOfSightTarget.global_position, Color(0,255,0), 0.2)
				
				last_p = unit_arrs[0].size()
				last_e = i+1
				continue
			
		var player_loop_begin_idx: int = last_los_idx_player if first_enemy_iter_this_tick else 0		
		first_enemy_iter_this_tick = false
		
		for j in range(last_los_idx_player, unit_arrs[0].size()):
			last_p = j
			var pu: Unit = unit_arrs[0][j]
			
			if (raycasts_this_tick >= max_raycasts_per_tick):
				break_enemy = true
				break
			
			if (check_los(pu, eu)):
				visible_units.append(eu)
				is_visible = true
				unit_last_seen_by[eu] = pu
				if (visualize_los):
					DebugDraw3D.draw_line(pu.LineOfSightTarget.global_position, eu.LineOfSightTarget.global_position, Color(255,0,0), 0.2)

				break
				
		if (break_enemy):
			break
			
		if (!is_visible):
			hidden_units.append(eu)
	
	last_los_idx_player = last_p
	last_los_idx_enemy = last_e
	
	# If the player unit index we checked is the last in the array, wrap around to the beginning
	if (last_los_idx_player >= unit_arrs[0].size()-1):
		last_los_idx_player = 0
		
		#If the above is true, AND we're at the final enemy unit, wrap it to the beginning as well
		if (last_los_idx_enemy >= unit_arrs[1].size()-1):
			last_los_idx_enemy = 0
	
	return [visible_units, hidden_units]
	
func set_unit_vis_from_los(player_id: int) -> void:
	var vis := get_enemy_unit_visibility(player_id)
	
	var visible: Array[Unit] = vis[0]
	var hidden: Array[Unit] = vis[1]
	
	for v in visible:
		v.set_hidden(false)
		
	for h in hidden:
		h.set_hidden(true)
	


func get_closest_enemy_in_los(to_unit: Unit) -> Unit:
	
	var enemy_arr: Array[Unit] = unit_arrs[(to_unit.team + 1) % 2]
	var dist_sorted_enemies: Array[Unit] = enemy_arr.duplicate()
	dist_sorted_enemies.sort_custom(func(a: Unit, b: Unit)->bool:  return to_unit.global_position.distance_to(a.global_position) < to_unit.global_position.distance_to(b.global_position))          
	
	for enemy in enemy_arr:
		var los: bool = check_los(to_unit, enemy)
		if (los):
			unit_last_seen_by[to_unit] = enemy
			unit_last_seen_by[enemy] = to_unit
			return enemy
			
	return null	
	
