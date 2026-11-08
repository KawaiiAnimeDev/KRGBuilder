shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

// ---------------- Effect 1: Chromatic Tunnel ----------------
uniform bool chromatic_enabled = true;
uniform float chromatic_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float pinch_amount : hint_range(0.0, 2.0) = 0.4;
uniform vec2 pinch_center = vec2(0.5, 0.25);

const int CHROMA_SAMPLES = 9;

// ---------------- Effect 2: Sepia Burn Tremble ----------------
uniform bool burn_enabled = false;
uniform float burn_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float burn_speed = 30.0;
uniform vec3 sepia_tint = vec3(0.55, 0.35, 0.18); // brown target color

// ---------------- Effect 3: Glitch ----------------
uniform bool glitch_enabled = false;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float glitch_speed = 5.0;
const int GLITCH_LINES = 5; // fixed count, unrolled

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

vec2 hash21(float p) {
    return vec2(hash11(p), hash11(p + 17.17));
}

vec3 apply_chromatic_tunnel(vec2 uv, vec2 screen_pixel_size) {
    vec2 delta = uv - pinch_center;
    delta.x *= screen_pixel_size.y / screen_pixel_size.x;

    float dist = length(delta);
    vec2 dir = -normalize(delta + 1e-5);

    float pinch = 1.0 - pinch_amount * 0.15 * dist * dist;
    vec2 puv = pinch_center + (uv - pinch_center) * pinch;

    vec3 accum = vec3(0.0);
    for (int i = 0; i < CHROMA_SAMPLES; i++) {
        float t = float(i) / float(CHROMA_SAMPLES - 1);
        vec2 o = dir * chromatic_intensity * 0.02 * t * (dist + 0.2);

        vec3 mask = vec3(0.0);
        if (i % 3 == 0) mask = vec3(1.0, 0.0, 0.0);
        else if (i % 3 == 1) mask = vec3(0.0, 1.0, 0.0);
        else mask = vec3(0.0, 0.0, 1.0);

        accum += texture(screen_texture, clamp(puv + o, vec2(0.0), vec2(1.0))).rgb * mask;
    }
    return accum / 3.0;
}

// Applies N independently-seeded random red/transparent horizontal segments.
// Each line has random y, random height, random x-range, random alpha,
// and re-rolls on a time step so it doesn't animate continuously or tile as a grid.
vec3 apply_glitch_segments(vec2 uv, vec3 base_color) {
    vec3 color = base_color;
    float step_id = floor(TIME * glitch_speed);

    for (int i = 0; i < GLITCH_LINES; i++) {
        float seed = step_id * 13.7 + float(i) * 91.3;

        float active = step(0.55, hash11(seed)); // only some lines active each step
        if (active < 0.5) continue;

        vec2 r1 = hash21(seed + 1.0);
        vec2 r2 = hash21(seed + 2.0);

        float line_y = r1.x;                         // random vertical position
        float line_h = 0.004 + r1.y * 0.02 * glitch_intensity; // random thin height

        float seg_start = r2.x * 0.7;                 // random horizontal start
        float seg_width = 0.05 + r2.y * 0.35;          // random segment width (not full screen)

        bool in_band = uv.y > line_y && uv.y < line_y + line_h;
        bool in_seg = uv.x > seg_start && uv.x < seg_start + seg_width;

        if (in_band && in_seg) {
            float alpha = (0.3 + hash11(seed + 3.0) * 0.7) * glitch_intensity;
            vec3 redInv = (vec3(1.0) - color) * vec3(1.0, 0.15, 0.15);
            color = mix(color, redInv, alpha);
        }
    }
    return color;
}

void fragment() {
    vec2 uv = SCREEN_UV;

    if (glitch_enabled) {
        float block = floor(uv.y * 24.0 + floor(TIME * glitch_speed));
        float trigger = step(0.85, hash11(block * 7.13));
        uv.x += (hash11(block) - 0.5) * glitch_intensity * 0.05 * trigger;
    }

    vec3 color = chromatic_enabled
        ? apply_chromatic_tunnel(uv, SCREEN_PIXEL_SIZE)
        : texture(screen_texture, uv).rgb;

    if (burn_enabled) {
    // sample offset for the tremble, but blend from `color` (already has CA applied)
    vec2 tuv = uv;
    tuv.x += sin(TIME * burn_speed) * burn_intensity * 0.03;

    vec3 trembled = chromatic_enabled
        ? apply_chromatic_tunnel(tuv, SCREEN_PIXEL_SIZE)
        : texture(screen_texture, clamp(tuv, vec2(0.0), vec2(1.0))).rgb;

    color = mix(color, trembled, burn_intensity * 0.5); // apply the tremble offset itself

    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    float inv_gray = 1.0 - gray;
    vec3 sepia = inv_gray * sepia_tint * 1.6;

    color = mix(color, sepia, burn_intensity);
}

    if (glitch_enabled) {
        color = apply_glitch_segments(uv, color);
    }

    COLOR = vec4(color, 1.0);
}