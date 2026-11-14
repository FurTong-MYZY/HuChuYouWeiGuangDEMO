shader_type canvas_item;
render_mode blend_mix;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float d = length((uv * 2.0 - 1.0) * vec2(1.12, 1.0));
	float vig = smoothstep(0.42, 1.12, d) * 0.55;

	// 红色警报脉冲
	float pulse = 0.5 + 0.5 * sin(TIME * 2.0 + sin(TIME * 0.7) * 1.4);

	// 浮尘/余烬
	vec2 p = uv * vec2(150.0, 85.0) + vec2(TIME * 4.0, -TIME * 7.0);
	float dust = step(0.9975, hash(floor(p)));
	float ash = step(0.9988, hash(floor(p * 0.55 + 17.0)));

	float a = vig * 0.92 + pulse * 0.032 + dust * 0.06 + ash * 0.035;
	vec3 col = mix(vec3(0.12, 0.005, 0.002), vec3(0.95, 0.07, 0.02), pulse * 0.55);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
