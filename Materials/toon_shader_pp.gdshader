shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform sampler2D screen_tex : hint_screen_texture;

uniform float edge_threshold = 0.2;

void fragment() {
    vec2 uv = SCREEN_UV;

    vec3 col = texture(screen_tex, uv).rgb;

    // simple luminance
    float lum = dot(col, vec3(0.299, 0.587, 0.114));

    // posterize (cel shading effect)
    float levels = 20.0;
    lum = floor(lum * levels) / levels;

    vec3 toon = vec3(lum);

    ALBEDO = toon;
	
}