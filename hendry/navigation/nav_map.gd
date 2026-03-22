# https://www.gamedeveloper.com/programming/creating-natural-paths-on-terrains-using-pathfinding
# https://howtorts.github.io/2014/01/04/basic-flow-fields.html

extends RefCounted

const FOOTPRINT_SAMPLE_COUNT := 4
const GRID_CELL_SIZE := 1.0
const A_STAR_MAX_ITERATIONS := 10000

var _cached_cell_nav_data: Dictionary = {}
var _cached_point_nav_data: Dictionary = {}
var _terrain_snapshot: NavTerrainSnapshot = null

func get_cell_size() -> float:
	return GRID_CELL_SIZE

# set the new terrain snapshot
func set_terrain_snapshot(terrain_snapshot: NavTerrainSnapshot) -> void:
	_terrain_snapshot = terrain_snapshot
	_cached_cell_nav_data.clear()
	_cached_point_nav_data.clear()

# get navigation data at a point
func get_nav_data(point: Vector3) -> Dictionary:
	if _terrain_snapshot == null:
		return {}

	var terrain_data: Dictionary = _terrain_snapshot.get_terrain_data(point)
	if terrain_data.is_empty():
		return {}

	var slope_data: Array = _terrain_snapshot.get_terrain_slope(point)
	if slope_data.is_empty():
		return {}

	var slope_x: float = float(slope_data[0])
	var slope_z: float = float(slope_data[1])
	var slope_degrees: float = rad_to_deg(atan(float(slope_data[2])))

	return {
		"height": terrain_data["height"],
		"slope_x": slope_x,
		"slope_z": slope_z,
		"slope_degrees": slope_degrees
	}

# check if a point is traversable for a given agent information
# ONLY for step height and radius, slope is handled in the pathfinding code
func is_traversable(point: Vector3, agent_config: NavAgentConfig, center_nav_data: Dictionary = {}) -> bool:
	var nav_data := center_nav_data
	if nav_data.is_empty():
		nav_data = _get_cached_nav_data(point)

	if nav_data.is_empty():
		return false
	
	var agent_radius: float = agent_config.radius
	var agent_max_step_height: float = agent_config.max_step_height

	var center_height: float = nav_data["height"]

	for i in range(FOOTPRINT_SAMPLE_COUNT):
		var angle := TAU * float(i) / float(FOOTPRINT_SAMPLE_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * agent_radius
		var sample_point := point + offset
		var sample_data := _get_cached_nav_data(sample_point)

		if sample_data.is_empty():
			return false

		if abs(sample_data["height"] - center_height) > agent_max_step_height:
			return false

	return true

# go from world space to cell coordinates 
func world_to_cell(point: Vector3) -> Vector2i:
	return Vector2i(
		floor(point.x / GRID_CELL_SIZE),
		floor(point.z / GRID_CELL_SIZE)
	)

# go from cell coordinates to world space (center of the cell)
func cell_to_world(cell: Vector2i, use_surface_height: bool = false, nav_data: Dictionary = {}) -> Vector3:
	var point := Vector3(
		(cell.x + 0.5) * GRID_CELL_SIZE,
		0.0,
		(cell.y + 0.5) * GRID_CELL_SIZE
	)

	if use_surface_height:
		if nav_data.is_empty():
			nav_data = _get_cached_nav_data(point)

		if not nav_data.is_empty():
			point.y = nav_data["height"]

	return point

# get the navigation information for a cell
func sample_cell(cell: Vector2i, agent_config: NavAgentConfig) -> Dictionary:
	var world_point := cell_to_world(cell)
	var nav_data := _get_cached_cell_nav_data(cell)
	var traversable := is_traversable(world_point, agent_config, nav_data)

	return {
		"cell": cell,
		"world_point": world_point,
		"nav_data": nav_data,
		"traversable": traversable
	}

# https://en.wikipedia.org/wiki/A*_search_algorithm using euclidean distance as the heuristic
func find_path(
	start: Vector3,
	goal: Vector3,
	agent_config: NavAgentConfig,
	agent_context: Dictionary
) -> PackedVector3Array:
	var start_cell := world_to_cell(start)
	var goal_cell := world_to_cell(goal)

	var cache: Dictionary = {}
	var iterations: int = 0

	if not _sample_cell_with_cache(start_cell, agent_config, cache)["traversable"]:
		print("Start position is not traversable")
		return PackedVector3Array()
	if not _sample_cell_with_cache(goal_cell, agent_config, cache)["traversable"]:
		print("Goal position is not traversable")
		return PackedVector3Array()

	var open_set: Array[Vector2i] = [start_cell]
	var closed_set: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start_cell: 0.0}
	var f_score: Dictionary = {start_cell: _heuristic(start_cell, goal_cell)}

	while not open_set.is_empty():
		iterations += 1
		if iterations > A_STAR_MAX_ITERATIONS:
			push_warning("A* algorithm exceeded maximum iterations")
			return PackedVector3Array()

		var current := _find_lowest_f_score(open_set, f_score, goal_cell)

		if current == goal_cell:
			var path: PackedVector3Array = PackedVector3Array()
			var path_cell := current

			while path_cell in came_from:
				var cell_data: Dictionary = cache.get(path_cell, {})
				path.append(cell_to_world(path_cell, true, cell_data.get("nav_data", {})))
				path_cell = came_from[path_cell]

			var start_data: Dictionary = cache.get(start_cell, {})
			path.append(cell_to_world(start_cell, true, start_data.get("nav_data", {})))
			path.reverse()
			return path

		open_set.erase(current)
		closed_set[current] = true

		for neighbor in _get_neighbors_with_cache(current, agent_config, cache):
			if closed_set.has(neighbor):
				continue

			# build the data for the move cost function
			var from_data: Dictionary = cache.get(current, {})
			var to_data: Dictionary = cache.get(neighbor, {})

			if from_data.is_empty() or to_data.is_empty():
				continue

			var edge_max_slope_degrees: float = _get_edge_max_slope_degrees(current, neighbor, from_data, to_data)
			if edge_max_slope_degrees == INF:
				continue

			var move_context := {
				"from_cell": current,
				"to_cell": neighbor,
				"from_data": from_data,
				"to_data": to_data,
				"edge_max_slope_degrees": edge_max_slope_degrees
			}

			# get the cost to move from current to neighbor using the agent config's cost function
			var move_cost: float = agent_config.get_nav_cost(agent_context, move_context)
			if move_cost == INF:
				continue

			var tentative_g: float = g_score[current] + move_cost
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal_cell)

				if neighbor not in open_set:
					open_set.append(neighbor)

	print("no path found")
	return PackedVector3Array()

