shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always;
// Horizontal Repeat Shader (for judge line segment)
// by Kiri for KiriRhythmGame 

uniform sampler2D segment_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float segment_width_units = 0.0625;
uniform float segment_alpha_multiplier : hint_range(0.0, 1.0, 0.1) = 0.5;

varying vec2 seg_uv;

void vertex() {
	seg_uv = vec2(VERTEX.x / segment_width_units, UV.y);
}

void fragment() {
	vec4 col = texture(segment_texture, seg_uv);
	ALBEDO = col.rgb;
	ALPHA = col.a * segment_alpha_multiplier;
}
