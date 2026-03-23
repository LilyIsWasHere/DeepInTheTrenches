extends RefCounted

const FOOTPRINT_SAMPLE_COUNT := 4
const GRID_CELL_SIZE := 1.0
const DIRTY_CELL_PADDING := 1

# internal type to hold the data sampled from the terrain for a cell
class _NavSample:
	var height: float = 0.0
	var initial_height: float = 0.0
	var slope_x: float = 0.0
	var slope_z: float = 0.0
	var slope_degrees: float = 0.0

# PERSISTENT STUFF
# latest published terrain snapshot from the main thread
var _terrain_snapshot: NavTerrainSnapshot = null

# persistent Godot A* grid class and its terrain-derived nav data by cell
var _grid_astar: NavAStarGrid2D = null
var _astar_nav_data: Dictionary = {}

# terrain snapshot for the requests currently being processed
var _nav_terrain_snapshot: NavTerrainSnapshot = null

# CURRENT REQUEST STUFF
# request-specific agent information
var _agent_config: NavAgentConfig = null
var _agent_context: Dictionary = {}

# request-specific cell data cache with agent-specific traversability info
# the key is the cell coordinate, and the value is a NavCellData instance
var _grid_request_cell_data: Dictionary = {}

# request-specific point data cache for sampling
var _cached_point_nav_data: Dictionary = {}

# get the size of a grid cell in world units
func get_cell_size() -> float:
	return GRID_CELL_SIZE

# set the new terrain snapshot from the main thread
func set_terrain_snapshot(terrain_snapshot: NavTerrainSnapshot) -> void:
	_terrain_snapshot = terrain_snapshot
	_cached_point_nav_data.clear()
	_grid_request_cell_data.clear()

# go from world space to cell coordinates
func world_to_cell(point: Vector3) -> Vector2i:
	return Vector2i(
		floor(point.x / GRID_CELL_SIZE),
		floor(point.z / GRID_CELL_SIZE)
	)

# go from cell coordinates to world space (center of the cell)
func cell_to_world(cell: Vector2i, use_surface_height: bool = false, nav_data: _NavSample = null) -> Vector3:
	var point := Vector3(
		(cell.x + 0.5) * GRID_CELL_SIZE,
		0.0,
		(cell.y + 0.5) * GRID_CELL_SIZE
	)

	if use_surface_height:
		if nav_data == null:
			nav_data = _get_cached_nav_data(point)

		if nav_data != null:
			point.y = nav_data.height

	return point

# use Godot's AStarGrid2D to find a path
func find_path(start: Vector3, goal: Vector3,	agent_config: NavAgentConfig,	agent_context: Dictionary) -> PackedVector3Array:
	if not _ensure_nav_grid_ready(agent_config, agent_context):
		return PackedVector3Array()

	var start_cell: Vector2i = world_to_cell(start)
	var goal_cell: Vector2i = world_to_cell(goal)

	if not _grid_astar.region.has_point(start_cell) or not _grid_astar.region.has_point(goal_cell):
		return PackedVector3Array()

	# clear per-request caches
	_cached_point_nav_data.clear()
	_grid_request_cell_data.clear()

	var start_data: NavCellData = _get_request_cell_data(start_cell)
	if start_data == null or not start_data.traversable:
		print("Start position is not traversable")
		return PackedVector3Array()

	var goal_data: NavCellData = _get_request_cell_data(goal_cell)
	if goal_data == null or not goal_data.traversable:
		print("Goal position is not traversable")
		return PackedVector3Array()

	# actual pathfinding
	var id_path: Array[Vector2i] = _grid_astar.get_id_path(start_cell, goal_cell)
	if id_path.is_empty():
		print("no path found")
		return PackedVector3Array()

	# turn the path of cell IDs into a path of world points on the terrain surface
	var path: PackedVector3Array = PackedVector3Array()
	for i in range(id_path.size()):
		var cell: Vector2i = id_path[i]
		var nav_data: _NavSample = _astar_nav_data.get(cell, null)
		path.append(cell_to_world(cell, true, nav_data))
		

	return path

