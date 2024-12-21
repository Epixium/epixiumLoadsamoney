shader_type canvas_item;

uniform vec4 base_colors[12] : source_color;
uniform vec4 alt_colors[12] : source_color;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

const float precision = 0.05;

vec4 swap_color(vec4 color) {
	for (int i = 0; i < base_colors.length(); i ++) {
		if (distance(color, base_colors[i]) <= precision){
			return alt_colors[i];
		}
	}
	return color;
}
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR = swap_color(texture(screen_texture, SCREEN_UV));
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
