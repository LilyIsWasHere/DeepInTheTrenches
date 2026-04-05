shader_type spatial;
render_mode unshaded;

uniform sampler2D heightmap;
uniform sampler2D albedo_tex;
uniform float heightmap_scale = 1.0;


void vertex() {
	
	
	vec3 wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * vec3(100.0/428.0, 1.0, 1.0) * 0.01;
	UV = wpos.xz;
	VERTEX.y += texture(heightmap, UV).r * heightmap_scale;
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb * 0.3;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
