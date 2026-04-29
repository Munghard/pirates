shader_type spatial;
render_mode depth_test_disabled;

uniform vec3 color1 : source_color;
uniform vec3 color2 : source_color;
uniform vec3 color3 : source_color;
uniform sampler2D noise;
uniform sampler2D noise_foam;
uniform float depth = -10.0;
uniform float shape_power = 10.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// SPHEREMASK
	vec2 uv = UV;
	vec2 half = vec2(0.5,0.5);
	float dist = distance(uv,half);
	dist = smoothstep(dist,1.0,0.5);
	dist = pow(dist,shape_power);
	
	float sphere_mask = dist;
	// SPHEREMASK
	VERTEX.y = sphere_mask * depth;
}

void fragment() {
	vec3 white = vec3(1.0,1.0,1.0);
	
	// SPHEREMASK
	vec2 uv = UV;
	vec2 half = vec2(0.5,0.5);
	float dist = distance(uv,half);
	dist = smoothstep(dist,1.0,0.5);
	
	float sphere_mask = dist;
	// SPHEREMASK
	
	// SPHEREMASK2
	float dist2 = distance(UV,half);
	dist2 = smoothstep(dist2,0.0,0.1);
	
	// SPHEREMASK2
	// NOISE
	vec2 center = vec2(0.5,0.5);
	vec2 dir = center - UV;
	vec2 flow = dir * 0.1;
	vec2 noise_uv = UV + flow + (TIME * 0.05);
	
	vec4 noise_tex = texture(noise,noise_uv);
	
	vec4 noise_foam_tex = texture(
		noise_foam,
		UV + flow + noise_tex.r * 0.1
	);
	noise_foam_tex *= noise_foam_tex;
	// NOISE
	// SPIRAL
	float rotate_speed = 1.5;
	float scale = 200.0;

	vec2 noise_offset = (noise_tex.xz - 0.5) * 0.05;
	vec2 p = ((UV - vec2(0.5)) - noise_offset) * scale;

	float r = length(p);
	float a = atan(p.y, p.x) + TIME * rotate_speed;

	float spiral = r * 0.2 + a * 2.0 ;
	// SPIRAL

	float pattern = sin(spiral) * 1.0 + 0.5;
	float band = 1.0 - abs(pattern - 0.5) * 2.0;
	band = clamp(band, 0.0, 1.0);
	float spiral_mask = smoothstep(0.0, 1.0, band);
	
	float spiral_strength = pow(spiral_mask, 0.7);
	vec3 phase1 = mix(color1, color2, spiral_strength);

	vec3 phase2 = mix(color3, phase1, dist2);
	vec3 foam = (noise_foam_tex.rgb * noise_foam_tex.rgb * noise_foam_tex.rgb) * dist2;
	ALBEDO = phase2 + (foam * color2);
	ALPHA = clamp(sphere_mask * 5.0,0.0,1.0);
	//ALPHA = sphere_mask * dist2 * spiral_mask;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
