shader_type canvas_item;

// Speed of vertical scroll (positive = downward, negative = upward)
uniform float scroll_speed : hint_range(-5.0, 5.0) = 1.0;

void fragment() {
    // Offset UV vertically based on time, wrap with fract() for seamless loop
    vec2 offset_uv = UV + vec2(0.0, TIME * scroll_speed);
    vec2 scrolled_uv = fract(offset_uv);

    COLOR = texture(TEXTURE, scrolled_uv);
}