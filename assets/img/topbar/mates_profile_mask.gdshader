shader_type canvas_item;

uniform float radius = 0.5; // 0.5 = full circle, lower = rounded rect corners
uniform vec2 size = vec2(1.0, 1.0); // fed from script

void fragment() {
    vec2 px = UV * size;
    vec2 center = size * 0.5;
    float dist = length(px - center);
    float mask = 1.0 - smoothstep(size.x * radius - 1.0, size.x * radius, dist);
    COLOR = texture(TEXTURE, UV);
    COLOR.a *= mask;
}