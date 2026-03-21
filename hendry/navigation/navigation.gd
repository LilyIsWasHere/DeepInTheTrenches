extends Node

# const NavPlanHandle := preload("res://hendry/navigation/types/nav_plan_handle.gd")
# const NavSteeringResult := preload("res://hendry/navigation/types/nav_steering_result.gd")

const NavMap := preload("res://hendry/navigation/nav_map.gd")
var _nav_map: NavMap = null

const DEFAULT_AGENT_RADIUS := 0.2
const DEFAULT_AGENT_HEIGHT := 1.7
const DEFAULT_AGENT_MAX_SPEED := 5.0
const DEFAULT_AGENT_MAX_SLOPE_DEGREES := 90.0#45.0
const DEFAULT_AGENT_MAX_STEP_HEIGHT := 1.0
const DEFAULT_AGENT_WALL_CLIMB_HEIGHT := 1.7

# Go in the trenches, or ignore the trenches?
enum NavProfileId {
	SAFE,
	DIRECT,
}

var _agent_properties: Dictionary = {}
var _active_requests: Dictionary = {}
var _player_score_components: Dictionary = {}

func _ready() -> void:
	_nav_map = NavMap.new()

# Probably don't need this function. This is only if you want to change the agent properties mid-request.
func set_agent_properties(
	agent: Node,
	radius: float = DEFAULT_AGENT_RADIUS,
	height: float = DEFAULT_AGENT_HEIGHT,
	max_speed: float = DEFAULT_AGENT_MAX_SPEED,
	max_slope_degrees: float = DEFAULT_AGENT_MAX_SLOPE_DEGREES,
	max_step_height: float = DEFAULT_AGENT_MAX_STEP_HEIGHT,
	wall_climb_height: float = DEFAULT_AGENT_WALL_CLIMB_HEIGHT
) -> void:
	if agent == null:
		return

	_agent_properties[agent] = {
		"radius": radius,
		"height": height,
		"max_speed": max_speed,
		"max_slope_degrees": max_slope_degrees,
		"max_step_height": max_step_height,
		"wall_climb_height": wall_climb_height,
	}

# Call this function to remove an agent from the navigation system. This will cancel any active requests for that agent and free up resources.
func remove_agent(agent: Node) -> void:
	if agent == null:
		return

	_agent_properties.erase(agent)
	_active_requests.erase(agent)

# Call this function to request a path to a target. Returns a NavPlanHandle that can be used to track the status of the request and sample steering results.
func request_move(
	agent: Node,
	player_id: int,
	target: Vector3,
	profile: NavProfileId = NavProfileId.SAFE,
) -> NavPlanHandle:
	if agent == null:
		return null

	if not agent is Node3D:
		return null

	if not _agent_properties.has(agent):
		set_agent_properties(agent)

	var existing_handle: NavPlanHandle = _active_requests.get(agent, null)
	if existing_handle != null:
		cancel_request(existing_handle)

	var handle := NavPlanHandle.new()
	handle.target = target
	handle.profile = profile
	handle.player_id = player_id

	_active_requests[agent] = handle

	var agent_node: Node3D = agent
	_plan_request(agent_node, handle)

	return handle


# Same as above but you can do it for a bunch of agents. Returns a dict mapping each agent to their NavPlanHandle.
func request_batch_move(
	agents: Array[Node],
	player_id: int,
	target: Vector3,
	profile: NavProfileId = NavProfileId.SAFE,
) -> Dictionary:
	var result: Dictionary = {}

	for agent in agents:
		var handle := request_move(agent, player_id, target, profile)
		if handle != null:
			result[agent] = handle

	return result

# Call this function to cancel an active path request for an agent.
func cancel_request(handle: NavPlanHandle) -> void:
	if handle == null:
		return

	handle.status = NavPlanHandle.NavRequestStatus.CANCELLED

