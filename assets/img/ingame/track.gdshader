shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always;
// Tiled moving track shader
// by Kiri for KiriRhythmGame 

uniform sampler2D track_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float uv_scale_y = 15.0;
uniform float track_scroll_offset = 0.0;
uniform float t_alpha : hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	
	vec2 scrolled_uv = UV;
	scrolled_uv.y = (scrolled_uv.y * uv_scale_y) + track_scroll_offset;
	
	vec4 col = texture(track_texture, scrolled_uv);
	ALBEDO = col.rgb;
	ALPHA = col.a * t_alpha;
}
