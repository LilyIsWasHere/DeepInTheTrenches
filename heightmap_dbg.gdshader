shader_type spatial;
render_mode unshaded;

uniform sampler2D heightmap: source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = fract(texture(heightmap, UV).xyz);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
