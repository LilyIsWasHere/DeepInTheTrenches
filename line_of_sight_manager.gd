extends Node3D

@export var visualize_los: bool = false
@export var max_raycasts_per_tick: int = 100

var raycasts_this_tick: int = 0
var last_los_idx_player: Array[int] = [0,0]
var last_los_idx_enemy: Array[int] = [0,0]

var unit_arrs: Array[Array] = []

var unit_last_seen_by: Dictionary[Unit, Unit]

var unit_closest_visible_enemy:Array[Dictionary]

var units_seen_this_frame: Array[Dictionary]

var should_update_closest: bool = false

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	var arr0: Array[Unit]
	var arr1: Array[Unit]
	unit_arrs.append(arr0)
	unit_arrs.append(arr1)
	
	units_seen_this_frame = [{}, {}]
	unit_closest_visible_enemy = [{}, {}]

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(_delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	_get_enemy_unit_visibility(0)
	_get_enemy_unit_visibility(1)
	
	if (should_update_closest):
		update_closest_visible_enemy_dict(0)
		update_closest_visible_enemy_dict(1)
		units_seen_this_frame[0].clear()
		units_seen_this_frame[1].clear()
		should_update_closest = false

func register_unit(unit: Unit, player_id: int) -> void:
	unit_arrs[player_id].append(unit)
	
	
	

func unregister_unit(unit: Unit) -> void:
	unit_arrs[0].erase(unit)
	unit_arrs[1].erase(unit)
	
	unit_last_seen_by.erase(unit_last_seen_by.find_key(unit))
	unit_last_seen_by.erase(unit)
	
	var ucve0_key: Unit = unit_closest_visible_enemy[0].find_key(unit)
	while (ucve0_key):
		ucve0_key = unit_closest_visible_enemy[0].find_key(unit) 
		unit_closest_visible_enemy[0].erase(ucve0_key)
		ucve0_key = unit_closest_visible_enemy[0].find_key(unit)
	unit_closest_visible_enemy[0].erase(unit)
	
	
	var ucve1_key: Unit =unit_closest_visible_enemy[1].find_key(unit)
	while (ucve1_key):
		ucve1_key = unit_closest_visible_enemy[1].find_key(unit)
		unit_closest_visible_enemy[1].erase(ucve1_key)
		ucve1_key = unit_closest_visible_enemy[1].find_key(unit)
	unit_closest_visible_enemy[1].erase(unit)
	
	units_seen_this_frame[0].erase(unit)
	units_seen_this_frame[1].erase(unit)
	

	

	
func check_los(a: Unit, b: Unit) -> bool:
	raycasts_this_tick += 1
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var origin: Vector3 = a.LineOfSightTarget.global_position
	var target: Vector3 = b.LineOfSightTarget.global_position
	
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	
	query.collision_mask = 	pow(2, 1-1)
	
	query.hit_back_faces = false
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	else:
		# maybe there's some collisions that are ok? Probably wanna manage that with channels though
		return false


func _get_enemy_unit_visibility(player_id: int) -> Array[Array]:
	var enemy_id: int = (player_id + 1) % 2
	
	var player_arr: Array = unit_arrs[player_id]
	var enemy_arr: Array = unit_arrs[(player_id + 1) % 2]
	
	var visible_units: Array[Unit]
	var hidden_units: Array[Unit]
	
	raycasts_this_tick = 0
	
	var last_e: int = last_los_idx_enemy[player_id]
	var last_p: int = last_los_idx_player[player_id]
	
	var break_enemy: bool = false
	var first_enemy_iter_this_tick: bool = true
	
	for i in range(last_los_idx_enemy[player_id], unit_arrs[enemy_id].size()):

		
		last_e = i
		var eu: Unit = unit_arrs[enemy_id][i]
		var is_visible: bool = false
		
		
		if (unit_last_seen_by.has(eu) && unit_last_seen_by[eu] != null):
			var pu: Unit = unit_last_seen_by[eu]
			if (check_los(pu, eu)):
				visible_units.append(eu)
				is_visible = true
				unit_last_seen_by[eu] = pu
				units_seen_this_frame[player_id][eu] = true
				
				if (visualize_los):
					#DebugDraw3D.draw_line(unit_last_seen_by[eu].LineOfSightTarget.global_position, eu.LineOfSightTarget.global_position, Color(0,255,0, 0.2), 0.2)
					pass
				
				last_p = unit_arrs[player_id].size()
				last_e = i+1
				continue
			
		var player_loop_begin_idx: int = last_los_idx_player[player_id] if first_enemy_iter_this_tick else 0		
		first_enemy_iter_this_tick = false
		
		for j in range(last_los_idx_player[player_id], unit_arrs[player_id].size()):
			

			last_p = j
			var pu: Unit = unit_arrs[player_id][j]
			
			if (raycasts_this_tick >= max_raycasts_per_tick):
				break_enemy = true
				break
			
			if (check_los(pu, eu)):
				visible_units.append(eu)
				units_seen_this_frame[player_id][eu] = true
				unit_last_seen_by[eu] = pu

				is_visible = true
				if (visualize_los):
					DebugDraw3D.draw_line(pu.LineOfSightTarget.global_position, eu.LineOfSightTarget.global_position, Color(255,0,0), 0.2)

				break
				
		if (break_enemy):
			break
			
		if (!is_visible):
			hidden_units.append(eu)
	
	last_los_idx_player[player_id] = last_p
	last_los_idx_enemy[player_id] = last_e
	
	# If the player unit index we checked is the last in the array, wrap around to the beginning
	if (last_los_idx_player[player_id] >= unit_arrs[player_id].size()-1):
		last_los_idx_player[player_id] = 0
		
		#If the above is true, AND we're at the final enemy unit, wrap it to the beginning as well
		if (last_los_idx_enemy[player_id] >= unit_arrs[enemy_id].size()-1):
			last_los_idx_enemy[player_id] = 0
			
			# update closest enemy dict
			# Reset frame visibility cache
			should_update_closest = true
			
	
	
	
	
	return [visible_units, hidden_units]
	
	
func update_closest_visible_enemy_dict(player_id: int) -> void:
	var enemy_id: int = (player_id + 1) % 2
	unit_closest_visible_enemy[player_id].clear()
	
	var seen_eus: Array = units_seen_this_frame[player_id].keys().duplicate()
	var seen_pus: Array = units_seen_this_frame[enemy_id].keys().duplicate()
	
	seen_pus.sort_custom(func(a: Unit, b: Unit)->bool: return a.global_position.distance_to(Vector3(0,0,0)) < b.global_position.distance_to(Vector3(0,0,0)))
	
	for pu: Unit in seen_pus:
		unit_closest_visible_enemy[player_id][pu] = null
		seen_eus.sort_custom(func(a: Unit, b: Unit)->bool: return a.global_position.distance_to(pu.global_position) < b.global_position.distance_to(pu.global_position))
		for eu: Unit in seen_eus:
			if (check_los(pu, eu)):
				unit_last_seen_by[eu] = pu
				unit_closest_visible_enemy[player_id][pu] = eu
				if (visualize_los):
					if (pu.team == 0):
						DebugDraw3D.draw_line(unit_last_seen_by[eu].LineOfSightTarget.global_position, eu.LineOfSightTarget.global_position, Color(0,0,255), 0.2)
				break
				
				
	
	

func set_unit_vis_from_los(player_id: int) -> void:
	var vis := _get_enemy_unit_visibility(player_id)
	
	var visible: Array[Unit] = vis[0]
	var hidden: Array[Unit] = vis[1]
	
	for v in visible:
		v.set_hidden(false)
		
	for h in hidden:
		h.set_hidden(true)
	


func get_closest_visible_enemy(to_unit: Unit) -> Unit:
	return unit_closest_visible_enemy[to_unit.team].get(to_unit)
	
