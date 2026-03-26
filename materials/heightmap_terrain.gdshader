shader_type spatial;

uniform sampler2D heightmap: repeat_disable, filter_nearest;
uniform float vertical_scale = 100;

const float normal_offset = 0.001;

varying vec3 world_position;
varying vec3 world_normal;

uniform vec4 organic_colour: source_color = vec4(1,0,0,1);
uniform vec4 crystal_colour: source_color = vec4(0.5,0,0,1);

uniform sampler2D crystal_albedo_texture;
uniform float crystal_tex_scale;

uniform sampler2D organic_albedo_texture: source_color;
uniform float organic_tex_scale;

uniform float organic_diffuse;
uniform float organic_specular;
uniform float organic_clearcoat;

// Returns the weights for a cubic spline interpolation.
// This function is called by textureBicubic()
//
// References:
//  https://stackoverflow.com/questions/13501081/efficient-bicubic-filtering-code-in-glsl
//  http://www.java-gaming.org/index.php?topic=35123.0

vec4 cubic_spline_weights(float v)
{
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

// Func:    textureBicubic( sampler, texCoords )
//
// Desc:    Performs a texture lookup on the texture bound to 'sampler', but
//          instead of the standard (built-in) bilinear filtering, this call performs
//          bicubic spline filtering.
//
//          This provides rounder, smoother interpolation, w/o pyramid edges that
//          are prone to happen using bilinear.
//
// References:
//  https://stackoverflow.com/questions/13501081/efficient-bicubic-filtering-code-in-glsl
//  https://developer.nvidia.com/gpugems/gpugems2/part-iii-high-quality-rendering/chapter-20-fast-third-order-texture-filtering
//
vec4 textureBicubic(sampler2D sampler, vec2 texCoords)
{
   vec2 texSize = vec2(textureSize(sampler, 0));
   vec2 invTexSize = 1.0 / texSize;

   texCoords = texCoords * texSize - 0.5;


    vec2 fxy = fract(texCoords);
    texCoords -= fxy;

    vec4 xcubic = cubic_spline_weights(fxy.x);
    vec4 ycubic = cubic_spline_weights(fxy.y);

    vec4 c = texCoords.xxyy + vec2 (-0.5, +1.5).xyxy;

    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

    offset *= invTexSize.xxyy;

    vec4 sample0 = texture(sampler, offset.xz);
    vec4 sample1 = texture(sampler, offset.yz);
    vec4 sample2 = texture(sampler, offset.xw);
    vec4 sample3 = texture(sampler, offset.yw);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
       mix(sample3, sample2, sx),
       mix(sample1, sample0, sx),
       sy);
}


float height(vec2 position) {

	return textureBicubic(heightmap, position).x * vertical_scale;
	// return texture(heightmap, position).x * heightmap_scale;
}

vec2 scale_uv_by_center(vec2 uv, vec2 scale) {
	 return (uv-vec2(0.5,0.5)*scale) + vec2(0.5, 0.5);
}


vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 fromLinear(vec4 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);

    return vec4(mix(higher, lower, cutoff), linearRGB.a);
}