# HELPERS
# get the cached navigation data for a point, or sample it if it's dirty or not cached
func _get_cached_nav_data(point: Vector3) -> Dictionary:
	if _cached_point_nav_data.has(point):
		return _cached_point_nav_data[point]

	var nav_data: Dictionary = get_nav_data(point)
	_cached_point_nav_data[point] = nav_data
	return nav_data

# get the cached navigation data for a cell, or sample it if it's dirty or not cached
func _get_cached_cell_nav_data(cell: Vector2i) -> Dictionary:
	if _cached_cell_nav_data.has(cell):
		return _cached_cell_nav_data[cell]

	var nav_data: Dictionary = _get_cached_nav_data(cell_to_world(cell))
	_cached_cell_nav_data[cell] = nav_data
	return nav_data

# wrap around sample_cell with a cache thrown in
func _sample_cell_with_cache(cell: Vector2i, agent_config: NavAgentConfig, cache: Dictionary) -> Dictionary:
	if cell in cache:
		return cache[cell]
	
	var data := sample_cell(cell, agent_config)
	cache[cell] = data
	return data

# same as get_neighbors but with a cache thrown in
func _get_neighbors_with_cache(cell: Vector2i, agent_config: NavAgentConfig, cache: Dictionary) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1),
	]

	for dir in directions:
		var neighbor := cell + dir
		var neighbor_data := _sample_cell_with_cache(neighbor, agent_config, cache)
		if not neighbor_data["traversable"]:
			continue

		neighbors.append(neighbor)

	return neighbors

# Euclidean for A*
func _heuristic(cell: Vector2i, goal_cell: Vector2i) -> float:
	var dx: int = abs(cell.x - goal_cell.x)
	var dy: int = abs(cell.y - goal_cell.y)
	var diagonal: int = min(dx, dy)
	var straight: int = max(dx, dy) - diagonal
	return diagonal * 1.41421356 + straight

# for A*
func _find_lowest_f_score(open_set: Array[Vector2i], f_score: Dictionary, goal_cell: Vector2i) -> Vector2i:
	var best: Vector2i = open_set[0]
	var best_f: float = f_score.get(best, INF)
	var best_h: float = _heuristic(best, goal_cell)

	for cell in open_set:
		var f: float = f_score.get(cell, INF)
		var h: float = _heuristic(cell, goal_cell)

		if f < best_f or (f == best_f and h < best_h):
			best = cell
			best_f = f
			best_h = h

	return best

# get the max slope along two cells
func _get_edge_max_slope_degrees(
	from_cell: Vector2i,
	to_cell: Vector2i,
	from_data: Dictionary,
	to_data: Dictionary
) -> float:
	var from_slope: float = float(from_data["nav_data"]["slope_degrees"])
	var to_slope: float = float(to_data["nav_data"]["slope_degrees"])

	var midpoint: Vector3 = cell_to_world(from_cell).lerp(cell_to_world(to_cell), 0.5)
	var midpoint_data: Dictionary = _get_cached_nav_data(midpoint)
	if midpoint_data.is_empty():
		return INF

	var midpoint_slope: float = float(midpoint_data["slope_degrees"])
	return max(from_slope, max(midpoint_slope, to_slope))

# DEBUG
