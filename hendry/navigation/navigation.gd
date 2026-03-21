extends Node

# const NavPlanHandle := preload("res://hendry/navigation/types/nav_plan_handle.gd")
# const NavSteeringResult := preload("res://hendry/navigation/types/nav_steering_result.gd")

const NavMap := preload("res://hendry/navigation/nav_map.gd")
var _nav_map: NavMap = null

const DEFAULT_AGENT_RADIUS := 0.2
const DEFAULT_AGENT_HEIGHT := 1.7
const DEFAULT_AGENT_MAX_SPEED := 5.0
const DEFAULT_AGENT_MAX_SLOPE_DEGREES := 45.0
const DEFAULT_AGENT_MAX_STEP_HEIGHT := 1.0
const DEFAULT_AGENT_WALL_CLIMB_HEIGHT := 1.7

var _active_requests: Dictionary = {}
var _player_score_layers: Dictionary = {}

func _ready() -> void:
	_nav_map = NavMap.new()

# helper to get the agent config for an agent
func _get_agent_config(agent: Node) -> NavAgentConfig:
	if agent != null and agent.has_method("get_nav_agent_config"):
		return agent.get_nav_agent_config()

	return null

# helper to build the agent context for an agent
func _build_agent_context(agent: Node, agent_config: NavAgentConfig) -> Dictionary:
	if agent_config == null:
		return {}

	return agent_config.init_context(agent)

# Call this function to remove an agent from the navigation system. This will cancel any active requests for that agent and free up resources.
func remove_agent(agent: Node) -> void:
	if agent == null:
		return

	_active_requests.erase(agent)

# Call this function to request a path to a target. Returns a NavPlanHandle that can be used to track the status of the request and sample steering results.
func request_move(
	agent: Node,
	target: Vector3
) -> NavPlanHandle:
	if agent == null:
		return null

	if not agent is Node3D:
		return null

	var existing_handle: NavPlanHandle = _active_requests.get(agent, null)
	if existing_handle != null:
		cancel_request(existing_handle)

	var handle := NavPlanHandle.new()
	handle.target = target
	handle.agent = agent
	handle.agent_config = _get_agent_config(agent)
	if handle.agent_config == null:
		return null

	handle.agent_context = _build_agent_context(agent, handle.agent_config)

	_active_requests[agent] = handle

	var agent_node: Node3D = agent
	_plan_request(agent_node, handle)

	return handle


# Same as above but you can do it for a bunch of agents. Returns a dict mapping each agent to their NavPlanHandle.
func request_batch_move(
	agents: Array[Node],
	target: Vector3
) -> Dictionary:
	var result: Dictionary = {}

	for agent in agents:
		var handle := request_move(agent, target)
		if handle != null:
			result[agent] = handle

	return result

# Call this function to cancel an active path request for an agent.
func cancel_request(handle: NavPlanHandle) -> void:
	if handle == null:
		return

	handle.status = NavPlanHandle.NavRequestStatus.CANCELLED

func record_terrain_change(
	position: Vector3,
	radius: float,
	height_delta: float,
) -> void:
	if _nav_map == null:
		return

	if radius <= 0.0:
		return

	if is_zero_approx(height_delta):
		return

	# Raw terrain-change hook only.
	# Dirty-cell invalidation / nav-cache refresh will live here later.

# Apply a score stamp to a player's score layer by name.
func apply_player_score_stamp(
	player_id: int,
	layer_name: StringName,
	position: Vector3,
	radius: float,
	score_delta: float,
) -> void:
	if _nav_map == null:
		return

	if radius <= 0.0:
		return

	if is_zero_approx(score_delta):
		return

	var center_cell: Vector2i = _nav_map.world_to_cell(position)
	var player_layer: Dictionary = create_player_score_layer(player_id, layer_name)

	var cell_size: float = _nav_map.get_cell_size()
	var cell_radius: int = int(ceil(radius / cell_size))

	for z in range(-cell_radius, cell_radius + 1):
		for x in range(-cell_radius, cell_radius + 1):
			var cell: Vector2i = center_cell + Vector2i(x, z)
			var cell_position: Vector3 = _nav_map.cell_to_world(cell)
			var distance: float = Vector2(
				cell_position.x - position.x,
				cell_position.z - position.z
			).length()

			if distance > radius:
				continue

			var weight: float = 1.0 - (distance / radius)
			var old_score: float = float(player_layer.get(cell, 0.0))
			var new_score: float = max(0.0, old_score + score_delta * weight)

			if is_zero_approx(new_score):
				player_layer.erase(cell)
			else:
				player_layer[cell] = new_score

# Get a player's score layer by name.
func get_player_score_layer(player_id: int, layer_name: StringName) -> Dictionary:
	if not _player_score_layers.has(player_id):
		return {}

	var player_layers: Dictionary = _player_score_layers[player_id]
	if not player_layers.has(layer_name):
		return {}

	return player_layers[layer_name]

# Create a player's score layer if it doesn't exist and return it.
func create_player_score_layer(player_id: int, layer_name: StringName) -> Dictionary:
	if not _player_score_layers.has(player_id):
		_player_score_layers[player_id] = {}

	var player_layers: Dictionary = _player_score_layers[player_id]
	if not player_layers.has(layer_name):
		player_layers[layer_name] = {}

	return player_layers[layer_name]

