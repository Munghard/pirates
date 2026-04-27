shader_type spatial;

uniform sampler2D noise;
uniform vec3 color:source_color = vec3(1.0,1.0,1.0);
uniform float scale:hint_range(0.0, 1.0, 0.01);
uniform float wind_speed_multiplier:hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float cloud_opacity:hint_range(0.0, 1.0, 0.01) = 0.1;
//from script
uniform vec2 offset;
uniform vec2 wind_dir;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wind_offset = offset * wind_speed_multiplier;
	vec2 pos = vec2(world_pos.x, world_pos.z);
	
	vec2 wind = normalize(wind_dir);
	vec2 perp = vec2(-wind.y, wind.x);

	float along = dot(pos, wind);
	float across = dot(pos, perp);
	
	vec2 uv = vec2(along, across);
	
	uv *= vec2(0.1,0.5) * wind_dir;
	
	//vec2 uv =  vec2(world_pos.x,world_pos.z);
	float d = texture(noise, uv * 0.05 + wind_offset).r;

	vec2 warp = vec2(d - 0.5) * 2.0;

	vec2 warped_uv = uv + warp * 2.0;
	vec2 skew = vec2(0.1,1.0);
	
	float noise_tex = texture(noise, warped_uv * scale + wind_offset).r;
	
	float cloud = smoothstep(0.7,0.8,noise_tex);
	cloud = clamp(cloud,0.0,1.0);
	
	
	ALBEDO = color;
	ALPHA = cloud * cloud_opacity;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
