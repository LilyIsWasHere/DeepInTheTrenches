extends BuildingUnit

@export var weapon : Weapon

@export var workstation: Workstation

var in_sights_angle_threshold: float = 0.01
var max_rotation_speed: float = PI

func negate(f: Callable) -> Callable:
	return (func()->bool: return !f.call())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	init_ai_states()
	add_to_group("can_attack")
	connect("died", destroyed)

func shoot_at_point(point : Vector3) -> void:
	weapon.shoot(point)

func init_ai_states() -> void:
	
	var base_state := AIState.create("base")
	ai_controller.set_base_state(base_state)
	
	var await_operator_state := base_state.add_child_state(AIState.create("await_operator"))
	var under_operation_state := base_state.add_child_state(AIState.create("under_operation_state"))
	
	await_operator_state.add_transition(under_operation_state, func()->bool: return true)
	#under_operation_state.add_transition(await_operator_state, negate(workstation.is_occupied))
	
	
	########################
	### Operation States ###
	########################
	
	var no_visible_enemy_state := under_operation_state.add_child_state(AIState.create("no_visible_enemy"))
	var rotate_towards_enemy_state := under_operation_state.add_child_state(AIState.create("rotate_towards_enemy"))\
		.set_tick_function(rotate_towards_enemy_tick_fn)
	var fire_at_enemy_state := under_operation_state.add_child_state(AIState.create("fire_at_enemy")) \
		.set_tick_function(fire_at_enemy_tick_fn)
		
		
		
	no_visible_enemy_state.add_transition(rotate_towards_enemy_state, enemy_visible)
	rotate_towards_enemy_state.add_transition(no_visible_enemy_state, negate(enemy_visible))
	fire_at_enemy_state.add_transition(no_visible_enemy_state, negate(enemy_visible))
	
	rotate_towards_enemy_state.add_transition(fire_at_enemy_state, enemy_in_sights)
	fire_at_enemy_state.add_transition(rotate_towards_enemy_state, negate(enemy_in_sights))
	
	
	

func enemy_in_sights() -> bool:
	var enemy: Unit = LineOfSightManager.get_closest_visible_enemy(self)
	var enemy_dir: Vector3 = (enemy.global_position - global_position).normalized()
	var look_dir: Vector3 = -global_transform.basis.z
	var angle_diff: float = enemy_dir.angle_to(look_dir)
	return angle_diff <= in_sights_angle_threshold
	

func rotate_towards_enemy_tick_fn() -> void:
	if !(workstation.is_occupied()):
		return
	
	var enemy: Unit = LineOfSightManager.get_closest_visible_enemy(self)
	if (!enemy):
		return
		
	var enemy_dir: Vector3 = (enemy.global_position - global_position).normalized()
	var look_dir: Vector3 = -global_transform.basis.z
	var angle_diff: float = look_dir.angle_to(enemy_dir)
	
	var max_rot_this_frame: float = max_rotation_speed * get_process_delta_time()
	var rot_amt: float = min(max_rot_this_frame, angle_diff)
	
	var rot_step: float = rot_amt / angle_diff 
	if (angle_diff == 0): rot_step = 0
	
	var old_basis: Basis = global_transform.basis
	var new_basis: Basis = Basis.looking_at(enemy_dir)
	var intermediate_basis: Basis = lerp(old_basis, new_basis, rot_step).orthonormalized()
	global_transform.basis = intermediate_basis
	assert(intermediate_basis.is_conformal() && intermediate_basis.is_finite())
	
func fire_at_enemy_tick_fn() -> void:
	if !(workstation.is_occupied()):
		return
	
	rotate_towards_enemy_tick_fn()
	var enemy: Unit = LineOfSightManager.get_closest_visible_enemy(self)
	if (enemy):
		weapon.shoot(enemy.global_position)

func enemy_visible() -> bool:
	return LineOfSightManager.get_closest_visible_enemy(self) != null

func destroyed() -> void:
	$Workstation.eject_operator()
	visible = false

func _process(delta: float) -> void:
	super(delta)