# Clear a player's score layer by name.
func clear_player_score_layer(player_id: int, layer_name: StringName) -> void:
	if not _player_score_layers.has(player_id):
		return

	var player_layers: Dictionary = _player_score_layers[player_id]
	if not player_layers.has(layer_name):
		return

	player_layers[layer_name] = {}

# Clear the scores for a specific layer for all players.
func clear_all_score_layers(layer_name: StringName) -> void:
	var player_ids: Array = _player_score_layers.keys()

	for i in range(player_ids.size()):
		var player_id: int = int(player_ids[i])
		clear_player_score_layer(player_id, layer_name)

# Internal function to handle a pathfinding request. 
# This is where the actual pathfinding logic happens. 
# It will update the NavPlanHandle with the results and emit the appropriate signals.
func _plan_request(agent: Node3D, handle: NavPlanHandle) -> void:
	var agent_config: NavAgentConfig = handle.agent_config
	if agent_config == null:
		handle.status = NavPlanHandle.NavRequestStatus.FAILED
		handle.failure_reason = "Missing nav agent config"
		handle.waypoints = PackedVector3Array()
		handle.failed.emit()
		return

	var path: PackedVector3Array = _nav_map.find_path(
		agent.global_position,
		handle.target,
		agent_config,
		handle.agent_context
	)

	if path.is_empty():
		handle.status = NavPlanHandle.NavRequestStatus.FAILED
		handle.failure_reason = "No path found"
		handle.waypoints = PackedVector3Array()
		handle.failed.emit()
		return

	handle.status = NavPlanHandle.NavRequestStatus.READY
	handle.failure_reason = ""
	handle.waypoints = path
	handle.ready.emit()

# Call this function to ask where the agent should go next. Returns a NavSteeringResult with all the info you need.
func sample_steering(
	agent: Node,
	handle: NavPlanHandle,
	_delta: float,
) -> NavSteeringResult:
	var steering := NavSteeringResult.new()

	if agent == null or handle == null:
		return steering

	if not agent is Node3D:
		return steering

	if handle.status != NavPlanHandle.NavRequestStatus.READY:
		return steering

	if handle.waypoints.is_empty():
		steering.arrived = true
		steering.next_waypoint = handle.target
		return steering

	var agent_node: Node3D = agent
	var current_position: Vector3 = agent_node.global_position
	var agent_config: NavAgentConfig = handle.agent_config

	var waypoint_tolerance: float = DEFAULT_AGENT_RADIUS
	var max_speed: float = DEFAULT_AGENT_MAX_SPEED

	if agent_config != null:
		waypoint_tolerance = agent_config.radius
		max_speed = agent_config.max_speed


	while not handle.waypoints.is_empty():
		var first_waypoint: Vector3 = handle.waypoints[0]
		if current_position.distance_to(first_waypoint) > waypoint_tolerance:
			break

		handle.waypoints.remove_at(0)
		handle.updated.emit()

	if handle.waypoints.is_empty():
		steering.arrived = true
		steering.next_waypoint = handle.target
		steering.remaining_distance = 0.0
		steering.desired_velocity = Vector3.ZERO
		return steering

	var next_waypoint: Vector3 = handle.waypoints[0]
	steering.next_waypoint = next_waypoint

	var remaining_distance: float = current_position.distance_to(next_waypoint)
	for i in range(handle.waypoints.size() - 1):
		remaining_distance += handle.waypoints[i].distance_to(handle.waypoints[i + 1])

	steering.remaining_distance = remaining_distance

	var to_waypoint: Vector3 = next_waypoint - current_position
	var distance_to_waypoint: float = to_waypoint.length()

	if distance_to_waypoint <= waypoint_tolerance:
		steering.desired_velocity = Vector3.ZERO
	else:
		steering.desired_velocity = to_waypoint.normalized() * max_speed

	return steering

# DEBUG
func debug_get_score_info(
	point: Vector3,
	agent_config: NavAgentConfig,
	player_id: int,
	layer_name: StringName
) -> Dictionary:
	var cell: Vector2i = _nav_map.world_to_cell(point)
	var player_layer: Dictionary = get_player_score_layer(player_id, layer_name)
	var raw_score: float = float(player_layer.get(cell, 0.0))
	var trench_info: Dictionary = _nav_map.debug_get_safe_trench_info(cell, agent_config)

	return {
		"cell": cell,
		"layer_name": layer_name,
		"raw_score": raw_score,
		"trench_info": trench_info,
	}

func debug_find_path(
	start: Vector3,
	goal: Vector3,
	agent: Node,
	agent_config: NavAgentConfig
) -> PackedVector3Array:
	print("Debug find path with agent:", agent)
	print("Debug find path with config:", agent_config)

	if agent_config == null:
		return PackedVector3Array()	

	var agent_context: Dictionary = {}
	if agent_config != null:
		agent_context = agent_config.init_context(agent)

	return _nav_map.find_path(start, goal, agent_config, agent_context)
