shader_type spatial;
render_mode unshaded;

uniform int team = 0;
uniform float near_vanish_dist = 5.0;
uniform float vanish_range = 3.0;

varying vec3 worldpos;
void vertex() {
	// Called for every vertex the material is visible on.
	worldpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (team == 0) {
		ALBEDO = vec3(0.0,0.0,1);
	}
	else {
		ALBEDO = vec3(1,0,0);
	}
	
	float dist = distance(CAMERA_POSITION_WORLD, worldpos); 
	
	ALPHA = clamp(((dist - near_vanish_dist) / (near_vanish_dist + vanish_range)), 0.0, 1.0);
	
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
