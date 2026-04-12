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
	//world_pos -= NODE_POSITION_WORLD;

	vec2 wind = normalize(vec2(wind_dir.x, wind_dir.y));

	vec2 perp = vec2(-wind.y, wind.x);

	vec2 pos_xz = world_pos.xz;

	float along = dot(pos_xz, wind);
	float across = dot(pos_xz, perp);

	float t = time;
	float f = freq;

	// --- waves (ALL wind-aligned now) ---
	float w1 = sin(along * f * 0.2 + t) * 0.5;
	float w2 = sin(across * f * 0.1 + t * 2.0) * 0.3;
	float w3 = sin((along * 0.35 + across * 0.1) * f + t * 1.2) * 0.2;

	float wave = w1 + w2 + w3;
	wave = sign(wave) * pow(abs(wave), 1.3);
	wave *= amp * wave_height_scale;

	VERTEX.y += wave;
	v_height = wave;

	// --- derivatives (MATCHING wave math) ---

	float dw1 = cos(along * f * 0.2 + t) * (f * 0.2);
	vec2 d1 = wind * (dw1 * 0.5);

	float dw2 = cos(across * f * 0.1 + t * 2.0) * (f * 0.1);
	vec2 d2 = perp * (dw2 * 0.3);

	float phase3 = (along * 0.35 + across * 0.1) * f + t * 1.2;
	float dw3 = cos(phase3);

	vec2 d3 = wind * (dw3 * 0.35 * f) + perp * (dw3 * 0.1 * f);

	vec2 slope = d1 + d2 + d3;

	vec3 normal = normalize(vec3(-slope.x, 1.0, -slope.y));

	// --- normal map (fix wind space) ---
	vec2 uv = world_pos.xz / normal_map_scale;
	uv += wind * time * -0.1;

	vec3 n_tex = texture(normal_map, uv).rgb * 2.0 - 1.0;

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