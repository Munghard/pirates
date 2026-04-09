shader_type spatial;

uniform vec3 albedo : source_color = vec3(0.1, 0.3, 0.5);
uniform vec3 crest_color : source_color = vec3(0.4, 0.7, 1.0);
uniform vec3 foam_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 wind_direction; // Changed to vec3 to match script
uniform sampler2D wave_noise : repeat_enable; // IMPORTANT: Noise must repeat
uniform float scale : hint_range(0.001, 1.0) = 0.1;
uniform float wave_height : hint_range(0.0, 5.0) = 1.0;

varying float v_height;

void vertex() {
    // 1. Get World Space UVs so waves don't "slide" when the mesh moves
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // 2. Directional Movement
    // We use wind_direction.xz because Y is UP in 3D space
    vec2 motion = wind_direction.xz / 100.0 * TIME;
    vec2 uv = (world_pos.xz * scale) + motion;
    
    float n = texture(wave_noise, uv).r;
    v_height = n;
    
    VERTEX.y += n * wave_height;
    
    // 3. Normal Fix: Since we change height, we should technically recalculate normals.
    // A quick hack for water is to slightly tilt the normal based on the noise.
    NORMAL = normalize(vec3(0.0, 1.0, 0.0)) * n; 
}

void fragment() {
    // Crests are the tops of waves, Foam is the absolute peak
    float crest_mask = smoothstep(0.4, 1.0, v_height); 
    float foam_mask = smoothstep(0.70, 1.0, v_height); 
    
    vec3 color = mix(albedo, crest_color, crest_mask);
    color = mix(color, foam_color, foam_mask);
    
    ALBEDO = color;
    METALLIC = 0.0;
    ROUGHNESS = 0.05; // Low roughness = shiny water
    SPECULAR = 0.8;
    
    // Fake some depth by making the peaks slightly more opaque
    //ALPHA = 0.9; 
}