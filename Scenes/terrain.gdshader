shader_type spatial;

uniform vec3 beach_color:source_color ;
uniform vec3 grass_color:source_color ;
uniform vec3 dirt_color:source_color ;
uniform vec3 slope_color:source_color ;

uniform vec2 rock = vec2(0.0, 0.4);
uniform vec2 dirt = vec2(0.4, 1.0);

uniform float beach_height ;
uniform float land_height ;

varying vec3 world_pos;
varying vec3 normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	
	float height = world_pos.y;
	
	float slope = 1.0 - normal.y;
	
	float beach_factor = smoothstep(beach_height, land_height, height);
	float rock_factor = smoothstep(rock.x,rock.y, slope);
	float dirt_factor = smoothstep(dirt.x,dirt.y, slope);
	
	vec3 highland = mix(grass_color,dirt_color,dirt_factor);
	
	vec3 land_with_slope = mix(highland, slope_color, rock_factor);
	vec3 beach_land = mix(beach_color,land_with_slope,beach_factor);
	vec3 final_color = mix(beach_color, land_with_slope, beach_factor);
	
	ALBEDO = final_color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
