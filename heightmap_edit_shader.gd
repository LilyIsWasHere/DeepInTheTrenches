@tool
extends CompositorEffect
class_name HeightmapEditCompositorEffect

@export_group("Shader Settings")
@export var location := Vector2(0, 0)
@export var radius: float = 10
@export var height: float = 0.2


var rd : RenderingDevice
var heightmap_edit_compute : ACompute

func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()

	# To make use of an existing ACompute shader we use its filename to access it, in this case, the example compute shader file is 'heightmap_edit.acompute'
	heightmap_edit_compute = ACompute.new('heightmap_edit')


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# ACompute will handle the freeing of any resources attached to it
		heightmap_edit_compute.free()


func _render_callback(p_effect_callback_type: int, p_render_data: RenderData) -> void:
	if not enabled: return
	if p_effect_callback_type != EFFECT_CALLBACK_TYPE_POST_TRANSPARENT: return
	
	if not rd:
		push_error("No rendering device")
		return
	
	var render_scene_buffers : RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()

	if not render_scene_buffers:
		push_error("No buffer to render to")
		return

	
	var size: Vector2i = render_scene_buffers.get_internal_size()
	if size.x == 0 and size.y == 0:
		push_error("Rendering to 0x0 buffer")
		return
	
	var x_groups: int = (size.x - 1) / 8 + 1
	var y_groups: int = (size.y - 1) / 8 + 1
	var z_groups: int = 1
	
	# Vulkan has a feature known as push constants which are like uniform sets but for very small amounts of data
	var push_constant : PackedFloat32Array = PackedFloat32Array([size.x, size.y, 0.0, 0.0])
	
	for view in range(render_scene_buffers.get_view_count()):
		var input_image: RID = render_scene_buffers.get_color_layer(view)


		# Pack the exposure vector into a byte array
		var uniform_array := PackedFloat32Array([location.x, location.y, radius, height, float(Time.get_ticks_msec()), 0.0, 0.0, 0.0]).to_byte_array()
		
		# ACompute handles uniform caching under the hood, as long as the exposure value doesn't change or the render target doesn't change, these functions will only do work once
		heightmap_edit_compute.set_texture(0, input_image)
		heightmap_edit_compute.set_uniform_buffer(1, uniform_array)
		heightmap_edit_compute.set_push_constant(push_constant.to_byte_array())

		# Dispatch the compute kernel
		heightmap_edit_compute.dispatch(0, x_groups, y_groups, z_groups)
