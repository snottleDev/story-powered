shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
uniform float offset_amount : hint_range(-1.0, 1.0) = 0.0;
uniform float distortion_amount : hint_range(0.0, 1.0) = 0.0;

vec4 blur_sample(sampler2D tex, vec2 uv, float amount) {
	// Weighted 9-sample blur — pixel stride scales with amount
	vec2 ps = TEXTURE_PIXEL_SIZE * amount * 18.0;
	vec4 color = texture(tex, uv) * 4.0;
	color += texture(tex, uv + vec2(ps.x, 0.0)) * 2.0;
	color += texture(tex, uv - vec2(ps.x, 0.0)) * 2.0;
	color += texture(tex, uv + vec2(0.0, ps.y)) * 2.0;
	color += texture(tex, uv - vec2(0.0, ps.y)) * 2.0;
	color += texture(tex, uv + ps);
	color += texture(tex, uv - ps);
	color += texture(tex, uv + vec2(ps.x, -ps.y));
	color += texture(tex, uv + vec2(-ps.x, ps.y));
	return color / 16.0;
}

void fragment() {
	vec2 uv = UV;

	// Distortion — spatial wave
	if (abs(distortion_amount) > 0.001) {
		float wave_x = sin(uv.y * 25.0) * distortion_amount * 0.04;
		float wave_y = cos(uv.x * 20.0) * distortion_amount * 0.03;
		uv += vec2(wave_x, wave_y);
	}

	// Double vision — two offset copies blended
	if (abs(offset_amount) > 0.001) {
		vec2 shift = vec2(offset_amount * 0.06, offset_amount * 0.02);
		vec4 c1 = blur_sample(TEXTURE, uv + shift, blur_amount);
		vec4 c2 = blur_sample(TEXTURE, uv - shift, blur_amount);
		COLOR = mix(c1, c2, 0.5);
	} else {
		COLOR = blur_sample(TEXTURE, uv, blur_amount);
	}
}
