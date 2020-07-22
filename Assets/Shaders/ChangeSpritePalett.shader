shader_type canvas_item;

uniform sampler2D palette;

void fragment() {
    // Get the sprite texture
	vec4 rgba_channels = texture(TEXTURE, UV);
	
	vec4 final_color = texture(palette, vec2(rgba_channels.r, 0.0));
	final_color.a =  rgba_channels.a;
	
	COLOR = final_color;
}