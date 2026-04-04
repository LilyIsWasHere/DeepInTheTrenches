shader_type canvas_item;
uniform float border_size_px;
uniform vec3 border_color: source_color;

varying vec2 pixel_pos;

void vertex() {
	pixel_pos = VERTEX;
}

void fragment() {
	
	vec2 border_size = border_size_px * SCREEN_PIXEL_SIZE;
	bool is_border = UV.x < border_size.x || UV.y < border_size.y || UV.x > 1.0-border_size.x || UV.y > 1.0 - border_size.y;
	COLOR = vec4(border_color, float(is_border));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
