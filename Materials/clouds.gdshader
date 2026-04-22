shader_type spatial;

uniform sampler2D noise;
uniform vec3 color:source_color = vec3(1.0,1.0,1.0);
uniform float scale:hint_range(0.0, 1.0, 0.01);
uniform float wind_speed_multiplier:hint_range(0.0, 1.0, 0.01) = 1.0;

//from script
uniform vec2 offset;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv =  vec2(world_pos.x,world_pos.z);
	
	float d = texture(noise, uv * 0.1 + offset).r; // distortion field
	vec2 warped_uv = uv + (d - 0.5) * 2.0;
	
	float noise_tex = texture(noise,offset + (warped_uv * scale)).r;
	
	float cloud = smoothstep(0.7,0.8,noise_tex);
	cloud = clamp(cloud,0.0,1.0);
	
	float cloud_opacity = 0.1;
	ALBEDO = color;
	ALPHA = cloud * cloud_opacity;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
