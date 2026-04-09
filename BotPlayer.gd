class_name BotPlayer
extends Player


@export var pct_excavation: float = 0.25
@export var pct_transport: float = 0.25


var item_depot_transforms: Array[Array] = [	
	[Vector3(38.470329284668, 4.81857395172119, 165.075149536133), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(71.6328887939453, 2.26973724365234, 162.414642333984), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(110.116485595703, 4.94820594787598, 161.387283325195), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(147.820938110352, 2.91354131698608, 158.280319213867), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(178.691986083984, 7.51506328582764, 158.747863769531), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(212.204345703125, 7.35420608520508, 154.496246337891), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(173.485015869141, 4.77237701416016, 182.100006103516), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(103.321617126465, 6.42527055740356, 184.66828918457), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(80.8953170776367, 5.95237159729004, 203.280044555664), Vector3(0.0, 0.0, 0.0)], 
]

var turret_transforms: Array[Array] = [
	[Vector3(53.3139991760254, 4.60818290710449, 148.870803833008), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(93.3074493408203, 3.06425189971924, 146.375946044922), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(130.941940307617, 3.22467947006226, 143.960830688477), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(164.757308959961, 5.99530982971191, 142.59553527832), Vector3(0.0, 0.0, 0.0)], 
	[Vector3(203.761459350586, 5.62372493743896, 140.081100463867), Vector3(0.0, 0.0, 0.0)], 
]

var mortar_transforms: Array[Array] = [
	[Vector3(52.5413665771484, 5.61319494247437, 183.68586730957), Vector3(0.0, 3.14159250259399, 0.0)], 
	[Vector3(91.1192016601563, 7.24423885345459, 183.806976318359), Vector3(0.0, -3.14159250259399, 0.0)], 
	[Vector3(129.603240966797, 3.0915379524231, 178.909362792969), Vector3(0.0, 3.14159250259399, 0.0)], 
	[Vector3(164.017807006836, 5.07817697525024, 180.191268920898), Vector3(0.0, 3.14159250259399, 0.0)], 
	[Vector3(195.291275024414, 5.60531139373779, 178.454559326172), Vector3(0.0, 3.14159250259399, 0.0)], 
]




var bullet_factory_transforms: Array[Array] = [
	[Vector3(72.9232330322266, 6.05450677871704, 203.811172485352), Vector3(0.0, 0.69813162088394, 0.0)], 
]

var magazine_factory_transforms: Array[Array] = [
	[Vector3(73.3375549316406, 5.33650875091553, 216.196990966797), Vector3(0.0, -0.69813162088394, 0.0)], 
]

var soldier_factory_transforms: Array[Array] = [
	[Vector3(170.057022094727, 4.93890380859375, 194.152114868164), Vector3(0.0, -0.34906563162804, 0.0)], 
]

var shell_factory_transforms: Array[Array] = [
	[Vector3(112.755477905273, 5.40182161331177, 205.964691162109), Vector3(0.0, 0.00000013411051, 0.0)], 
]


var item_depot_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/ItemDepotConstructable.tres")
var turret_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/TurretConstructable.tres")
var mortar_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/MortarConstructable.tres")

var soldier_factory_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/SoldierFactoryConstructable.tres")
var bullet_factory_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/BulletFactoryConstructable.tres")
var shell_factory_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/ShellFactoryConstructable.tres")
var magazine_factory_constructable: ConstructableBuilding = preload("res://Units/Buildings/ConstructableBuildingResources/MagazineFactoryConstructable.tres")


@export var print_info_btn: bool:
	set(value):
		print_all_unit_transforms()
		
func print_all_unit_transforms() -> String:
	for child in unit_spawner.get_children():
		(child as Unit).print_info()
	
	return ""
	
	
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CameraScene = load("res://BotPlayerCamera.tscn")
	num_starting_units = 16
	super()
	#process_input = false
	


func spawn_starting_units() -> void:
	super()
	
	for transform in item_depot_transforms:
		var constructable: ConstructableBuilding = item_depot_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
	for transform in turret_transforms:
		var constructable: ConstructableBuilding = turret_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
	for transform in mortar_transforms:
		var constructable: ConstructableBuilding = mortar_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
	for transform in bullet_factory_transforms:
		var constructable: ConstructableBuilding = bullet_factory_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
	for transform in magazine_factory_transforms:
		var constructable: ConstructableBuilding = magazine_factory_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
	for transform in shell_factory_transforms:
		var constructable: ConstructableBuilding = shell_factory_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
	for transform in soldier_factory_transforms:
		var constructable: ConstructableBuilding = soldier_factory_constructable
		var unit: BuildingUnit = unit_spawner.spawn_unit(constructable.scene.resource_path, transform[0], player_id) as BuildingUnit
		unit.global_position = transform[0]
		unit.global_rotation = transform[1]
		var construction_cost: Dictionary[InventoryItem, int] = constructable.construction_cost if constructable.construction_cost != null else {}
		unit.initialize_building(construction_cost)
		unit.is_placed = true
		unit.on_placed()
		
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
		if (!turret.is_constructed):
			break
		
		if (!turret.workstation.is_occupied()):
			var unit_idx: int = patrol_units.find_custom(func(u: FootUnit) -> bool: return (!u.is_occupied && u.active_order != FootUnit.DirectOrders.MOVE_TO_WORKSTATION))
			if (unit_idx == -1): break
			var unit_to_assign: FootUnit = patrol_units[unit_idx]
			unit_to_assign.active_order = FootUnit.DirectOrders.MOVE_TO_WORKSTATION
			unit_to_assign.designated_workstation = turret.workstation
			
	for mortar in mortar_units:
		if (!mortar.is_constructed):
			break
		
		if (!mortar.workstation.is_occupied()):
			var unit_idx: int = patrol_units.find_custom(func(u: FootUnit) -> bool: return (!u.is_occupied && u.active_order != FootUnit.DirectOrders.MOVE_TO_WORKSTATION))
			if (unit_idx == -1): break
			var unit_to_assign: FootUnit = patrol_units[unit_idx]
			unit_to_assign.active_order = FootUnit.DirectOrders.MOVE_TO_WORKSTATION
			unit_to_assign.designated_workstation = mortar.workstation
			
			
		
		var rand_target_unit: Unit = LineOfSightManager.unit_arrs[0].get(randi_range(0, LineOfSightManager.unit_arrs[0].size() - 1))
		var rand_target_pos: Vector3 = rand_target_unit.global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
		(mortar as MortarUnit).set_target(rand_target_pos)
			

	
	
	#
