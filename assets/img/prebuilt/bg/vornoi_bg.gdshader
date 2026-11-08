shader_type canvas_item;

uniform sampler2D noise_texture : source_color, filter_linear, repeat_enable;
uniform int color_choice : hint_range(0, 3, 1) = 0;

varying flat vec2 rot_a;

void vertex() {
    rot_a = sin(vec2(1.570796, 0.0) + TIME / 8.0);
}

float p5(float x)  { float x2 = x * x; return x2 * x2 * x; }
float p12(float x) { float x2 = x * x; float x4 = x2 * x2; return x4 * x4 * x4; }
float p24(float x) { float x2 = x * x; float x4 = x2 * x2; float x8 = x4 * x4; return x8 * x8 * x8; }
float p32(float x) { float x2 = x * x; float x4 = x2 * x2; float x8 = x4 * x4; float x16 = x8 * x8; return x16 * x16; }

vec3 tex3D_fast(sampler2D tex, vec3 p, vec3 n) {
    vec3 n_abs = max(abs(n) - 0.2, 0.001);
    n_abs /= (n_abs.x + n_abs.y + n_abs.z);
    vec3 s = texture(tex, p.xy).rgb * n_abs.z + texture(tex, p.zx).rgb * n_abs.y;
    return s * s;
}

vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(41.0, 289.0)));
    p = fract(vec2(262144.0, 32768.0) * n);
    return sin(p * 6.2831853 + TIME) * 0.45 + 0.5;
}

void height_5(vec2 q, out float hc, out float idf, out vec4 hn) {
    const float EPS = 0.02;
    vec2 g = floor(q);
    vec2 f = q - g;
    vec4 fx = f.x + vec4(EPS, -EPS, 0.0, 0.0);
    vec4 fy = f.y + vec4(0.0, 0.0, EPS, -EPS);

    float cx = 1.0, cy = 1.0;
    vec4 dx = vec4(1.0), dy = vec4(1.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(float(x), float(y));
            o += hash22(g + o);

            vec2 r = o - f;
            float dz = dot(r, r);
            cy = max(cx, min(cy, dz));
            cx = min(cx, dz);

            vec4 vx = o.x - fx;
            vec4 vy = o.y - fy;
            vec4 dzv = vx * vx + vy * vy;
            dy = max(dx, min(dy, dzv));
            dx = min(dx, dzv);
        }
    }

    const float K = 1.0 / 1.2;
    float c = max(cy * K - cx, 0.0) * K;
    hc = c;
    idf = 0.0;
    if (c < 0.07) {
        hc = smoothstep(0.7, 1.0, 1.0 - c) * 0.2;
        idf = 1.0;
    }

    vec4 cn = max(dy * K - dx, vec4(0.0)) * K;
    vec4 low = 1.0 - step(0.07, cn);
    hn = mix(cn, smoothstep(0.7, 1.0, 1.0 - cn) * 0.2, low);
}

vec3 envMap_fast(vec3 rd) {
    vec2 uv = (rd.xy - TIME * 0.25) * 1.5;
    float c1 = texture(noise_texture, uv * 0.5).r;
    float c2 = texture(noise_texture, uv).r;
    float c = smoothstep(0.4, 0.9, c1 * 0.6 + c2 * 0.4);
    vec3 col = vec3(p12(c), c * c * sqrt(c), min(c * 1.5, 1.0));
    return mix(col, col.yzx, rd * 0.25 + 0.25);
}

void fragment() {
    vec2 inv_px = 1.0 / SCREEN_PIXEL_SIZE;
    vec3 rd = normalize(vec3(FRAGCOORD.xy - inv_px * 0.5, inv_px.y));
    rd.xy = mat2(rot_a, vec2(-rot_a.y, rot_a.x)) * rd.xy;

    float inv_z = 1.0 / rd.z;
    float fake_height = texture(noise_texture, rd.xy * inv_z * 0.5).r;
    vec3 p = rd * ((1.0 - 0.1 * fake_height) * inv_z);

    float hm, idf;
    vec4 hn;
    height_5(p.xy * 4.0, hm, idf, hn);

    vec3 n = normalize(vec3(-0.1 * (hn.x - hn.y), -0.1 * (hn.z - hn.w), -0.01));
    float edge = 0.1 * (abs(hn.x + hn.y - 2.0 * hm) + abs(hn.z + hn.w - 2.0 * hm));
    edge = smoothstep(0.0, 1.0, sqrt(edge * 400.0));

    vec3 light_dir = vec3(0.0, 0.0, -1.0) - p;
    float d2 = max(dot(light_dir, light_dir), 1e-6);
    light_dir *= inversesqrt(d2);

    vec3 base_color = tex3D_fast(noise_texture, p * 2.0 + hm * 0.2, n) * ((hm * 0.8 + 0.2) * 1.5);
    float gray = dot(base_color, vec3(0.299, 0.587, 0.114));

    if (idf < 0.5) {
        float lin = min(gray * 1.5, 1.0);
        float g5 = p5(gray);
        float g24 = p24(gray);
        vec3 pal;
        if (color_choice == 0)      pal = vec3(lin, g24, min(gray * 1.2, 1.0));
        else if (color_choice == 1) pal = vec3(g5, lin, g24);
        else if (color_choice == 2) pal = vec3(g24, g5, lin);
        else                        pal = vec3(lin, g5, g24);
        base_color *= pal * 2.0;
    } else {
        base_color *= 0.1;
    }

    float diffuse = max(dot(light_dir, n), 0.0);
    float specular = p32(max(dot(reflect(-light_dir, n), -rd), 0.0));
    if (idf > 0.5) specular *= specular;

    vec3 final_color = base_color * (diffuse + 0.75)
                     + vec3(1.0, 0.97, 0.92) * specular
                     + vec3(0.5, 0.7, 1.0) * p32(specular);

    vec3 em = envMap_fast(reflect(rd, n));
    if (idf > 0.5) em *= 0.5;
    final_color += em;

    final_color *= (1.0 - edge * 0.8) / (1.0 + d2 * 0.125);
    COLOR = vec4(sqrt(clamp(final_color, 0.0, 1.0)), 1.0);
}