class_name BotPlayer
extends Player


@export var pct_excavation: float = 0.25
@export var pct_transport: float = 0.25


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CameraScene = load("res://BotPlayerCamera.tscn")
	super()
	process_input = false
	
	var unit_spawn_pos: Vector3 = Vector3(132.742, 16.577, 165.993)
	
	for i in range(num_starting_units):
		var offset:  Vector3 = Vector3(randf_range(-10, 10), 10, randf_range(-10, 10))
		unit_spawner.spawn_unit(foot_unit_scene_path, unit_spawn_pos + offset, player_id)
	
func _process(delta: float) -> void:
	
	var units: Array[Unit] = LineOfSightManager.unit_arrs[1]
	var foot_units: Array[FootUnit] = []
	var transport_units: Array[FootUnit]
	var excavate_units: Array[FootUnit]
	var patrol_units: Array[FootUnit]
	
	var mortar_units: Array[MortarUnit]
	var turret_units: Array[TurretUnit]
	
	var num_excavation: int = 0
	var num_transport: int = 0
	var num_patrol: int = 0
	
	for unit in units:
		if (unit is MortarUnit):
			mortar_units.append(unit as MortarUnit)
		elif (unit is TurretUnit):
			turret_units.append(unit as TurretUnit)
		
		if (unit is FootUnit): 
			var fu: FootUnit = unit as FootUnit
			foot_units.append(fu)
			
			match(fu.role):
				FootUnit.FootUnitRoles.RESOURCE_TRANSPORT:
					num_transport += 1
					transport_units.append(fu)
				FootUnit.FootUnitRoles.EXCAVATE:
					num_excavation += 1
					excavate_units.append(fu)
				FootUnit.FootUnitRoles.PATROL:
					num_patrol += 1
					patrol_units.append(fu)
			
	var expected_excavation: int = foot_units.size() * pct_excavation
	var expected_transport: int = foot_units.size() * pct_transport
	
	if (expected_excavation > num_excavation):
		for i in range(expected_excavation - num_excavation):
			var role_swap_unit: FootUnit = patrol_units.pop_back()
			if (!role_swap_unit): continue
			role_swap_unit.role = FootUnit.FootUnitRoles.EXCAVATE
			excavate_units.append(role_swap_unit)
			
	elif (expected_excavation < num_excavation):
		for i in range(num_excavation - expected_excavation):
			var role_swap_unit: FootUnit = excavate_units.pop_back()
			if (!role_swap_unit): continue
			role_swap_unit.role = FootUnit.FootUnitRoles.PATROL
			patrol_units.push_back(role_swap_unit)
			
	if (expected_transport > num_transport):
		for i in range(expected_transport - num_transport):
			var role_swap_unit: FootUnit = patrol_units.pop_back()
			if (!role_swap_unit): continue
			role_swap_unit.role = FootUnit.FootUnitRoles.RESOURCE_TRANSPORT
			transport_units.append(role_swap_unit)
			
	elif (expected_transport < num_transport):
		for i in range(num_transport - expected_transport):
			var role_swap_unit: FootUnit = transport_units.pop_back()
			if (!role_swap_unit): continue
			role_swap_unit.role = FootUnit.FootUnitRoles.PATROL
			patrol_units.push_back(role_swap_unit)
	
		
		
	for turret in turret_units:
		if (!turret.workstation.is_occupied()):
			var unit_idx: int = patrol_units.find_custom(func(u: FootUnit) -> bool: return (!u.is_occupied && u.active_order != FootUnit.DirectOrders.MOVE_TO_WORKSTATION))
			if (unit_idx == -1): break
			var unit_to_assign: FootUnit = patrol_units[unit_idx]
			unit_to_assign.active_order = FootUnit.DirectOrders.MOVE_TO_WORKSTATION
			unit_to_assign.designated_workstation = turret.workstation
			
	for mortar in mortar_units:
		if (!mortar.workstation.is_occupied()):
			var unit_idx: int = patrol_units.find_custom(func(u: FootUnit) -> bool: return (!u.is_occupied && u.active_order != FootUnit.DirectOrders.MOVE_TO_WORKSTATION))
			if (unit_idx == -1): break
			var unit_to_assign: FootUnit = patrol_units[unit_idx]
			unit_to_assign.active_order = FootUnit.DirectOrders.MOVE_TO_WORKSTATION
			unit_to_assign.designated_workstation = mortar.workstation
			

	
	
	#