# Call this to have terrain edits (trenches) apply for nav scores
func record_terrain_edit(
	player_id: int,
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

	var center_cell: Vector2i = _nav_map.world_to_cell(position)
	var score_delta: float = abs(height_delta)

	if height_delta < 0.0:
		var terrain_scores: Dictionary = _get_player_terrain_scores(player_id)
		_apply_score_stamp(terrain_scores, center_cell, position, radius, score_delta)
		return

	var player_ids: Array = _player_score_components.keys()
	for i in range(player_ids.size()):
		var target_player_id: int = int(player_ids[i])
		var terrain_scores: Dictionary = _get_player_terrain_scores(target_player_id)
		_apply_score_stamp(terrain_scores, center_cell, position, radius, -score_delta)

# Helper: get the score layer for a player, creating it if it doesn't exist yet
func _get_player_score_components(player_id: int) -> Dictionary:
	if not _player_score_components.has(player_id):
		_player_score_components[player_id] = {
			"terrain": {},
		}

	return _player_score_components[player_id]

# Helper: get the terrain score layer for a player
func _get_player_terrain_scores(player_id: int) -> Dictionary:
	var components: Dictionary = _get_player_score_components(player_id)
	return components["terrain"]

# Helper: apply a score stamp to a player's score layer
func _apply_score_stamp(
	player_layer: Dictionary,
	center_cell: Vector2i,
	center_position: Vector3,
	radius: float,
	score_delta: float,
) -> void:
	var cell_size: float = _nav_map.get_cell_size()
	var cell_radius: int = int(ceil(radius / cell_size))

	for z in range(-cell_radius, cell_radius + 1):
		for x in range(-cell_radius, cell_radius + 1):
			var cell: Vector2i = center_cell + Vector2i(x, z)
			var cell_position: Vector3 = _nav_map.cell_to_world(cell)
			var distance: float = Vector2(
				cell_position.x - center_position.x,
				cell_position.z - center_position.z
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

# Internal function to handle a pathfinding request. 
# This is where the actual pathfinding logic happens. 
# It will update the NavPlanHandle with the results and emit the appropriate signals.
func _plan_request(agent: Node3D, handle: NavPlanHandle) -> void:
	var agent_config: Dictionary = _agent_properties.get(agent, {})
	var terrain_scores: Dictionary = {}

	if handle.profile == NavProfileId.SAFE:
		terrain_scores = _get_player_terrain_scores(handle.player_id)

	var path: PackedVector3Array = _nav_map.find_path(
		agent.global_position,
		handle.target,
		agent_config,
		handle.profile,
		terrain_scores
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

# Clear the terrain scores for a specific player.
func clear_player_terrain_scores(player_id: int) -> void:
	if not _player_score_components.has(player_id):
		return

	var components: Dictionary = _player_score_components[player_id]
	components["terrain"] = {}

# Clear the terrain scores for all players.
func clear_all_terrain_scores() -> void:
	var player_ids: Array = _player_score_components.keys()

	for i in range(player_ids.size()):
		var player_id: int = int(player_ids[i])
		clear_player_terrain_scores(player_id)

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
	var agent_config: Dictionary = _agent_properties.get(agent, {})

	var waypoint_tolerance: float = DEFAULT_AGENT_RADIUS
	var max_speed: float = DEFAULT_AGENT_MAX_SPEED

	if not agent_config.is_empty():
		waypoint_tolerance = float(agent_config["radius"])
		max_speed = float(agent_config["max_speed"])

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
	agent_config: Dictionary,
	player_id: int
) -> Dictionary:
	var cell: Vector2i = _nav_map.world_to_cell(point)
	var terrain_scores: Dictionary = _get_player_terrain_scores(player_id)
	var raw_terrain_score: float = float(terrain_scores.get(cell, 0.0))
	var effective_safe_score: float = _nav_map.get_effective_safe_score(cell, agent_config, raw_terrain_score)
	var trench_info: Dictionary = _nav_map.debug_get_safe_trench_info(cell, agent_config)

	return {
		"cell": cell,
		"raw_terrain_score": raw_terrain_score,
		"effective_safe_score": effective_safe_score,
		"trench_info": trench_info,
	}

func debug_find_path(
	start: Vector3,
	goal: Vector3,
	agent_config: Dictionary,
	player_id: int,
	profile: int = Navigation.NavProfileId.SAFE,
	use_terrain_scores: bool = true
) -> PackedVector3Array:
	print("Debug find path with config:", agent_config)
	print("Debug find path with player_id:", player_id)
	print("Debug find path with profile:", profile)
	print("Debug find path with terrain scores:", use_terrain_scores)

	var terrain_scores: Dictionary = {}
	if use_terrain_scores:
		terrain_scores = _get_player_terrain_scores(player_id)

	return _nav_map.find_path(start, goal, agent_config, profile, terrain_scores)
