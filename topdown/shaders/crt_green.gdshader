shader_type canvas_item;

// Phase 4 placeholder — CRT green-tint + scanline shader
// Will be applied as a full-screen ColorRect material later

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float green_tint : hint_range(0.0, 1.0) = 0.3;
uniform float vignette : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Green channel boost
	col.r *= (1.0 - green_tint * 0.5);
	col.b *= (1.0 - green_tint * 0.7);

	// Scanlines
	float line = mod(FRAGCOORD.y, 4.0);
	if (line < 1.0) {
		col.rgb *= (1.0 - scanline_strength);
	}

	// Vignette
	vec2 center = UV - 0.5;
	float dist = length(center);
	col.rgb *= 1.0 - dist * vignette;

	COLOR = col;
}
