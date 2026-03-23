extends Node
class_name TerrainManager


const max_tile_readback: int = 4
const max_pixel_readback: int = 490000

var tile_readback_queue: Array[TerrainTile_Class]
var tile_in_queue_set: Dictionary

var TileAssociatedExtractors: Dictionary[TerrainTile_Class, Dictionary]


var terrain: Terrain = null

var resource_data_placeholder_tex: RID
var initialized_placeholder: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	readback_queued_tiles()

		
func register_terrain(t: Terrain) -> void:
	terrain = t

func get_terrain() -> Terrain:
	return terrain


func queue_for_readback(tile: TerrainTile_Class) -> void:
	var tile_id := tile.get_instance_id()

	if (!tile_in_queue_set.get(tile_id, false)):
		tile_readback_queue.append(tile) 
		tile_in_queue_set[tile_id] = true
		
		
func queue_for_readback_with_resources(tile: TerrainTile_Class, extractor: ResourceExtractor) -> void:
	queue_for_readback(tile)
	
	if (!TileAssociatedExtractors.has(tile)):
		TileAssociatedExtractors[tile] = {}
		
	TileAssociatedExtractors[tile].set(extractor, true)
	

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
		tile_readback_queue.erase(tile)
		tile_in_queue_set.erase(tile.get_instance_id())
		
		var extractors: Array = TileAssociatedExtractors.get_or_add(tile, {}).keys()
		
		for e: ResourceExtractor in extractors:
			e.readback_resource_data()
			
		TileAssociatedExtractors[tile].clear()

	if not tiles_to_readback.is_empty():
		Navigation.record_terrain_readback_batch(tiles_to_readback)

func get_or_create_resource_tex() -> RID:
	
	if (!initialized_placeholder):
		var rd := RenderingServer.get_rendering_device()

		var tf : RDTextureFormat = RDTextureFormat.new()
		tf.format = RenderingDevice.DATA_FORMAT_R32_UINT
		tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
		tf.width = 3
		tf.height = 1
		tf.depth = 1
		tf.array_layers = 1
		tf.mipmaps = 1
		tf.usage_bits = RenderingDevice.TEXTURE_USAGE_CPU_READ_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT                                   
		resource_data_placeholder_tex = rd.texture_create(tf, RDTextureView.new())
		initialized_placeholder = true
	
	return resource_data_placeholder_tex
		
		
	
