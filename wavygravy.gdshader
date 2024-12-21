shader_type canvas_item;

uniform vec2 direction = vec2(0.1, 0.1);
uniform float wobble_speed = 1.0;
uniform vec2 wavelength = vec2(64.0, 64.0);
uniform vec2 amplitude = vec2(4.0, 4.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV - sin(direction * TIME);
	vec4 base_color = texture(TEXTURE, uv);
	vec4 moved_color = texture(TEXTURE, uv - vec2(TEXTURE_PIXEL_SIZE.x * amplitude.x * cos(FRAGCOORD.x/wavelength.x)*cos(TIME*wobble_speed), TEXTURE_PIXEL_SIZE.y * amplitude.y * sin(FRAGCOORD.y/wavelength.y)*sin(TIME*wobble_speed)));
	COLOR = mix(base_color, moved_color, 0.2);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
