shader_type canvas_item;

uniform vec4 outline_color;
uniform vec4 fill_color;
const vec4 base_outline = vec4(1, 0, 0, 1);
const vec4 base_fill = vec4(1, 1, 1, 1);

void fragment() {
	if (COLOR.rgb == base_outline.rgb) {
		COLOR.rgb = outline_color.rgb;
	}
	if (COLOR.rgb == base_fill.rgb) {
		COLOR.rgb = fill_color.rgb;
	}
	COLOR.a = texture(TEXTURE,UV).a;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
