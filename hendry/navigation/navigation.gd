extends Node

const NavMap := preload("res://hendry/navigation/nav_map.gd")
var _nav_map: NavMap = null

const DEFAULT_AGENT_RADIUS := 0.2
const DEFAULT_AGENT_HEIGHT := 1.7
const DEFAULT_AGENT_MAX_SPEED := 5.0
const DEFAULT_AGENT_MAX_SLOPE_DEGREES := 90.0#45.0
const DEFAULT_AGENT_MAX_STEP_HEIGHT := 1.0
const DEFAULT_AGENT_WALL_CLIMB_HEIGHT := 1.7
const TERRAIN_SNAPSHOT_MIN_REFRESH_MS := 100

# active requests for agents, mapping from the agent Node to their NavPlanHandle
var _active_requests: Dictionary = {}

# arbitrary score layers for each player to put in for whatever reason
var _player_score_layers: Dictionary = {}

# take a snapshot of the terrain data for pathfinding on a separate thread, updating the tiles marked dirty
var _terrain_snapshot: NavTerrainSnapshot = null
var _terrain_snapshot_dirty: bool = true
var _terrain_snapshot_refresh_after_ms: int = 0
var _dirty_terrain_tiles: Dictionary = {}

# navigation worker thread
var _plan_thread: Thread = null

# the plan queue is where the main thread pushes NavPlanSnapshots for the worker to solve
# each NavPlanQueueItem combines the snapshot (for the worker) and the handle (for the main thread and the rest of the game)
var _plan_queue_mutex: Mutex = Mutex.new()
var _plan_queue_semaphore: Semaphore = Semaphore.new()
var _queued_plan_items: Array[NavPlanQueueItem] = []

# same goes for the completed queue, where the worker pushes completed NavPlanQueueItems for the main thread to publish
var _completed_queue_mutex: Mutex = Mutex.new()
var _completed_plan_items: Array[NavPlanQueueItem] = []

# signal the worker to exit when the game is closing
var _worker_exit_requested: bool = false

func _ready() -> void:
	_nav_map = NavMap.new()
	_start_navigation_worker()

# check the completed queue for any finished items and publish their results
func _process(_delta: float) -> void:
	var completed_items: Array[NavPlanQueueItem] = []

	# duplicate the queue to the main thread and clear it on the worker side
	_completed_queue_mutex.lock()
	var duplicated_completed_items: Array = _completed_plan_items.duplicate()
	_completed_plan_items.clear()
	_completed_queue_mutex.unlock()

	# do stuff with the completed items on the main thread
	for i in range(duplicated_completed_items.size()):
		var item: NavPlanQueueItem = duplicated_completed_items[i]
		completed_items.append(item)

	for i in range(completed_items.size()):
		var item: NavPlanQueueItem = completed_items[i]
		_publish_plan_result(item.handle, item.path)

# should probably avoid hanging threads and such when exiting
# https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html#using-multiple-threads
func _exit_tree() -> void:
	if _plan_thread != null and _plan_thread.is_alive():
		_worker_exit_requested = true
		_plan_queue_semaphore.post()
		_plan_thread.wait_to_finish()

# API
# Call this function to remove an agent from the navigation system. This will cancel any active requests for that agent and free up resources.
func remove_agent(agent: Node) -> void:
	if agent == null:
		return

	_active_requests.erase(agent)

# Call this function to request a path to a target. Returns a NavPlanHandle that can be used to track the status of the request and sample steering results.
func request_move(agent: Node, target: Vector3, agent_config: NavAgentConfig) -> NavPlanHandle:
	if agent == null:
		return null

	if not agent is Node3D:
		return null

	if agent_config == null:
		return null

	# before doing anything, make sure the terrain snapshot is up to date
	_ensure_terrain_snapshot()
	var existing_handle: NavPlanHandle = _active_requests.get(agent, null)
	if existing_handle != null:
		cancel_request(existing_handle)

	var handle := NavPlanHandle.new()
	handle.target = target
	handle.agent = agent
	handle.agent_config = agent_config

	# give the agent the stuff it needs to know beforehand
	handle.agent_context = _build_agent_context(agent, handle.agent_config)

	_active_requests[agent] = handle
	var agent_node: Node3D = agent
	_plan_request(agent_node, handle)

	return handle

