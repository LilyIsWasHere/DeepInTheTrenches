shader_type spatial;

uniform sampler2D heightmap: repeat_disable;
uniform float vertical_scale = 100;

const float normal_offset = 0.001;

varying vec3 world_position;
varying vec3 world_normal;


// Returns the weights for a cubic spline interpolation.
// This function is called by textureBicubic()
//
// References:
//  https://stackoverflow.com/questions/13501081/efficient-bicubic-filtering-code-in-glsl
//  http://www.java-gaming.org/index.php?topic=35123.0
vec4 
cubic_spline_weights(float v)
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

	return texture(heightmap, position).x * vertical_scale;
	// return texture(heightmap, position).x * heightmap_scale;
}



void vertex() {
	
	
	
	// Called for every vertex the material is visible on.
  	vec2 pos = UV;
  	float k = height(pos);
 	VERTEX.y = k;
	NORMAL = normalize(vec3(height(pos + vec2(-normal_offset, 0.0)) - height(pos + vec2(normal_offset, 0.0)), normal_offset, height(pos + vec2(0.0, -normal_offset)) - height(pos + vec2(0.0, normal_offset))));
	
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = (vec4(NORMAL, 1.0)).xyz;
	
}

void fragment() {
	// Called for every pixel the material is visible on.
	// ALBEDO = NORMAL;
	
	
	bool banding = mod(world_position.y, 1) < 0.9;
	
	if (distance(world_normal, vec3(0, 1, 0)) < 0.05) {
		banding = false;
	}
	
	vec3 color = vec3(UV.x, UV.y, 0.5) * float(banding);
	
	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
