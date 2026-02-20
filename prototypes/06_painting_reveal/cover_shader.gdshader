shader_type canvas_item;

uniform sampler2D mask_texture : hint_default_white;

void fragment() {
	// Mask: white (1.0) = cover visible, black (0.0) = cover erased
	float mask_val = texture(mask_texture, UV).r;
	COLOR.a *= mask_val;
}