# Same as above but you can do it for a bunch of agents. Returns a dict mapping each agent to their NavPlanHandle.
func request_batch_move(agents: Array[Node], target: Vector3, agent_configs: Dictionary) -> Dictionary:
	var result: Dictionary = {}

	for agent in agents:
		var agent_config: NavAgentConfig = agent_configs.get(agent, null)
		var handle := request_move(agent, target, agent_config)
		if handle != null:
			result[agent] = handle

	return result

# Call this function to cancel an active path request for an agent.
func cancel_request(handle: NavPlanHandle) -> void:
	if handle == null:
		return

	handle.status = NavPlanHandle.NavRequestStatus.CANCELLED

# Call this function to get the size of a nav cell in world units.
func get_nav_cell_size() -> float:
	if _nav_map == null:
		return 0.0

	return _nav_map.get_cell_size()

# Call this function to convert a point in world space to a nav cell coordinate.
func world_to_nav_cell(point: Vector3) -> Vector2i:
	if _nav_map == null:
		return Vector2i.ZERO

	return _nav_map.world_to_cell(point)

# Call this function to convert a nav cell coordinate to a point in world space (specifically, the center of the cell).
func nav_cell_to_world(cell: Vector2i) -> Vector3:
	if _nav_map == null:
		return Vector3.ZERO

	return _nav_map.cell_to_world(cell)

# Call this function to ask where the agent should go next. Returns a NavSteeringResult with all the info you need.
func sample_steering(agent: Node, handle: NavPlanHandle, use_xz_only: bool = false) -> NavSteeringResult:
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

	# if we are pretty much at the next waypoint, pop it and move on to the next one
	while not handle.waypoints.is_empty():
		var first_waypoint: Vector3 = handle.waypoints[0]
		if _steering_distance(current_position, first_waypoint, use_xz_only) > waypoint_tolerance:
			break

		handle.waypoints.remove_at(0)
		handle.updated.emit()

	# if there are no more waypoints, we have arrived
	if handle.waypoints.is_empty():
		steering.arrived = true
		steering.next_waypoint = handle.target
		steering.remaining_distance = 0.0
		steering.desired_velocity = Vector3.ZERO
		return steering

	var next_waypoint: Vector3 = handle.waypoints[0]
	steering.next_waypoint = next_waypoint

	var remaining_distance: float = _steering_distance(current_position, next_waypoint, use_xz_only)
	for i in range(handle.waypoints.size() - 1):
		remaining_distance += _steering_distance(handle.waypoints[i], handle.waypoints[i + 1], use_xz_only)

	steering.remaining_distance = remaining_distance

	var to_waypoint: Vector3 = next_waypoint - current_position
	if use_xz_only:
		to_waypoint.y = 0.0
	var distance_to_waypoint: float = to_waypoint.length()

	if distance_to_waypoint <= waypoint_tolerance:
		steering.desired_velocity = Vector3.ZERO
	else:
		steering.desired_velocity = to_waypoint.normalized() * max_speed

	return steering

# Call this function to mark terrain tiles as dirty, so that the next time it's sampled, it will be updated.
func record_terrain_readback_batch(tiles: Array[TerrainTile_Class]) -> void:
	if tiles.is_empty():
		return

	_terrain_snapshot_dirty = true
	_terrain_snapshot_refresh_after_ms = Time.get_ticks_msec() + TERRAIN_SNAPSHOT_MIN_REFRESH_MS

	for tile in tiles:
		var tile_coord := Vector2i(
			int(tile.position.x / tile.size),
			int(tile.position.z / tile.size)
		)

		_dirty_terrain_tiles[tile.get_instance_id()] = tile_coord

# Call this function to add a score delta to a player's score layer for a batch of cells.
func update_player_score_layer(player_id: int, layer_name: StringName, cells: Array[Vector2i], score_delta: float) -> void:
	if is_zero_approx(score_delta):
		return

	var player_layer: Dictionary = create_player_score_layer(player_id, layer_name)
	for i in range(cells.size()):
		var cell: Vector2i = cells[i]
		var old_score: float = float(player_layer.get(cell, 0.0))
		var new_score: float = max(0.0, old_score + score_delta)

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
		var player_id: int = player_ids[i]
		clear_player_score_layer(player_id, layer_name)

