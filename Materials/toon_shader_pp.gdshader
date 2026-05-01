shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;

uniform float cell_strength = 1.0;
uniform float edge_threshold = 0.2;
uniform float edge_strength = 1.0;

void fragment() {
    vec2 uv = SCREEN_UV;
 	vec2 texel = 1.0 / vec2(textureSize(screen_tex, 0));

    vec3 col = texture(screen_tex, uv).rgb;

    // simple luminance
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
	// --- edge detection (Sobel-ish) ---
    float lumL = dot(texture(screen_tex, uv + vec2(-texel.x, 0.0)).rgb, vec3(0.299,0.587,0.114));
    float lumR = dot(texture(screen_tex, uv + vec2(texel.x, 0.0)).rgb, vec3(0.299,0.587,0.114));
    float lumU = dot(texture(screen_tex, uv + vec2(0.0, -texel.y)).rgb, vec3(0.299,0.587,0.114));
    float lumD = dot(texture(screen_tex, uv + vec2(0.0, texel.y)).rgb, vec3(0.299,0.587,0.114));

    float edge = abs(lumL - lumR) + abs(lumU - lumD);

    float edge_mask = step(edge_threshold, edge);
    // posterize (cel shading effect)
    float levels = 10.0;
    lum = floor(lum * levels) / levels;
	float cell = mix(1.0,lum,cell_strength);
    vec3 toon = cell * col;
	vec3 final = mix(toon,vec3(0.0),edge_mask * edge_strength);

    COLOR = vec4(final, 1.0);;
	
}