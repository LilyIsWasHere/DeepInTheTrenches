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