# HELPERS
func _steering_distance(a: Vector3, b: Vector3, use_xz_only: bool) -> float:
	if use_xz_only:
		return Vector2(a.x - b.x, a.z - b.z).length()

	return a.distance_to(b)

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

	# initialization
	if _terrain_snapshot == null:
		_terrain_snapshot = NavTerrainSnapshot.new()
		_terrain_snapshot.rebuild_from_terrain(terrain)
		_terrain_snapshot_dirty = false
		_dirty_terrain_tiles.clear()
		return

	if not _terrain_snapshot_dirty:
		return

	# only refresh if enough time has passed
	if Time.get_ticks_msec() < _terrain_snapshot_refresh_after_ms:
		return

	_terrain_snapshot = _terrain_snapshot.create_refreshed_copy(terrain, _dirty_terrain_tiles)
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

# helper to solve a nav plan snapshot with a worker-owned nav map
func _solve_plan_with_nav_map(nav_map: NavMap, snapshot: NavPlanSnapshot) -> PackedVector3Array:
	if nav_map == null:
		return PackedVector3Array()

	if snapshot == null:
		return PackedVector3Array()

	if snapshot.agent_config == null:
		return PackedVector3Array()

	if snapshot.terrain_snapshot == null:
		return PackedVector3Array()

	nav_map.set_terrain_snapshot(snapshot.terrain_snapshot)

	return nav_map.find_path(
		snapshot.start,
		snapshot.target,
		snapshot.agent_config,
		snapshot.agent_context
	)

# helper that pushes one request snapshot into the nav queue, then calls the manager
func _queue_plan_request(handle: NavPlanHandle, snapshot: NavPlanSnapshot) -> void:
	_start_navigation_worker()
	if _plan_thread == null:
		handle.status = NavPlanHandle.NavRequestStatus.FAILED
		handle.failure_reason = "Failed to start nav worker thread"
		handle.waypoints = PackedVector3Array()
		handle.failed.emit()
		return

	# we have a worker thread, so we can queue the request
	var item := NavPlanQueueItem.new()
	item.handle = handle
	item.snapshot = snapshot

	# horrors of COMP 3000 haunts me still
	_plan_queue_mutex.lock()
	_queued_plan_items.append(item)
	_plan_queue_mutex.unlock()
	_plan_queue_semaphore.post()

# helper that applies a finished path to the handle if it's valid
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

# helper that starts the navigation worker thread if it's not already running
# if it is already running, does nothing
func _start_navigation_worker() -> void:

	# if there is already a worker thread, do nothing
	if _plan_thread != null and _plan_thread.is_alive():
		return

	# otherwise, start a new worker thread (should only happen once per game)
	_worker_exit_requested = false
	_plan_thread = Thread.new()
	var err: Error = _plan_thread.start(Callable(self, "_run_navigation_worker"))
	if err != OK:
		push_error("Failed to start navigation worker thread")
		_plan_thread = null

# helper that runs on the worker thread
# waits for items to be added to the plan queue, solves them, then adds them to the completed queue
func _run_navigation_worker() -> void:
	var worker_nav_map := NavMap.new()

	# wait until there is something in the queue
	while true:
		_plan_queue_semaphore.wait()

		# exit flag
		_plan_queue_mutex.lock()
		var should_exit: bool = _worker_exit_requested
		var item: NavPlanQueueItem = null

		# if there is something in the queue, take it out
		if not _queued_plan_items.is_empty():
			item = _queued_plan_items[0]
			_queued_plan_items.remove_at(0)
		_plan_queue_mutex.unlock()

		if item == null:
			if should_exit:
				break
			continue

		# solve the item and put it in the completed queue
		item.path = _solve_plan_with_nav_map(worker_nav_map, item.snapshot)
		_completed_queue_mutex.lock()
		_completed_plan_items.append(item)
		_completed_queue_mutex.unlock()

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

	var existing_handle: NavPlanHandle = _active_requests.get(agent, null)
	if existing_handle != null:
		cancel_request(existing_handle)

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
