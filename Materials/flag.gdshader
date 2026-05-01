shader_type spatial;
render_mode cull_disabled,unshaded;

uniform sampler2D flag_texture;

void vertex() {
	float wave =  sin(UV.x * 5.0 + TIME * 5.0) * 0.1;
	VERTEX.z += UV.x * wave;
	VERTEX.y += UV.x * wave * 0.2;
}

void fragment() {
	vec4 flag_tex = texture(flag_texture,UV);
	ALBEDO = flag_tex.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
