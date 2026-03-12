extends Node3D
class_name ResourceExtractor

signal resource_items_extracted(item: InventoryItem, quantity: int)

const num_resource_types: int = 3
var resource_data_tex: RID

var resource_data: Array[int] = [0,0,0]

@export var default_item_conversion_factor: float = 0.001
@export var organic_item_conversion_factor: float = 0.001
@export var crystal_item_conversion_factor: float = 0.001

@export var inventory_connection: Inventory

enum ResourceID {
	DEFAULT,
	ORGANIC,
	CRYSTAL
}

var resource_item_map: Dictionary[ResourceID, InventoryItem] = {
	ResourceID.DEFAULT: preload("res://Inventory/InventoryItems/defualt_terrain_item.tres"),
	ResourceID.ORGANIC: preload("res://Inventory/InventoryItems/organic_material_item.tres"),
	ResourceID.CRYSTAL: preload("res://Inventory/InventoryItems/energy_crystal_item.tres")
}

var rd: RenderingDevice


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rd = RenderingServer.get_rendering_device()
	
	var tf : RDTextureFormat = RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R32_UINT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = 3
	tf.height = 1
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_CPU_READ_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT                                   

	resource_data_tex = rd.texture_create(tf, RDTextureView.new())
	
	rd.texture_clear(resource_data_tex, Color(0,0,0,0), 0, 1, 0, 1)

func _get_adjusted_resource_quantities(default: int, organic: int, crystal: int) -> Array[int]:
	
	
	return [int(round(default * default_item_conversion_factor)), int(round(organic * organic_item_conversion_factor)), int(round(crystal * crystal_item_conversion_factor))]

func readback_resource_data() -> void:
	await get_tree().process_frame
	rd.texture_get_data_async(resource_data_tex, 0, _on_texture_readback_complete)
	# rd.texture_get_data_async(resource_data_tex, 0, _on_texture_readback_complete)



	
	
func _on_texture_readback_complete(data: PackedByteArray) -> void:

	var new_resource_data: Array = Array(data.to_int32_array())
	var default_delta: int = new_resource_data[ResourceID.DEFAULT] - resource_data[ResourceID.DEFAULT]
	var organic_delta: int = new_resource_data[ResourceID.ORGANIC] - resource_data[ResourceID.ORGANIC]
	var crystal_delta: int = new_resource_data[ResourceID.CRYSTAL] - resource_data[ResourceID.CRYSTAL]
	var resource_amts: Array[int] = _get_adjusted_resource_quantities(default_delta, organic_delta, crystal_delta)
	
	for i in resource_amts.size():
		if (resource_amts[i]) > 0:
			resource_items_extracted.emit(resource_item_map[i], resource_amts[i])
			
			if (inventory_connection != null):
				inventory_connection.add_items(resource_item_map[i], resource_amts[i])
			
	#workaround for weird typing error: 'Trying to assign an array of type "Array" to a variable of type "Array[int]".'
	resource_data = [new_resource_data[0], new_resource_data[1], new_resource_data[2]]
	
	
func get_resource_tex() -> RID:
	return resource_data_tex

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
