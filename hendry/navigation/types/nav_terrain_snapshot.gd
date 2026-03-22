# frozen terrain data used by threaded navigation
extends RefCounted
class_name NavTerrainSnapshot

var terrain_global_transform: Transform3D = Transform3D.IDENTITY
var num_tiles: Vector2i = Vector2i.ZERO
var tile_size: int = 0
var tiles: Dictionary = {}

# copies the entire terrain into the snapshot
# only for initialization
func rebuild_from_terrain(terrain: Terrain) -> void:
	terrain_global_transform = terrain.global_transform
	num_tiles = terrain.num_tiles
	tile_size = terrain.tile_size
	tiles.clear()

	for x in range(terrain.tile_arr.size()):
		var column: Array = terrain.tile_arr[x]

		for y in range(column.size()):
			var tile: TerrainTile_Class = column[y]
			if tile == null or tile.heightmap_img == null:
				continue

			var heightmap_copy := Image.new()
			heightmap_copy.copy_from(tile.heightmap_img)

			tiles[Vector2i(x, y)] = {
				"heightmap_img": heightmap_copy,
			}

# refreshes changed tiles
func refresh_dirty_tiles_from_terrain(terrain: Terrain, dirty_tiles: Dictionary) -> void:
	terrain_global_transform = terrain.global_transform
	num_tiles = terrain.num_tiles
	tile_size = terrain.tile_size

	var dirty_tile_values: Array = dirty_tiles.values()

	for i in range(dirty_tile_values.size()):
		var tile_info: Dictionary = dirty_tile_values[i]
		var tile_position: Vector3 = tile_info["position"]
		var local_position: Vector3 = terrain.global_transform.affine_inverse() * tile_position
		var tile_coord := Vector2i(
			int(round(local_position.x / float(tile_size))),
			int(round(local_position.z / float(tile_size)))
		)

		var tile: TerrainTile_Class = terrain.tile_arr[tile_coord.x][tile_coord.y]
		if tile == null or tile.heightmap_img == null:
			continue

		var heightmap_copy := Image.new()
		heightmap_copy.copy_from(tile.heightmap_img)

		tiles[tile_coord] = {
			"heightmap_img": heightmap_copy,
		}

# helper to check if a point is within the bounds of the terrain
func _is_in_bounds(point: Vector3) -> bool:
	var local_point: Vector3 = terrain_global_transform.affine_inverse() * point
	var half_tile: float = float(tile_size) * 0.5
	var min_x: float = -half_tile
	var min_z: float = -half_tile
	var max_x: float = float(num_tiles.x * tile_size) - half_tile
	var max_z: float = float(num_tiles.y * tile_size) - half_tile

	return local_point.x >= min_x and local_point.x < max_x and local_point.z >= min_z and local_point.z < max_z

# same as Terrain.get_terrain_data but using the snapshot's data
func get_terrain_data(point: Vector3) -> Dictionary:
	if not _is_in_bounds(point):
		return {}

	var local_point: Vector3 = terrain_global_transform.affine_inverse() * point
	var tile_coord := Vector2i(
		int(floor((local_point.x + float(tile_size) * 0.5) / float(tile_size))),
		int(floor((local_point.z + float(tile_size) * 0.5) / float(tile_size)))
	)

	if not tiles.has(tile_coord):
		return {}

	var tile_data: Dictionary = tiles[tile_coord]
	var heightmap_img: Image = tile_data["heightmap_img"]

	var tile_origin := Vector3(
		float(tile_coord.x * tile_size),
		0.0,
		float(tile_coord.y * tile_size)
	)
	var tile_local_point: Vector3 = local_point - tile_origin

	var pixel_x: int = int(clamp(floor(tile_local_point.x + float(tile_size) * 0.5), 0.0, float(heightmap_img.get_width() - 1)))
	var pixel_z: int = int(clamp(floor(tile_local_point.z + float(tile_size) * 0.5), 0.0, float(heightmap_img.get_height() - 1)))

	var px_val: Color = heightmap_img.get_pixel(pixel_x, pixel_z)

	return {
		"height": px_val.r * 10.0,
		"initial_height": px_val.g * 10.0,
		"resource": int(px_val.b),
	}

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
