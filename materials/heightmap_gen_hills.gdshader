shader_type canvas_item;
#include "noise.gdshaderinc"


uniform vec2 offset;
uniform int size;

uniform float frequency_scale = 1.0;



float hills(vec2 uv, int tile_size, vec2 tile_offset) {

	vec2 sample = (uv * float(tile_size + 3)) + offset;

	float noise = layered_snoise(sample * 1.0/(frequency_scale * 100.0), 6);

	return  noise;
}

void fragment() {


	float height = hills(UV, size, offset);
	COLOR = vec4(height, height, 0, 1);

}