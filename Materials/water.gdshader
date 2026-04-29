shader_type spatial;
render_mode depth_draw_always;

uniform sampler2D normal_map :hint_normal;

uniform sampler2D noise_tex; // foam
uniform sampler2D heightmap: filter_linear, repeat_disable;
uniform vec3 beach_color : source_color = vec3(0.8, 0.5, 0.6);
uniform vec3 albedo : source_color = vec3(0.1, 0.3, 0.5);
uniform vec3 crest_color : source_color = vec3(0.4, 0.7, 1.0);
uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0);

uniform float normal_map_scale : hint_range(0.001, 100.0) = 1.0;
uniform float normal_map_strength : hint_range(0.001, 1.0) = 0.5;
uniform float crest_threshold_min:hint_range(0.0, 1.0) = 0.6;
uniform float crest_threshold_max:hint_range(0.0, 1.0) = 0.9;
uniform float foam_threshold_min:hint_range(0.0, 1.0) = 0.3;
uniform float foam_threshold_max:hint_range(0.0, 1.0) = 0.7;

uniform float max_depth = -10.0;
uniform float terrain_height;
// from script
uniform float water_level_world = 0.0;
uniform vec2 heightmap_size;
uniform vec2 terrain_world_size;
uniform vec2 terrain_cell_size;
uniform vec3 terrain_origin;
uniform float time;
uniform float freq;
uniform float amp;
uniform float wave_height_scale;
uniform vec2 wind_dir;

varying float v_height;
varying vec3 world_pos;
varying float v_amp;
varying float terrain_h;
varying float depth;
varying float v_depth; // Add this!

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
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
	
	vec2 local_pos = world_pos.xz - terrain_origin.xz;
	vec2 hm_uv = local_pos / terrain_world_size;
	float h01 = texture(heightmap, hm_uv).r;
	terrain_h = (h01 - 0.5) * terrain_height;
	depth = max(0.0, water_level_world - terrain_h);
	
	float depth01 = clamp(depth / abs(max_depth), 0.0, 1.0);
	v_depth = depth01;
	
	wave = sign(wave) * pow(abs(wave), 1.3);
	float final_amp = amp * depth01 * wave_height_scale;
	wave *= final_amp;

	v_amp = final_amp * wave_height_scale;;

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

	float slope_factor = mix(0.3, 1.0, depth01);
	vec3 normal = normalize(vec3(-slope.x * slope_factor, 1.0, -slope.y * slope_factor));

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
    float crest_mask = smoothstep(crest_threshold_min, crest_threshold_max, h) * v_depth; 
    float foam_mask = smoothstep(foam_threshold_min, foam_threshold_max, h) * v_depth;
    
    vec3 color = mix(albedo, crest_color, crest_mask);

	vec2 uv = vec2(world_pos.x, world_pos.z) * 0.1;
	vec2 wind_dir_normalized = normalize(wind_dir);
	float n = texture(noise_tex, uv + wind_dir_normalized * TIME * 0.1).r;
	float n2 = texture(noise_tex, uv * 0.2 + wind_dir_normalized * TIME * 0.01).r;
	float n3 = texture(noise_tex, uv * 0.1 + wind_dir_normalized * TIME * -0.01).r;
	n3 *= n3 * n3;
	
	n3 = clamp(n3,0.0,1.0);
	
	color = mix(color,crest_color,n3);

	float foam = smoothstep(0.5, 1.0, n);
	float foam_big = smoothstep(0.4, 1.0, n2);
	foam *= foam_mask;
	foam_big *= 0.5;
	
	float foam_big_mixed = mix( 0,foam_big,amp / 5.0);
	
	///////////////////////////// shoreline
	
	
	vec2 local_pos = world_pos.xz - terrain_origin.xz;
	// Use the varying world_pos to get the static world UV
	vec2 hm_uv = local_pos / terrain_world_size;

	// scale into texel grid
	vec2 fragment_hm_uv = (local_pos + terrain_cell_size * 0.5 ) / terrain_world_size;
	fragment_hm_uv *= (heightmap_size - vec2(1.0)) / heightmap_size;
	
	// Sample the height directly in the fragment shader for pixel-perfect locking
	// This prevents the "swimming" effect when the camera moves
	float h01 = texture(heightmap, fragment_hm_uv).r;
	float terrain_h_at_frag = (h01 - 0.5) * terrain_height;
	float frag_depth = max(0.0, water_level_world - terrain_h_at_frag);
	float frag_v_depth = clamp(frag_depth / abs(max_depth), 0.0, 1.0);

	float wave_freq = 40.0; 
	float wave_speed = -2.0;
	
	// Use the NEW frag_v_depth instead of the varying v_depth
	float wave_anim = sin(frag_v_depth * wave_freq - TIME * wave_speed);
	wave_anim = wave_anim * 0.5 + 0.5; 
	
	float radiating_wave = smoothstep(0.6, 0.8, wave_anim);
	
	// Mask it using the new static depth
	float shore_mask = smoothstep(0.2, 0.0, frag_v_depth);
	float beach_waves = radiating_wave * shore_mask;
	
	///////////////////////////// shoreline
	
	float foam_total = clamp(foam + foam_big_mixed + beach_waves, 0.0, 1.0);
	
	vec3 final_color = mix(color, foam_color, foam_total);
	float beach_color_mask = 1.0 - shore_mask;
	final_color = mix(beach_color,final_color,beach_color_mask);
    ALBEDO = final_color;
    //ALBEDO = vec3(1.0,1.0,1.0) * beach_waves;
	
	
    METALLIC = 0.0;
    ROUGHNESS = mix(0.05,1.0, foam_total); // Low roughness = shiny water
    SPECULAR = mix(0.8,0.0,foam_total);
    
    // Fake some depth by making the peaks slightly more opaque
    //ALPHA = 1.0 - shore_mask; 
}