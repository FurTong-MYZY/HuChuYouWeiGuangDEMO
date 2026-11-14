shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.55;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = p * 2.03 + 7.1;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float ang = atan(uv.y, uv.x);
	float n = fbm(vec2(ang * 2.4 + seed * 3.0, r * 5.0 - progress * 7.5));

	float grow = min(1.0, progress * 2.5);
	float outer = 0.24 + 0.82 * grow;
	float body = smoothstep(outer + 0.03, outer - 0.34, r + (n - 0.5) * 0.26);
	float fade = 1.0 - progress;

	vec3 col = mix(vec3(1.0, 0.10, 0.005), vec3(1.0, 0.55, 0.06), smoothstep(1.0, 0.25, r));
	col = mix(col, vec3(1.0, 0.92, 0.46), smoothstep(0.58, 0.10, r));
	col = mix(col, vec3(1.0), smoothstep(0.26, 0.0, r));

	float ring_r = 0.17 + progress * 1.05;
	float ring = exp(-pow((r - ring_r) * 25.0, 2.0)) * 0.75 * fade;
	ring += exp(-pow((r - ring_r * 0.72) * 34.0, 2.0)) * 0.35 * fade;

	float alpha = clamp(body * fade + ring, 0.0, 1.0);
	COLOR = vec4(col * alpha, alpha);
}
