shader_type canvas_item;
render_mode blend_mix;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	float d = length((uv * 2.0 - 1.0) * vec2(1.12, 1.0));
	float vig = smoothstep(0.48, 1.15, d) * 0.55;

	// 高处强风：斜向雨丝
	vec2 p = vec2(uv.x * 120.0 + uv.y * 10.0 + t * 5.0, uv.y * 26.0 - t * 58.0);
	float n = hash(floor(p));
	float streak = smoothstep(0.986, 1.0, n);
	float fade = smoothstep(0.0, 0.14, uv.y) * (1.0 - smoothstep(0.84, 1.0, uv.y));
	float rain = streak * fade * 0.14;

	// 云雾感
	float fog = smoothstep(0.55, 1.0, d) * 0.03 + smoothstep(0.72, 1.0, uv.y) * 0.04;

	float a = clamp(vig * 0.9 + rain + fog, 0.0, 1.0);
	vec3 col = mix(vec3(0.004, 0.006, 0.02), vec3(0.6, 0.78, 1.0), rain);
	COLOR = vec4(col, a);
}
