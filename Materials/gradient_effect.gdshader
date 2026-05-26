shader_type spatial;

render_mode unshaded,cull_disabled;
uniform vec4 color:source_color;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = color.rgb;
	float blink = (sin(TIME * 10.0) + 1.0) * 0.5;
	ALPHA = mix(0.0,1.0 * color.a * blink,UV.y);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