# GRID HELPERS
# make sure the persistent grid and the current request state are ready
func _ensure_nav_grid_ready(agent_config: NavAgentConfig, agent_context: Dictionary) -> bool:
	if _terrain_snapshot == null:
		return false

	# initialize the persistent Godot A* class for the first time
	var full_grid_rect: Rect2i = _terrain_snapshot.make_astar_grid(GRID_CELL_SIZE)
	if _grid_astar == null:
		_grid_astar = NavAStarGrid2D.new()
		_grid_astar.compute_cost_fn = Callable(self, "_grid_compute_cost")
		_grid_astar.cell_size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
		_grid_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
		_grid_astar.jumping_enabled = false
		_build_full_nav_grid(full_grid_rect)
		_agent_config = agent_config
		_agent_context = agent_context
		return true

	# update the current request state with the new agent information
	_agent_config = agent_config
	_agent_context = agent_context

	# if something has changed such that the current grid is no longer valid
	if _nav_terrain_snapshot == null or _grid_astar.region != full_grid_rect:
		_build_full_nav_grid(full_grid_rect)
		return true

	# if the grid exists but the terrain has changed, refresh just the dirty cells
	if _nav_terrain_snapshot != _terrain_snapshot:
		_refresh_dirty_grid_cells()
		return true

	# otherwise the grid is ready to go as-is
	return true

# build or rebuild the entire persistent grid from the current terrain snapshot
func _build_full_nav_grid(full_grid_rect: Rect2i) -> void:
	_grid_astar.region = full_grid_rect
	_grid_astar.cell_size = Vector2(GRID_CELL_SIZE, GRID_CELL_SIZE)
	_grid_astar.offset = Vector2.ZERO
	_grid_astar.update()

	# clear persistent and request-specific data
	_astar_nav_data.clear()
	_cached_point_nav_data.clear()
	_grid_request_cell_data.clear()

	var min_x: int = full_grid_rect.position.x
	var min_y: int = full_grid_rect.position.y
	var max_x: int = full_grid_rect.position.x + full_grid_rect.size.x
	var max_y: int = full_grid_rect.position.y + full_grid_rect.size.y
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			_update_grid_cell(Vector2i(x, y))

	_nav_terrain_snapshot = _terrain_snapshot

# refresh just the cells touched by dirty terrain tiles in the new snapshot
func _refresh_dirty_grid_cells() -> void:
	if _grid_astar == null or _terrain_snapshot == null: return

	# clear request-specific caches
	_cached_point_nav_data.clear()
	_grid_request_cell_data.clear()

	var dirty_cells: Array[Vector2i] = _terrain_snapshot.get_dirty_cells(GRID_CELL_SIZE, DIRTY_CELL_PADDING)
	for i in range(dirty_cells.size()):
		var cell: Vector2i = dirty_cells[i]
		if not _grid_astar.region.has_point(cell):
			continue
		_update_grid_cell(cell)

	_nav_terrain_snapshot = _terrain_snapshot

# update one persistent grid cell from the current terrain snapshot.
func _update_grid_cell(cell: Vector2i) -> void:
	var nav_data: _NavSample = _get_nav_data(cell_to_world(cell))
	if nav_data == null:
		_astar_nav_data.erase(cell)
		return

	_astar_nav_data[cell] = nav_data

# CALLBACKS
# for the A* class to compute the cost of moving along an edge
func _grid_compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	if _agent_config == null or _grid_astar == null:
		return INF

	# basic traversability and slope checks
	var from_data: NavCellData = _get_request_cell_data(from_id)
	var to_data: NavCellData = _get_request_cell_data(to_id)
	if from_data == null or to_data == null:
		return INF

	if not from_data.traversable or not to_data.traversable:
		return INF

	var edge_max_slope_degrees: float = _compute_edge_max_slope_degrees(from_id, to_id, from_data, to_data)
	if edge_max_slope_degrees == INF:
		return INF

	# then use the agent config's custom cost function
	var move_context := NavMoveContext.new()
	move_context.from_cell = from_id
	move_context.to_cell = to_id
	move_context.from_data = from_data
	move_context.to_data = to_data
	move_context.edge_max_slope_degrees = edge_max_slope_degrees

	return _agent_config.get_nav_cost(_agent_context, move_context)

