
extends Node3D
class_name TerrainTile_Class


var heightmap_tex: Texture2D
var heightmap_mat: ShaderMaterial
var first_heightmap_update: bool = true

var size: int
var terrain_heightmap_updated: bool = false

const terrain_height: float = 100;

func initialize(_position: Vector3i, _size: int, _heightmap_generator: ShaderMaterial) -> void:
	position = _position
	$TerrainMeshScale.scale = Vector3(_size, 1 ,_size)
	size = _size
	
	heightmap_mat = _heightmap_generator
	
	if _heightmap_generator != null:
		_heightmap_generator.set_shader_parameter("offset", Vector2(position.x, position.z))
		_heightmap_generator.set_shader_parameter("size", size)
		
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HeightMapGenViewport/HeightMapGenColorRect.material = heightmap_mat
	$HeightMapGenViewport.size = Vector2i(size, size)
	heightmap_tex = $HeightMapGenViewport.get_texture()
	
	
	await RenderingServer.frame_post_draw
	
	_update_heightmap(heightmap_tex)
	


	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _update_heightmap(new_heightmap: Texture2D) -> void:

	
	$TerrainMeshScale/TerrainMesh.material_override.set_shader_parameter("heightmap", heightmap_tex)
	$TerrainMeshScale/TerrainMesh.material_override.set_shader_parameter("vertical_scale", terrain_height)
	var heightmap_collision: HeightMapShape3D = $TerrainTileStaticBody3D/CollisionShape3D.shape
	var heightmap_img: Image = new_heightmap.get_image()
	heightmap_img.decompress()
	heightmap_img.convert(Image.FORMAT_RF)
	heightmap_collision.update_map_data_from_image(heightmap_img, 0, terrain_height)
	
	
func sculpt_tile(global_pos: Vector3, radius: float, height: float) -> void:
	var world_to_local: Transform3D = global_transform.inverse()
	var local_pos: Vector3 = world_to_local * global_pos
	var global_scale: Vector3 = _get_global_scale($TerrainMeshScale/TerrainMesh.global_transform.basis)
	var pixel_pos: Vector3 = ((local_pos / (0.1 * global_scale)) + Vector3(0.5, 0.5, 0.5)) * float(size)
	
	_update_edit_heightmap_compositor(Vector2(pixel_pos.x, pixel_pos.z), radius, height)


func _update_edit_heightmap_compositor(position: Vector2, radius: float, height: float) -> void:
	var compositor_effect: HeightmapEditCompositorEffect = $HeightMapGenViewport/WorldEnvironment/HeightMapEditCam.compositor.compositor_effects[0]
	compositor_effect.location = position
	compositor_effect.radius = radius
	compositor_effect.height = height
	
	
	$HeightMapGenViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# await RenderingServer.frame_post_draw
	_update_heightmap(heightmap_tex)
	
	if (first_heightmap_update):
		$HeightMapGenViewport/HeightMapGenColorRect.queue_free()
		first_heightmap_update = false

	

		

	
	
func _get_global_scale(basis: Basis) -> Vector3:
	var scaleX:Vector3 = Vector3(basis.x.x, basis.y.x, basis.z.x)
	var scaleY:Vector3 = Vector3(basis.x.y, basis.y.y, basis.z.y)
	var scaleZ:Vector3 = Vector3(basis.x.z, basis.y.z, basis.z.z)
	var scale_x_len: float = scaleX.length()
	var scale_y_len: float = scaleY.length()
	var scale_z_len: float = scaleZ.length()
	
	return Vector3(scale_x_len, scale_y_len, scale_z_len)
