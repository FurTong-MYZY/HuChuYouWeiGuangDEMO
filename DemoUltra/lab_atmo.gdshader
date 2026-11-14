shader_type canvas_item;
render_mode blend_mix;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float d = length((uv * 2.0 - 1.0) * vec2(1.1, 1.0));
	float vig = smoothstep(0.4, 1.12, d) * 0.58;

	// 收容所冷色暗角 + 灯管轻微闪烁
	float flicker = 0.82 + 0.18 * smoothstep(0.4, 0.9, hash(vec2(floor(TIME * 7.0), 3.0)));
	float scan = 0.5 + 0.5 * sin(uv.y * 980.0);
	vec2 fog_p = uv * vec2(8.0, 4.0) + vec2(TIME * 0.025, -TIME * 0.018);
	float fog = smoothstep(0.2, 0.85, hash(floor(fog_p))) * 0.035;

	float a = vig * 0.94 + scan * 0.012 + fog + (1.0 - flicker) * 0.06;
	vec3 col = mix(vec3(0.005, 0.055, 0.05), vec3(0.03, 0.22, 0.17), flicker);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
