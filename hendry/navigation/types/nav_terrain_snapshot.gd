# frozen terrain data used by threaded navigation
extends RefCounted
class_name NavTerrainSnapshot

var terrain_global_transform: Transform3D = Transform3D.IDENTITY
var num_tiles: Vector2i = Vector2i.ZERO
var tile_size: int = 0
var tiles: Dictionary = {}
var dirty_tile_coords: Array[Vector2i] = []

# copies the entire terrain into the snapshot
# only for initialization
func rebuild_from_terrain(terrain: Terrain) -> void:
	terrain_global_transform = terrain.global_transform
	num_tiles = terrain.num_tiles
	tile_size = terrain.tile_size
	tiles.clear()
	dirty_tile_coords.clear()

	# make a snapshot of each tile and store it in the dictionary, keyed by tile coordinate
	for x in range(terrain.tile_arr.size()):
		var column: Array = terrain.tile_arr[x]

		for y in range(column.size()):
			var tile: TerrainTile_Class = column[y]
			if tile == null or tile.heightmap_img == null:
				continue

			tiles[Vector2i(x, y)] = _make_tile_snapshot(tile)

# create a new snapshot with updated data for the dirty tiles, shallow copying the rest
func create_refreshed_copy(terrain: Terrain, dirty_tiles: Dictionary) -> NavTerrainSnapshot:
	var snapshot := NavTerrainSnapshot.new()

	# shallow copy the unchanged data, then deep copy the dirty tiles
	snapshot.terrain_global_transform = terrain.global_transform
	snapshot.num_tiles = terrain.num_tiles
	snapshot.tile_size = terrain.tile_size
	snapshot.tiles = tiles.duplicate()

	# deep copy the dirty tiles and store their coordinates in the snapshot for A* map updating
	var dirty_tile_values: Array = dirty_tiles.values()
	for i in range(dirty_tile_values.size()):
		var tile_coord: Vector2i = dirty_tile_values[i]
		var tile: TerrainTile_Class = terrain.tile_arr[tile_coord.x][tile_coord.y]
		if tile == null or tile.heightmap_img == null:
			continue

		snapshot.tiles[tile_coord] = _make_tile_snapshot(tile)
		snapshot.dirty_tile_coords.append(tile_coord)

	return snapshot

# same as Terrain.get_terrain_data and TerrainTile.get_terrain_data but using the snapshot's data
func get_terrain_data(point: Vector3) -> Dictionary:
	var local_point: Vector3 = terrain_global_transform.affine_inverse() * point

	# get the tile coordinate
	var tile_coord: Vector2i = _array_coord(Vector2(local_point.x, local_point.z))
	if not tiles.has(tile_coord):
		return {}

	# get the tile data and get the data out of the heightmap image
	var tile_data: Dictionary = tiles[tile_coord]
	var heightmap_img: Image = tile_data["heightmap_img"]
	var pixel_pos: Vector2i = _global_to_pixel(tile_data, point)
	var px_val: Color = heightmap_img.get_pixelv(pixel_pos)
	var data: Dictionary
	data["height"] = px_val.r * 10.0
	data["initial_height"] = px_val.g * 10.0
	data["resource"] = int(px_val.b)
	return data

# same as Terrain.get_terrain_slope but using the snapshot's data
func get_terrain_slope(point: Vector3) -> Array:
	var data_p: Dictionary = get_terrain_data(point)
	if data_p.is_empty():
		return []

	var offset: float = 1.0
	var data_x: Dictionary = get_terrain_data(point + Vector3(offset, 0.0, 0.0))
	var data_z: Dictionary = get_terrain_data(point + Vector3(0.0, 0.0, offset))

	if data_x.is_empty() or data_z.is_empty():
		return []

	var slope_x: float = (float(data_x["height"]) - float(data_p["height"])) / offset
	var slope_z: float = (float(data_z["height"]) - float(data_p["height"])) / offset

	return [slope_x, slope_z, sqrt(slope_x * slope_x + slope_z * slope_z)]

