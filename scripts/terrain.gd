extends Node3D
class_name Terrain

@export var num_tiles: Vector2i
@export var tile_size: int
@export var heightmap_gen_material: ShaderMaterial
# Called when the node enters the scene tree for the first time.

var terrain_tile_scene := preload("res://TerrainTile.tscn")

var tile_arr: Array[Array] = [[]]

func _init() -> void:
	
	
	pass

func _ready() -> void:
	for x in range(num_tiles.x):
		tile_arr.append([])
		for z in range(num_tiles.y):
			var tile: TerrainTile_Class = terrain_tile_scene.instantiate()
			tile.initialize(Vector3i(x * tile_size, 0, z * tile_size), tile_size, heightmap_gen_material.duplicate(true))
			tile_arr[x].append(tile)
			self.add_child(tile)
			
	
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void: 
	pass
	
	
func sculpt_terrain(global_pos: Vector3i, radius: float, height: float) -> void:
	var affected_tiles: Array[TerrainTile_Class] = get_affected_tiles(global_pos, radius)
	
	for tile in affected_tiles:
		tile.sculpt_tile(global_pos, radius, height)
	
	
func _array_coord(local_coord: Vector2) -> Vector2i:
	return Vector2i(int((local_coord.x + tile_size/2) / tile_size), int((local_coord.y + tile_size/2) / tile_size))
	

func _tile_in_radius(array_coord: Vector2i, circle_origin: Vector2, r: float) -> bool:
	var cx: float = circle_origin.x
	var cy: float = circle_origin.y
	
	var tile_pos: Vector3 = tile_arr[array_coord.x][array_coord.y].position
	var rx: float = tile_pos.x - (tile_size / 2)
	var ry: float = tile_pos.z - (tile_size / 2)
	
	print("	rx: " + str(rx))
	print("	ry: " + str(ry))
	
	var testX := cx;
	var testY := cy;
	var rw: float = tile_size
	var rh: float = tile_size
	
	if (cx < rx):         testX = rx
	elif (cx > rx+rw): testX = rx + rw
	if (cy < ry):         testY = ry
	elif (cy > ry+rh): testY = ry + rh
	
	print("	testX: " + str(testX))
	print("	testY: " + str(testY))
	
	var distX := cx-testX;
	var distY := cy-testY;
	var distance := sqrt( (distX*distX) + (distY*distY) )

	if (distance <= r):
		print("	tile at " + str(array_coord) + ": TRUE")
		return true
	else:
		print("	tile at " + str(array_coord) + ": FALSE")
		return false
	
	

func get_affected_tiles(global_pos: Vector3, radius: float) -> Array[TerrainTile_Class]:
	var world_to_local: Transform3D = global_transform.affine_inverse()
	var local_pos: Vector3 = world_to_local * global_pos
	
	var origin: Vector2 = Vector2(local_pos.x, local_pos.z)
	
	print("origin local pos: " + str(origin))
	print("origin array coord: " + str(_array_coord(origin)))
	
	
	var max_x: int = _array_coord(origin + Vector2(radius, 0)).x
	var min_x: int = _array_coord(origin + Vector2(-radius, 0)).x
	var max_y: int = _array_coord(origin + Vector2(0, radius)).y
	var min_y: int = _array_coord(origin + Vector2(0, -radius)).y
	
	print("min: " + str(Vector2i(min_x, min_y)))
	print("max: " + str(Vector2i(max_x, max_y)))

	if (max_x == min_x && max_y == min_y):
		print("radius within single tile: " + str(Vector2i(max_x, max_y)))
		print(" ")
		return [tile_arr[max_x][max_y]]	
		
	var affected_tiles: Array[TerrainTile_Class] = []
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if(_tile_in_radius(Vector2i(x, y), origin, radius)):
				affected_tiles.append(tile_arr[x][y])
				print(Vector2i(x, y))
				
				
	print(" ")
	return affected_tiles