// Converts a color from sRGB gamma to linear light gamma
vec4 toLinear(vec4 sRGB)
{
    bvec3 cutoff = lessThan(sRGB.rgb, vec3(0.04045));
    vec3 higher = pow((sRGB.rgb + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB.rgb/vec3(12.92);

    return vec4(mix(higher, lower, cutoff), sRGB.a);
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}


varying float is_edge;

void vertex() {

	//vec2 tex_size = vec2(textureSize(heightmap, 0));
//
	//vec2 scale_adj = (1.0 / tex_size) * 2.0;
	//UV = scale_uv_by_center(UV, 1.0 + scale_adj);
	if (min(UV.x, UV.y) == 0.0 || max(UV.x, UV.y) == 1.0) {
		is_edge = 1.0;
	}
	else is_edge = 0.0;

  	vec2 pos = UV;
  	float k = height(pos);
 	VERTEX.y = k;

	vec2 height_delta = vec2(height(pos + vec2(-normal_offset, 0.0)) - height(pos + vec2(normal_offset, 0.0)), height(pos + vec2(0.0, -normal_offset)) - height(pos + vec2(0.0, normal_offset)));
	NORMAL = normalize(vec3(height_delta.x, 100.0*normal_offset, height_delta.y));

    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((vec4(NORMAL, 1.0)).xyz);

}

uniform float band_thickness = 0.15;
uniform float band_height = 0.5;

uniform bool antialiasing = true;
uniform bool aa_opacity = true;
uniform bool display_aa_bands = false;

void fragment() {
	// Called for every pixel the material is visible on.
	// ALBEDO = NORMAL;


	vec2 tex_size = vec2(textureSize(heightmap, 0));
    vec4 height_data = texture(heightmap, UV);
	int resource_data = int(round(height_data.z));
	
	float slope_offset = 1.0 / tex_size.x;
	float slope = length(vec2(	height_data.x - texture(heightmap, UV + vec2(slope_offset, slope_offset)).x, 	height_data.y - texture(heightmap, UV + vec2(-slope_offset, slope_offset)).x	));
	
	float scaled_band_thickness = band_height * band_thickness;
	
	float bmod = mod(world_position.y, band_height);

	vec2 px_dd = vec2(dFdx(world_position.y), dFdy(world_position.y));
	float band_range = scaled_band_thickness * pow(slope, 0.33);
	float aa_band_range = max(band_range, length(px_dd));
	
	
	float banding = float(mod(world_position.y, band_height) >= band_height - band_range);
	float aa_banding = float(mod(world_position.y, band_height) >= band_height - aa_band_range);
	
	vec3 override = vec3(0.0);
	
	if (aa_opacity) {
		if (aa_banding > 0.9 && length(px_dd) > band_range) {
			aa_banding = mix(0.5, 1.0, sqrt(band_range / length(px_dd)));
			if ((px_dd.x > band_range || px_dd.y > band_range) && display_aa_bands) override = vec3(1.0, 0.0, 0.0);

		}
	}
	
	if(antialiasing) banding = aa_banding;


	vec2 banding_dd = vec2(dFdx(bmod), dFdy(bmod));
	// Analytical AA
	

	vec3 dirt_color = vec3(0.1, 0.05, 0.02);
	vec3 grass_color = vec3(0.3, 0.5, 0.3);

    vec3 mud_colour = vec3(0.07, 0.08, 0.055);

	float flatness = dot(vec3(0.0, 1.0, 0.0), world_normal);

	float height_diff = abs(height_data.r - height_data.g);
	float h = clamp(10.0 * height_diff, 0.0, 1.0);
	vec3 flat_colour = mix(grass_color, mud_colour, h);

	vec3 color = mix(dirt_color, flat_colour, flatness);


	vec3 crystal_tex_val = texture(crystal_albedo_texture, crystal_tex_scale*UV).rgb;
	vec3 organic_tex_val = texture(organic_albedo_texture, organic_tex_scale*UV).rgb;
	
	switch(resource_data) {
		case 1:
			color = mix(color, organic_tex_val, 0.6);
			SPECULAR = organic_specular;
			ROUGHNESS = organic_diffuse;
			CLEARCOAT = organic_clearcoat;
			break;
		case 2:
			color = crystal_tex_val.rgb;
			break;

	}



	ALBEDO = color * (1.0 - banding);
	if (length(override) > 0.01) ALBEDO = override;
	// if (show_dd) ALBEDO = vec3(bmod, 0.0, 0.0);


	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = (is_edge > 0.0) ? 0.0 : 1.0;

    ROUGHNESS = 1.0;
    SPECULAR = mix(0.0, mix(0.0, 0.5, flatness), h);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
