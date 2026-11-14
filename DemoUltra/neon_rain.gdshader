shader_type canvas_item;
render_mode blend_mix;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	vec2 p = vec2(uv.x * 92.0 + uv.y * 6.0 + t * 1.8, uv.y * 30.0 - t * 38.0);
	float n = hash(floor(p));
	float streak = smoothstep(0.984, 1.0, n);
	float fade = smoothstep(0.0, 0.12, uv.y) * (1.0 - smoothstep(0.84, 1.0, uv.y));
	float rain_a = streak * fade * 0.16;

	// 同一张全屏 pass 里合成暗角，省掉一层全屏绘制
	vec2 v = UV * 2.0 - 1.0;
	v.x *= 1.15;
	float vig = smoothstep(0.5, 1.15, length(v)) * 0.5;
	vec3 rain_col = vec3(0.55, 0.78, 1.0);
	vec3 col = mix(vec3(0.004, 0.006, 0.018), rain_col, rain_a);
	COLOR = vec4(col, max(rain_a, vig));
}
