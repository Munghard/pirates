shader_type spatial;

uniform sampler2D normal_map :hint_normal;
uniform vec3 albedo : source_color = vec3(0.1, 0.3, 0.5);
uniform vec3 crest_color : source_color = vec3(0.4, 0.7, 1.0);
uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0);

uniform float normal_map_scale : hint_range(0.001, 100.0) = 1.0;
uniform float normal_map_strength : hint_range(0.001, 1.0) = 0.5;
uniform float scale : hint_range(0.001, 1.0) = 0.1;
uniform float crest_threshold_min:hint_range(0.0, 1.0) = 0.6;
uniform float crest_threshold_max:hint_range(0.0, 1.0) = 0.9;
uniform float foam_threshold_min:hint_range(0.0, 1.0) = 0.3;
uniform float foam_threshold_max:hint_range(0.0, 1.0) = 0.7;

// from script
uniform float time;
uniform float freq;
uniform float amp;
uniform float wave_height_scale;
uniform vec2 wind_dir;

varying float v_height;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_pos -= NODE_POSITION_WORLD; // important
	
	vec2 wind = normalize(vec2(wind_dir.x,wind_dir.y));
	float p = dot(world_pos.xz, wind);

	float t = time;


	float w1 = sin(p * 0.2 * freq + t) * 0.5;
	float w2 = sin((world_pos.x + world_pos.z) * 0.15 * freq + t * 2.0) * 0.3;
	float w3 = sin(world_pos.x * 0.35 * freq + t * 1.2) * 0.2;

	float wave = w1 + w2 + w3;

	wave = sign(wave) * pow(abs(wave), 1.3);

	wave *= amp * wave_height_scale;

	VERTEX.y += wave;
	v_height = wave;
	

	// derivatives

	float dw1 = cos(p * 0.2 * freq + t) * 0.2 * freq * 0.5;
	vec2 d1 = wind * dw1;

	float dw2 = cos((world_pos.x + world_pos.z) * 0.15 * freq + t * 2.0) * 0.15 * freq * 0.3;
	vec2 d2 = vec2(dw2, dw2);

	float dw3 = cos(world_pos.x * 0.35 * freq + t * 1.2) * 0.35 * freq * 0.2;
	vec2 d3 = vec2(dw3, 0.0);

	vec2 slope = d1 + d2 + d3;

	vec3 normal = normalize(vec3(-slope.x, 1.0, -slope.y));
	vec2 uv = world_pos.xz / normal_map_scale;
	uv += wind_dir * time * -0.1;
	vec4 normal_tex = texture(normal_map,uv);
	vec3 n_tex = normal_tex.rgb * 2.0 - 1.0;
	
	NORMAL = normalize(normal + n_tex * normal_map_strength);
}


void fragment() {
	float h = v_height / (amp * wave_height_scale);
	h = h * 0.5 + 0.5;
    // Crests are the tops of waves, Foam is the absolute peak
    float crest_mask = smoothstep(crest_threshold_min, crest_threshold_max, h); 
    float foam_mask = smoothstep(foam_threshold_min, foam_threshold_max, h); 
    
    vec3 color = mix(albedo, crest_color, crest_mask);
    color = mix(color, foam_color, foam_mask);
    
    ALBEDO = color;
    METALLIC = 0.0;
    ROUGHNESS = 0.05; // Low roughness = shiny water
    SPECULAR = 0.8;
    
    // Fake some depth by making the peaks slightly more opaque
    //ALPHA = 0.9; 
}