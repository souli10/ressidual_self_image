shader_type canvas_item;

// CRT Shader — scanlines, green tint, vignette, subtle noise
// Apply to a ColorRect that covers the full viewport

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_frequency : hint_range(100.0, 800.0) = 360.0;
uniform float green_tint_strength : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float noise_strength : hint_range(0.0, 0.1) = 0.02;
uniform float curvature : hint_range(0.0, 0.1) = 0.02;
uniform float chromatic_aberration : hint_range(0.0, 5.0) = 1.0;

// Simple hash for noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 curve_uv(vec2 uv) {
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + curvature * dot(centered, centered);
	return centered * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(UV);

	// Out of bounds after curvature
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	// Chromatic aberration
	float ca_offset = chromatic_aberration / 1280.0;
	float r = texture(TEXTURE, uv + vec2(ca_offset, 0.0)).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - vec2(ca_offset, 0.0)).b;
	vec3 color = vec3(r, g, b);

	// Green tint
	color.r *= (1.0 - green_tint_strength * 0.7);
	color.g *= (1.0 + green_tint_strength * 0.15);
	color.b *= (1.0 - green_tint_strength * 0.5);

	// Scanlines
	float scanline = sin(uv.y * scanline_frequency * 3.14159) * 0.5 + 0.5;
	color *= 1.0 - scanline_strength * (1.0 - scanline);

	// Vignette
	vec2 vignette_uv = uv * (1.0 - uv);
	float vignette = vignette_uv.x * vignette_uv.y * 15.0;
	vignette = clamp(pow(vignette, vignette_strength), 0.0, 1.0);
	color *= vignette;

	// Noise
	float noise = hash(uv * 1000.0 + TIME * 5.0) * noise_strength;
	color += vec3(noise * 0.3, noise, noise * 0.3);

	COLOR = vec4(color, 1.0);
}
