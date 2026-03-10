# https://www.gamedeveloper.com/programming/creating-natural-paths-on-terrains-using-pathfinding
# https://howtorts.github.io/2014/01/04/basic-flow-fields.html

extends RefCounted

const MAX_STEP_HEIGHT := 0.35
const FOOTPRINT_SAMPLE_COUNT := 6
const GRID_CELL_SIZE := 0.5
const A_STAR_MAX_ITERATIONS := 10000

# get navigation data at a point
func get_nav_data(point: Vector3) -> Dictionary:
	var terrain := _get_terrain()
	if terrain == null:
		return {}
	
	if not _is_in_bounds(point):
		return {}
	
	# get the height and slope at the point
	var terrain_data: Dictionary = terrain.get_terrain_data(point)
	var slope_degrees: float = rad_to_deg(atan(terrain.get_terrain_slope(point)[2]))

	var nav_data: Dictionary = {
		"height": terrain_data["height"],
		"slope_degrees": slope_degrees,
		"cover_depth": 0.0
	}

	return nav_data

# check if a point is traversable for a given agent information
func is_traversable(
	point: Vector3,
	agent_radius: float,
	agent_max_slope_degrees: float,
	center_nav_data: Dictionary = {}
) -> bool:
	var nav_data := center_nav_data
	if nav_data.is_empty():
		nav_data = get_nav_data(point)

	if nav_data.is_empty():
		return false

	if nav_data["slope_degrees"] > agent_max_slope_degrees:
		return false

	var center_height: float = nav_data["height"]

	for i in range(FOOTPRINT_SAMPLE_COUNT):
		var angle := TAU * float(i) / float(FOOTPRINT_SAMPLE_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * agent_radius
		var sample_point := point + offset
		var sample_data := get_nav_data(sample_point)

		if sample_data.is_empty():
			return false

		if sample_data["slope_degrees"] > agent_max_slope_degrees:
			return false

		if abs(sample_data["height"] - center_height) > MAX_STEP_HEIGHT:
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
			nav_data = get_nav_data(point)

		if not nav_data.is_empty():
			point.y = nav_data["height"]

	return point

# get the navigation information for a cell
func sample_cell(cell: Vector2i, agent_radius: float, agent_max_slope_degrees: float) -> Dictionary:
	var world_point := cell_to_world(cell)
	var nav_data := get_nav_data(world_point)
	var traversable := is_traversable(world_point, agent_radius, agent_max_slope_degrees, nav_data)

	return {
		"cell": cell,
		"world_point": world_point,
		"nav_data": nav_data,
		"traversable": traversable
	}

# get the 4 cells around a cell if it is traversable
func get_neighbors(cell: Vector2i, agent_radius: float, agent_max_slope_degrees: float) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for dir in directions:
		var neighbor_cell := cell + dir
		var neighbor_data := sample_cell(neighbor_cell, agent_radius, agent_max_slope_degrees)
		if neighbor_data["traversable"]:
			neighbors.append(neighbor_cell)
	return neighbors

# https://en.wikipedia.org/wiki/A*_search_algorithm using manhattan distance as the heuristic
func find_path(
	start: Vector3,
	goal: Vector3,
	agent_radius: float,
	agent_max_slope_degrees: float
) -> PackedVector3Array:
	var start_cell := world_to_cell(start)
	var goal_cell := world_to_cell(goal)

	var cache: Dictionary = {}
	var iterations: int = 0

	if not _sample_cell_with_cache(start_cell, agent_radius, agent_max_slope_degrees, cache)["traversable"]:
		return PackedVector3Array()
	if not _sample_cell_with_cache(goal_cell, agent_radius, agent_max_slope_degrees, cache)["traversable"]:
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

		for neighbor in _get_neighbors_with_cache(current, agent_radius, agent_max_slope_degrees, cache):
			if closed_set.has(neighbor):
				continue

			var tentative_g: float = g_score[current] + 1.0
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal_cell)

				if neighbor not in open_set:
					open_set.append(neighbor)

	print("no path found")
	return PackedVector3Array()


# helpers
func _get_terrain() -> Terrain:
	return GlobalTerrainManager.get_terrain()

func _is_in_bounds(point: Vector3) -> bool:
	var terrain := _get_terrain()
	if terrain == null:
		return false
	
	var half := terrain.tile_size * 0.5
	var min_x := -half
	var min_z := -half
	var max_x := terrain.num_tiles.x * terrain.tile_size - half
	var max_z := terrain.num_tiles.y * terrain.tile_size - half
	var local_point := terrain.global_transform.affine_inverse() * point
	return local_point.x >= min_x and local_point.x < max_x and local_point.z >= min_z and local_point.z < max_z

# wrap around sample_cell with a cache thrown in
func _sample_cell_with_cache(cell: Vector2i, agent_radius: float, agent_max_slope_degrees: float, cache: Dictionary) -> Dictionary:
	if cell in cache:
		return cache[cell]
	
	var data := sample_cell(cell, agent_radius, agent_max_slope_degrees)
	cache[cell] = data
	return data

# same as get_neighbors but with a cache thrown in
func _get_neighbors_with_cache(cell: Vector2i, agent_radius: float, agent_max_slope_degrees: float, cache: Dictionary) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	for dir in directions:
		var neighbor := cell + dir
		if _sample_cell_with_cache(neighbor, agent_radius, agent_max_slope_degrees, cache)["traversable"]:
			neighbors.append(neighbor)

	return neighbors

# for A*
func _heuristic(cell: Vector2i, goal_cell: Vector2i) -> float:
	return abs(cell.x - goal_cell.x) + abs(cell.y - goal_cell.y)

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

# DEBUG
func sample_patch(
	center: Vector3,
	half_extent_cells: int,
	agent_radius: float,
	agent_max_slope_degrees: float
) -> Dictionary:
	var cells: Dictionary = {}
	var center_cell: Vector2i = world_to_cell(center)
	for z in range(-half_extent_cells, half_extent_cells + 1):
		for x in range(-half_extent_cells, half_extent_cells + 1):
			var cell := center_cell + Vector2i(x, z)
			cells[cell] = sample_cell(cell, agent_radius, agent_max_slope_degrees)
	return cells