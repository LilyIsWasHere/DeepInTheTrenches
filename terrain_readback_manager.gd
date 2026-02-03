extends Node



const max_tile_readback: int = 4
const max_pixel_readback: int = 490000

var tile_readback_queue: Array[TerrainTile_Class]
var tile_in_queue_set: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (tile_readback_queue.size() > 0): print("tiles in queue: " + str(tile_readback_queue.size()))
	readback_queued_tiles()

		
		
func queue_for_readback(tile: TerrainTile_Class) -> void:
	var tile_id := tile.get_instance_id()

	if (!tile_in_queue_set.get(tile_id, false)):
		tile_readback_queue.append(tile) 
		tile_in_queue_set[tile_id] = true

func readback_queued_tiles() -> void:
	var pixel_count: int = 0
	
	var tiles_to_readback: Array[TerrainTile_Class] = []
	for i in range(min(tile_readback_queue.size(), max_tile_readback)):
		var tile: TerrainTile_Class = tile_readback_queue[i]
		pixel_count += tile.size * tile.size
		
		if (pixel_count > max_pixel_readback):
			break
		else:
			tiles_to_readback.append(tile)
		
		
	for tile in tiles_to_readback:
		tile.readback_heightmap_data()
		tile_readback_queue.pop_front()
		tile_in_queue_set.erase(tile)
	
	
	
