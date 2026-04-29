shader_type spatial;

uniform sampler2D noise;
uniform float scale;
uniform float opacity;
varying vec3 world_pos;


void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(world_pos.x,world_pos.z);
	float x = abs(UV.x - 0.5) * 2.0;
	float x_gradient = 1.0 - x;
	vec4 noise_tex = texture(noise,uv * scale);
	ALBEDO = vec3(1.0,1.0,1.0);
	ALPHA = COLOR.a * noise_tex.r * opacity * x_gradient;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