# GETTERS
# get navigation data at a point
func _get_nav_data(point: Vector3) -> _NavSample:
	if _terrain_snapshot == null:
		return null

	var terrain_data: Dictionary = _terrain_snapshot.get_terrain_data(point)
	if terrain_data.is_empty():
		return null

	var slope_data: Array = _terrain_snapshot.get_terrain_slope(point)
	if slope_data.is_empty():
		return null

	var nav_sample := _NavSample.new()
	nav_sample.height = float(terrain_data["height"])
	nav_sample.initial_height = float(terrain_data["initial_height"])
	nav_sample.slope_x = float(slope_data[0])
	nav_sample.slope_z = float(slope_data[1])
	nav_sample.slope_degrees = rad_to_deg(atan(float(slope_data[2])))
	return nav_sample

# get the cached navigation data for a point, or sample it if it's not cached
func _get_cached_nav_data(point: Vector3) -> _NavSample:
	if _cached_point_nav_data.has(point):
		return _cached_point_nav_data[point]

	var nav_data: _NavSample = _get_nav_data(point)
	_cached_point_nav_data[point] = nav_data
	return nav_data

# get request-specific data for a cell since it has agent-specific traversability stuff
func _get_request_cell_data(cell: Vector2i) -> NavCellData:
	if _grid_request_cell_data.has(cell):
		return _grid_request_cell_data[cell]

	var base_data: _NavSample = _astar_nav_data.get(cell, null)
	if base_data == null:
		_grid_request_cell_data[cell] = null
		return null

	var nav_cell_data := NavCellData.new()
	nav_cell_data.cell = cell
	nav_cell_data.height = base_data.height
	nav_cell_data.initial_height = base_data.initial_height
	nav_cell_data.slope_x = base_data.slope_x
	nav_cell_data.slope_z = base_data.slope_z
	nav_cell_data.slope_degrees = base_data.slope_degrees
	nav_cell_data.world_point = cell_to_world(cell, true, base_data)
	if _agent_config != null:
		nav_cell_data.traversable = _is_traversable(nav_cell_data.world_point, _agent_config, base_data)

	_grid_request_cell_data[cell] = nav_cell_data
	return nav_cell_data

# TERRAIN UTILITY
# TODO: maybe fold this into the agent config's cost function as well???? idk 
# check if a point is traversable for a given agent information
func _is_traversable(point: Vector3, agent_config: NavAgentConfig, center_nav_data: _NavSample = null) -> bool:
	var nav_data: _NavSample = center_nav_data
	if nav_data == null:
		nav_data = _get_cached_nav_data(point)

	if nav_data == null:
		return false

	var agent_radius: float = agent_config.radius
	var agent_max_step_height: float = agent_config.max_step_height
	var center_height: float = nav_data.height

	# go around the point in a circle
	for i in range(FOOTPRINT_SAMPLE_COUNT):
		var angle: float = TAU * float(i) / float(FOOTPRINT_SAMPLE_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * agent_radius
		var sample_point: Vector3 = point + offset
		var sample_data: _NavSample = _get_cached_nav_data(sample_point)

		if sample_data == null:
			return false

		if abs(sample_data.height - center_height) > agent_max_step_height:
			return false

	return true

# compute the max slope along two cells
func _compute_edge_max_slope_degrees(from_cell: Vector2i,	to_cell: Vector2i, from_data: NavCellData,	to_data: NavCellData) -> float:
	var from_slope: float = from_data.slope_degrees
	var to_slope: float = to_data.slope_degrees

	var midpoint: Vector3 = cell_to_world(from_cell).lerp(cell_to_world(to_cell), 0.5)
	var midpoint_data: _NavSample = _get_cached_nav_data(midpoint)
	if midpoint_data == null:
		return INF

	var midpoint_slope: float = midpoint_data.slope_degrees
	return max(from_slope, max(midpoint_slope, to_slope))
