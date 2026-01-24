
extends Node3D
class_name TerrainTile_Class


var heightmap_tex: Texture2D
var heightmap_mat: ShaderMaterial

var size: int

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
	$HeightMapRT/HeightMapColorRect.material = heightmap_mat
	$HeightMapRT.size = Vector2i(size, size)
	heightmap_tex = $HeightMapRT.get_texture()
	
	await RenderingServer.frame_post_draw
	
	_update_heightmap(heightmap_tex)
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _update_heightmap(new_heightmap: Texture2D) -> void:

	
	$TerrainMeshScale/TerrainMesh.material_override.set_shader_parameter("heightmap", heightmap_tex)
	$TerrainMeshScale/TerrainMesh.material_override.set_shader_parameter("vertical_scale", terrain_height)
	var heightmap_collision: HeightMapShape3D =$StaticBody3D/CollisionShape3D.shape
	var heightmap_img: Image = new_heightmap.get_image()
	heightmap_img.decompress()
	heightmap_img.convert(Image.FORMAT_RF)
	heightmap_collision.update_map_data_from_image(heightmap_img, 0, terrain_height)
	
