# https://www.gamedeveloper.com/programming/creating-natural-paths-on-terrains-using-pathfinding
# https://howtorts.github.io/2014/01/04/basic-flow-fields.html

extends RefCounted

const FOOTPRINT_SAMPLE_COUNT := 4
const GRID_CELL_SIZE := 1.0
const A_STAR_MAX_ITERATIONS := 10000

func get_cell_size() -> float:
	return GRID_CELL_SIZE

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
func is_traversable(point: Vector3, agent_config: NavAgentConfig, center_nav_data: Dictionary = {}) -> bool:
	var nav_data := center_nav_data
	if nav_data.is_empty():
		nav_data = get_nav_data(point)

	if nav_data.is_empty():
		return false
	
	var agent_radius: float = agent_config.radius
	var agent_max_step_height: float = agent_config.max_step_height

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
func sample_cell(cell: Vector2i, agent_config: NavAgentConfig) -> Dictionary:
	var world_point := cell_to_world(cell)
	var nav_data := get_nav_data(world_point)
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

			var move_cost: float = _get_move_cost(current, neighbor, agent_config, agent_context, cache)
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
	var midpoint_data: Dictionary = get_nav_data(midpoint)
	if midpoint_data.is_empty():
		return INF

	var midpoint_slope: float = float(midpoint_data["slope_degrees"])
	return max(from_slope, max(midpoint_slope, to_slope))

func _get_height(point: Vector3) -> float:
	var terrain := _get_terrain()
	if terrain == null or not _is_in_bounds(point):
		return -1
	return terrain.get_terrain_data(point)["height"]

# get the cost to move from one cell to another for A*
func _get_move_cost(
	from_cell: Vector2i,
	to_cell: Vector2i,
	agent_config: NavAgentConfig,
	agent_context: Dictionary,
	cache: Dictionary
) -> float:
	var from_data: Dictionary = cache.get(from_cell, {})
	var to_data: Dictionary = cache.get(to_cell, {})

	if from_data.is_empty() or to_data.is_empty():
		return INF
	if not to_data["traversable"]:
		return INF

	var edge_max_slope_degrees: float = _get_edge_max_slope_degrees(from_cell, to_cell, from_data, to_data)
	if edge_max_slope_degrees == INF:
		return INF

	var move_context := {
		"from_cell": from_cell,
		"to_cell": to_cell,
		"from_data": from_data,
		"to_data": to_data,
		"edge_max_slope_degrees": edge_max_slope_degrees
	}

	return agent_config.get_nav_cost(agent_context, move_context)

# DEBUG
func sample_patch(
	center: Vector3,
	half_extent_cells: int,
	agent_config: NavAgentConfig
) -> Dictionary:
	var cells: Dictionary = {}
	var center_cell: Vector2i = world_to_cell(center)
	for z in range(-half_extent_cells, half_extent_cells + 1):
		for x in range(-half_extent_cells, half_extent_cells + 1):
			var cell := center_cell + Vector2i(x, z)
			cells[cell] = sample_cell(cell, agent_config)
	return cells

func debug_get_safe_trench_info(cell: Vector2i, agent_config: NavAgentConfig) -> Dictionary:
	var point: Vector3 = cell_to_world(cell)
	var center_height: float = _get_height(point)
	if center_height < 0.0:
		return {
			"valid": false,
			"score": 0.0,
		}

	var agent_radius: float = agent_config.radius
	var agent_height: float = agent_config.height
	var wall_height_threshold: float = agent_config.wall_climb_height
	var max_trench_depth: float = agent_height * 2.0
	var max_trench_width: float = agent_radius * 8.0
	var probe_step: float = max(GRID_CELL_SIZE * 0.5, agent_radius * 0.5)

	var wall_distances: Array[float] = []
	var wall_heights: Array[float] = []
	wall_distances.resize(8)
	wall_heights.resize(8)

	for i in range(8):
		wall_distances[i] = INF
		wall_heights[i] = 0.0

		var angle: float = TAU * float(i) / 8.0
		var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
		var distance: float = probe_step

		while distance <= max_trench_width:
			var sample_height: float = _get_height(point + direction * distance)
			if sample_height < 0.0:
				break

			var wall_height: float = sample_height - center_height
			if wall_height >= wall_height_threshold:
				wall_distances[i] = distance
				wall_heights[i] = wall_height
				break

			distance += probe_step

	var wall_hit_count: int = 0
	for i in range(8):
		if wall_distances[i] != INF:
			wall_hit_count += 1

	var best_score: float = 0.0
	var best_pair: Vector2i = Vector2i(-1, -1)

	for i in range(8):
		for j in range(i + 1, 8):
			var separation_steps: int = j - i
			separation_steps = min(separation_steps, 8 - separation_steps)

			if separation_steps < 3:
				continue

			var wall_a_distance: float = wall_distances[i]
			var wall_b_distance: float = wall_distances[j]

			if wall_a_distance == INF or wall_b_distance == INF:
				continue

			var wall_to_wall_width: float = wall_a_distance + wall_b_distance
			if wall_to_wall_width > max_trench_width:
				continue

			var effective_depth: float = min(wall_heights[i], wall_heights[j])
			if effective_depth > max_trench_depth:
				continue

			var depth_ratio: float = min(effective_depth / agent_height, 1.0)
			var width_ratio: float = 1.0 - (wall_to_wall_width / max_trench_width)
			var trench_score: float = depth_ratio + width_ratio

			if trench_score > best_score:
				best_score = trench_score
				best_pair = Vector2i(i, j)

	return {
		"valid": true,
		"score": best_score,
		"center_height": center_height,
		"wall_height_threshold": wall_height_threshold,
		"max_trench_depth": max_trench_depth,
		"max_trench_width": max_trench_width,
		"probe_step": probe_step,
		"wall_hit_count": wall_hit_count,
		"wall_distances": wall_distances,
		"wall_heights": wall_heights,
		"best_pair": best_pair,
	}