# create a Rect2i in cell coordinates that fully contains the terrain for A* map generation
func make_astar_grid(cell_size: float) -> Rect2i:
	var half_tile: float = float(tile_size) * 0.5
	var local_min := Vector3(-half_tile, 0.0, -half_tile)
	var local_max := Vector3(
		float(num_tiles.x * tile_size) - half_tile,
		0.0,
		float(num_tiles.y * tile_size) - half_tile
	)

	var world_min: Vector3 = terrain_global_transform * local_min
	var world_max: Vector3 = terrain_global_transform * local_max

	var min_cell_x: int = int(floor(world_min.x / cell_size))
	var min_cell_y: int = int(floor(world_min.z / cell_size))
	var max_cell_x: int = int(ceil(world_max.x / cell_size)) - 1
	var max_cell_y: int = int(ceil(world_max.z / cell_size)) - 1

	return Rect2i(
		Vector2i(min_cell_x, min_cell_y),
		Vector2i(max_cell_x - min_cell_x + 1, max_cell_y - min_cell_y + 1)
	)

# we know which tiles are dirty, so this translates that into which A* grid cells are dirty
func get_dirty_cells(cell_size: float, padding_cells: int = 1) -> Array[Vector2i]:
	var cells_by_id: Dictionary = {}
	var half_tile: float = float(tile_size) * 0.5

	for i in range(dirty_tile_coords.size()):
		var tile_coord: Vector2i = dirty_tile_coords[i]
		var local_min := Vector3(
			float(tile_coord.x * tile_size) - half_tile,
			0.0,
			float(tile_coord.y * tile_size) - half_tile
		)
		var local_max := local_min + Vector3(float(tile_size), 0.0, float(tile_size))

		var world_min: Vector3 = terrain_global_transform * local_min
		var world_max: Vector3 = terrain_global_transform * local_max

		# draw out the dirty rect in cell coordinates
		var min_cell_x: int = int(floor(world_min.x / cell_size)) - padding_cells
		var min_cell_y: int = int(floor(world_min.z / cell_size)) - padding_cells
		var max_cell_x: int = int(ceil(world_max.x / cell_size)) - 1 + padding_cells
		var max_cell_y: int = int(ceil(world_max.z / cell_size)) - 1 + padding_cells

		# collect all the cells in the dirty rect
		for y in range(min_cell_y, max_cell_y + 1):
			for x in range(min_cell_x, max_cell_x + 1):
				cells_by_id[Vector2i(x, y)] = true

	# go through all the dirty cells we collected and put them in an array to return
	var dirty_cell_keys: Array = cells_by_id.keys()
	var result: Array[Vector2i] = []
	for i in range(dirty_cell_keys.size()):
		var cell: Vector2i = dirty_cell_keys[i]
		result.append(cell)

	return result

# helper to make a snapshot of a tile's data
func _make_tile_snapshot(tile: TerrainTile_Class) -> Dictionary:
	var heightmap_copy := Image.new()
	heightmap_copy.copy_from(tile.heightmap_img)

	var tile_mesh: Node3D = tile.get_node("TerrainMeshScale/TerrainMesh")
	var tile_data: Dictionary = {}
	tile_data["heightmap_img"] = heightmap_copy
	tile_data["global_transform"] = tile.global_transform
	tile_data["mesh_global_scale"] = _get_global_scale(tile_mesh.global_transform.basis)
	tile_data["size"] = tile.size
	return tile_data

# from terrain.gd
func _array_coord(local_coord: Vector2) -> Vector2i:
	return Vector2i(int((local_coord.x + tile_size / 2) / tile_size), int((local_coord.y + tile_size / 2) / tile_size))

# from terrain_tile.gd
func _global_to_pixel(tile_data: Dictionary, global_pos: Vector3) -> Vector2i:
	var tile_global_transform: Transform3D = tile_data["global_transform"]
	var world_to_local: Transform3D = tile_global_transform.inverse()
	var local_pos: Vector3 = world_to_local * global_pos
	var global_scale: Vector3 = tile_data["mesh_global_scale"]
	var size_value: int = tile_data["size"]
	var pixel_pos: Vector3 = ((local_pos / (0.1 * global_scale)) + Vector3(0.5, 0.5, 0.5)) * float(size_value)
	return Vector2i(pixel_pos.x, pixel_pos.z)

# from terrain_tile.gd
func _get_global_scale(basis: Basis) -> Vector3:
	var scale_x: Vector3 = Vector3(basis.x.x, basis.y.x, basis.z.x)
	var scale_y: Vector3 = Vector3(basis.x.y, basis.y.y, basis.z.y)
	var scale_z: Vector3 = Vector3(basis.x.z, basis.y.z, basis.z.z)
	var scale_x_len: float = scale_x.length()
	var scale_y_len: float = scale_y.length()
	var scale_z_len: float = scale_z.length()
	return Vector3(scale_x_len, scale_y_len, scale_z_len)
