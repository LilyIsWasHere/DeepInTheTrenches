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
const TERRAIN_SNAPSHOT_MIN_REFRESH_MS := 100

var _active_requests: Dictionary = {}
var _player_score_layers: Dictionary = {}
var _terrain_snapshot: NavTerrainSnapshot = null
var _terrain_snapshot_dirty: bool = true
var _terrain_snapshot_refresh_after_ms: int = 0
var _dirty_terrain_tiles: Dictionary = {}
var _plan_thread: Thread = null
var _queued_plan_items: Array[NavPlanQueueItem] = []
var _running_handle: NavPlanHandle = null

func _ready() -> void:
	_nav_map = NavMap.new()

func _process(_delta: float) -> void:
	_pump_plan_thread()

# should probably avoid hanging threads
func _exit_tree() -> void:
	if _plan_thread != null and _plan_thread.is_alive():
		_plan_thread.wait_to_finish()

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

	_ensure_terrain_snapshot()
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

# Call this function to mark terrain tiles as dirty, so that the next time it's sampled, it will be updated.
func record_terrain_readback_batch(tiles: Array[TerrainTile_Class]) -> void:
	if tiles.is_empty():
		return

	_terrain_snapshot_dirty = true
	_terrain_snapshot_refresh_after_ms = Time.get_ticks_msec() + TERRAIN_SNAPSHOT_MIN_REFRESH_MS

	for tile in tiles:
		_dirty_terrain_tiles[tile.get_instance_id()] = {
			"position": tile.global_position,
			"size": tile.size,
		}

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

	# iterate over cells in the radius and apply the score delta with a falloff based on distance
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

# helper that make sure the terrain snapshot is up to date
func _ensure_terrain_snapshot() -> void:
	var terrain: Terrain = GlobalTerrainManager.get_terrain()
	if terrain == null:
		return

	if _terrain_snapshot == null:
		_terrain_snapshot = NavTerrainSnapshot.new()
		_terrain_snapshot.rebuild_from_terrain(terrain)
		_terrain_snapshot_dirty = false
		_dirty_terrain_tiles.clear()
		return

	if not _terrain_snapshot_dirty:
		return

	if Time.get_ticks_msec() < _terrain_snapshot_refresh_after_ms:
		return

	_terrain_snapshot.refresh_dirty_tiles_from_terrain(terrain, _dirty_terrain_tiles)
	_terrain_snapshot_dirty = false
	_dirty_terrain_tiles.clear()

# helper function to handle a pathfinding request
func _plan_request(agent: Node3D, handle: NavPlanHandle) -> void:
	var agent_config: NavAgentConfig = handle.agent_config
	if agent_config == null:
		handle.status = NavPlanHandle.NavRequestStatus.FAILED
		handle.failure_reason = "Missing nav agent config"
		handle.waypoints = PackedVector3Array()
		handle.failed.emit()
		return

	var snapshot: NavPlanSnapshot = _build_plan_snapshot(agent, handle)
	_queue_plan_request(handle, snapshot)

# helper to build a NavPlanSnapshot from an agent and NavPlanHandle
func _build_plan_snapshot(agent: Node3D, handle: NavPlanHandle) -> NavPlanSnapshot:
	var snapshot := NavPlanSnapshot.new()
	snapshot.start = agent.global_position
	snapshot.target = handle.target
	snapshot.agent_config = handle.agent_config
	snapshot.agent_context = handle.agent_context.duplicate(true)
	snapshot.terrain_snapshot = _terrain_snapshot

	return snapshot

# helper to solve a nav plan snapshot
# this is where the actual pathfinding happens 
func _solve_plan_snapshot(snapshot: NavPlanSnapshot) -> PackedVector3Array:
	if snapshot == null:
		return PackedVector3Array()

	if snapshot.agent_config == null:
		return PackedVector3Array()

	if snapshot.terrain_snapshot == null:
		return PackedVector3Array()

	var nav_map: NavMap = NavMap.new()
	nav_map.set_terrain_snapshot(snapshot.terrain_snapshot)

	return nav_map.find_path(
		snapshot.start,
		snapshot.target,
		snapshot.agent_config,
		snapshot.agent_context
	)

# pushes one request snapshot into the nav queue, then calls the manager
func _queue_plan_request(handle: NavPlanHandle, snapshot: NavPlanSnapshot) -> void:
	var item := NavPlanQueueItem.new()
	item.handle = handle
	item.snapshot = snapshot

	_queued_plan_items.append(item)
	_pump_plan_thread()

# queue manager
func _pump_plan_thread() -> void:

	# check if the current thread is done, and if so, publish the result and free it up
	if _plan_thread != null and not _plan_thread.is_alive():
		var path_variant: Variant = _plan_thread.wait_to_finish()
		var path: PackedVector3Array = path_variant
		var finished_handle: NavPlanHandle = _running_handle

		_plan_thread = null
		_running_handle = null

		_publish_plan_result(finished_handle, path)

	if _plan_thread != null:
		return

	# if there are any queued requests, start the next one
	while not _queued_plan_items.is_empty():
		var item: NavPlanQueueItem = _queued_plan_items[0]
		_queued_plan_items.remove_at(0)

		var handle: NavPlanHandle = item.handle
		var snapshot: NavPlanSnapshot = item.snapshot

		if handle == null:
			continue

		if handle.status == NavPlanHandle.NavRequestStatus.CANCELLED:
			continue

		var active_handle: NavPlanHandle = _active_requests.get(handle.agent, null)
		if active_handle != handle:
			continue

		_running_handle = handle
		_plan_thread = Thread.new()

		var err: Error = _plan_thread.start(Callable(self, "_solve_plan_snapshot").bind(snapshot))
		if err != OK:
			_plan_thread = null
			_running_handle = null

			handle.status = NavPlanHandle.NavRequestStatus.FAILED
			handle.failure_reason = "Failed to start nav thread"
			handle.waypoints = PackedVector3Array()
			handle.failed.emit()
			continue

		break

# applies a finished path to the handle if it's valid
func _publish_plan_result(handle: NavPlanHandle, path: PackedVector3Array) -> void:
	if handle == null:
		return

	if handle.status == NavPlanHandle.NavRequestStatus.CANCELLED:
		return

	var active_handle: NavPlanHandle = _active_requests.get(handle.agent, null)
	if active_handle != handle:
		return

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
func debug_request_path(
	start: Vector3,
	goal: Vector3,
	agent: Node,
	agent_config: NavAgentConfig
) -> NavPlanHandle:
	if agent == null:
		return null

	_ensure_terrain_snapshot()

	var handle := NavPlanHandle.new()
	handle.target = goal
	handle.agent = agent
	handle.agent_config = agent_config

	if handle.agent_config == null:
		return null

	handle.agent_context = _build_agent_context(agent, handle.agent_config)
	_active_requests[agent] = handle

	var snapshot := NavPlanSnapshot.new()
	snapshot.start = start
	snapshot.target = goal
	snapshot.agent_config = handle.agent_config
	snapshot.agent_context = handle.agent_context.duplicate(true)
	snapshot.terrain_snapshot = _terrain_snapshot

	_queue_plan_request(handle, snapshot)
	return handle
