shader_type canvas_item;
#include "noise.gdshaderinc"


uniform vec2 offset;
uniform int size;

uniform float heightmap_frequency_scale = 1.0;

uniform float organic_frequency_scale = 1.0;
uniform float crystal_frequency_scale = 1.0;

uniform float organic_offset = 0.0;
uniform float crystal_offset = 0.0;

uniform float organic_scarcity = 0.5;
uniform float crystal_scarcity = 0.5;

float hills(vec2 uv, int tile_size) {

	vec2 sample = (uv * float(tile_size + 3)) + offset;

	float noise = layered_snoise(sample * 1.0/(heightmap_frequency_scale * 100.0), 6);

	return  noise;
}

float resources(vec2 uv, int tile_size) {
	vec2 organic_sample = (uv * float(tile_size + 3)) + organic_offset + offset;
	float organic_noise = layered_snoise(organic_sample * 1.0/(organic_frequency_scale * 100.0), 1);
	
	vec2 crystal_sample = (uv * float(tile_size + 3)) + crystal_offset + offset;
	float crystal_noise = layered_snoise(crystal_sample * 1.0/(crystal_frequency_scale * 100.0), 1);
	
	float organic = ceil(organic_noise - organic_scarcity);
	float crystal = (organic_noise - organic_scarcity < 0.0) ? ceil(crystal_noise - crystal_scarcity) : 0.0;
	
	
	return organic + (2.0 * crystal);
}

void fragment() {


	float height = hills(UV, size);
	
	float res = resources(UV, size);
	
	COLOR = vec4(height, height, res, 1.0);

}