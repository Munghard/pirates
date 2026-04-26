shader_type spatial;

uniform sampler2D noise;
uniform vec3 color:source_color = vec3(1.0,1.0,1.0);
uniform float scale:hint_range(0.0, 100.0, 0.01);
uniform float wind_speed_multiplier:hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float cloud_opacity:hint_range(0.0, 1.0, 0.01) = 0.1;

//from script
uniform vec2 offset;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wind_offset = offset * wind_speed_multiplier;

	vec2 uv = world_pos.xz * 0.001;

	float d = texture(noise, uv * 0.1 + wind_offset).r;
	vec2 warped_uv = uv + (d - 0.5) * 3.0;

	float noise_tex = texture(noise, warped_uv * scale + wind_offset).r;

	float cloud = smoothstep(0.5, 0.8, noise_tex);
	cloud = pow(cloud, 1.5);

	float light = dot(normalize(vec3(1.0,1.0,0.5)), NORMAL);
	light = clamp(light, 0.3, 1.0);

	ALBEDO = color * light;
	ALPHA = cloud * cloud_opacity;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
