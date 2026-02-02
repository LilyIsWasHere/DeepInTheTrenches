shader_type spatial;
render_mode unshaded, fog_disabled;
uniform sampler2D viewport_tex: source_color;

void vertex() {
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = texture(viewport_tex, UV).xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
