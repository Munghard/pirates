shader_type canvas_item;


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float focus_center = 0.5;
uniform float focus_width = 0.2;
uniform float blur_strength = 16.0;

void fragment() {
    vec2 uv = SCREEN_UV;

    float d = abs(uv.y - focus_center);
    float blur_amount = smoothstep(focus_width, focus_width + 0.2, d) * blur_strength;

    vec3 col = texture(SCREEN_TEXTURE, uv).rgb;

    vec3 blur = vec3(0.0);
    int samples = 6;

    for (int i = 0; i < samples; i++) {
        float offset = float(i) / float(samples) * blur_amount * 0.002;
        blur += texture(SCREEN_TEXTURE, uv + vec2(0.0, offset)).rgb;
        blur += texture(SCREEN_TEXTURE, uv - vec2(0.0, offset)).rgb;
    }

    blur /= float(samples * 2);

    float t = clamp(blur_amount, 0.0, 1.0);
    vec3 final = mix(col, blur, t);

     COLOR = vec4(final, 1.0);

}