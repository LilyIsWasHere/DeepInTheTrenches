# https://www.gamedeveloper.com/programming/creating-natural-paths-on-terrains-using-pathfinding
# https://howtorts.github.io/2014/01/04/basic-flow-fields.html

extends RefCounted

const FOOTPRINT_SAMPLE_COUNT := 4
const GRID_CELL_SIZE := 1.0
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
	var slope_data: Array = terrain.get_terrain_slope(point)
	var slope_x: float = slope_data[0]
	var slope_z: float = slope_data[1]
	var slope_degrees: float = rad_to_deg(atan(slope_data[2]))

	var nav_data: Dictionary = {
		"height": terrain_data["height"],
		"slope_x": slope_x,
		"slope_z": slope_z,
		"slope_degrees": slope_degrees
	}

	return nav_data

# check if a point is traversable for a given agent information
# ONLY for step height and radius, slope is handled in the pathfinding code
func is_traversable( point: Vector3, agent_config: Dictionary, center_nav_data: Dictionary = {} ) -> bool:
	var nav_data := center_nav_data
	if nav_data.is_empty():
		nav_data = get_nav_data(point)

	if nav_data.is_empty():
		return false
	
	var agent_radius: float = agent_config["radius"]
	var agent_max_step_height: float = agent_config["max_step_height"]

	var center_height: float = nav_data["height"]

	for i in range(FOOTPRINT_SAMPLE_COUNT):
		var angle := TAU * float(i) / float(FOOTPRINT_SAMPLE_COUNT)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * agent_radius
		var sample_point := point + offset
		var sample_data := get_nav_data(sample_point)

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
			nav_data = get_nav_data(point)

		if not nav_data.is_empty():
			point.y = nav_data["height"]

	return point

# get the navigation information for a cell
func sample_cell(cell: Vector2i, agent_config: Dictionary) -> Dictionary:
	var world_point := cell_to_world(cell)
	var nav_data := get_nav_data(world_point)
	var traversable := is_traversable(world_point, agent_config, nav_data)

	return {
		"cell": cell,
		"world_point": world_point,
		"nav_data": nav_data,
		"traversable": traversable
	}

# https://en.wikipedia.org/wiki/A*_search_algorithm using manhattan distance as the heuristic
func find_path(start: Vector3, goal: Vector3,	agent_config: Dictionary,	profile: int) -> PackedVector3Array:
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

		# get neighbors with cache
		for neighbor in _get_neighbors_with_cache(current, agent_config, cache):
			if closed_set.has(neighbor):
				continue

			var move_cost := _get_move_cost(current, neighbor, agent_config, profile, cache)
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
func _sample_cell_with_cache(cell: Vector2i, agent_config: Dictionary, cache: Dictionary) -> Dictionary:
	if cell in cache:
		return cache[cell]
	
	var data := sample_cell(cell, agent_config)
	cache[cell] = data
	return data

# same as get_neighbors but with a cache thrown in
func _get_neighbors_with_cache(cell: Vector2i, agent_config: Dictionary, cache: Dictionary) -> Array[Vector2i]:
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
func _get_edge_max_slope_degrees(from_cell: Vector2i, to_cell: Vector2i) -> float:
	var from_point: Vector3 = cell_to_world(from_cell)
	var to_point: Vector3 = cell_to_world(to_cell)

	var max_slope: float = 0.0
	var sample_count: int = 4

	for i in range(sample_count + 1):
		var t: float = float(i) / float(sample_count)
		var point: Vector3 = from_point.lerp(to_point, t)
		var nav_data: Dictionary = get_nav_data(point)
		if nav_data.is_empty():
			return INF

		var slope_degrees: float = nav_data["slope_degrees"]
		if slope_degrees > max_slope:
			max_slope = slope_degrees

	return max_slope

func _get_height(point: Vector3) -> float:
	var terrain := _get_terrain()
	if terrain == null or not _is_in_bounds(point):
		return -1
	return terrain.get_terrain_data(point)["height"]

func _get_cover_depth(point: Vector3) -> float:
	var center_height_value := _get_height(point)
	if center_height_value == -1:
		return 0.0

	var center_height: float = center_height_value
	var diffs: Array[float] = []
	var cover_radius := 1.5

	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var sample_point := point + Vector3(cos(angle), 0.0, sin(angle)) * cover_radius
		var sample_height_value := _get_height(sample_point)
		if sample_height_value == -1:
			continue

		var diff: float = sample_height_value - center_height
		if diff > 0.0:
			diffs.append(diff)

	if diffs.is_empty():
		return 0.0

	diffs.sort()

	@warning_ignore("integer_division")
	var start: int = diffs.size() / 2
	var total := 0.0
	for i in range(start, diffs.size()):
		total += diffs[i]

	return total / float(diffs.size() - start)

# get the cost to move from one cell to another for A*
func _get_move_cost(
	from_cell: Vector2i,
	to_cell: Vector2i,
	agent_config: Dictionary,
	profile: int,
	cache: Dictionary
) -> float:
	var from_data: Dictionary = cache.get(from_cell, {})
	var to_data: Dictionary = cache.get(to_cell, {})

	if from_data.is_empty() or to_data.is_empty():
		return INF
	if not to_data["traversable"]:
		return INF

	var max_slope_degrees: float = agent_config["max_slope_degrees"]
	var max_step_height: float = agent_config["max_step_height"]
	var wall_climb_height: float = agent_config["wall_climb_height"]

	var from_height: float = from_data["nav_data"]["height"]
	var to_height: float = to_data["nav_data"]["height"]
	var rise: float = to_height - from_height

	var delta: Vector2i = to_cell - from_cell
	var run: float = 1.41421356 if abs(delta.x) == 1 and abs(delta.y) == 1 else 1.0
	var base_cost: float = run

	if rise > 0.0:
		var uphill_angle: float = rad_to_deg(atan(rise / run))

		if uphill_angle <= max_slope_degrees:
			pass
		elif rise <= wall_climb_height:
			if profile == Navigation.NavProfileId.DIRECT:
				base_cost += 2.0
			else:
				return INF
		else:
			return INF

	if rise < 0.0 and abs(rise) > max_step_height:
		return INF

	return base_cost

# DEBUG
func sample_patch(
	center: Vector3,
	half_extent_cells: int,
	agent_config: Dictionary
) -> Dictionary:
	var cells: Dictionary = {}
	var center_cell: Vector2i = world_to_cell(center)
	for z in range(-half_extent_cells, half_extent_cells + 1):
		for x in range(-half_extent_cells, half_extent_cells + 1):
			var cell := center_cell + Vector2i(x, z)
			cells[cell] = sample_cell(cell, agent_config)
	return cells
