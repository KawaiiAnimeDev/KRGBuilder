shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.15, 0.55, 0.8, 1.0);
uniform vec4 ridge_color : source_color = vec4(0.7, 1.0, 1.0, 1.0);
uniform vec3 fake_light_dir = vec3(0.4, 0.8, 0.3);
uniform float ambient : hint_range(0.0, 1.0) = 0.35;
uniform float rim_strength : hint_range(0.0, 3.0) = 1.2;

uniform float fade_in_start_z = -33.0;
uniform float fade_in_end_z = -30.0;
uniform float judgement_z = -1.25; // matches JUDGEMENT_Z in script, NOT 0
uniform float judgement_fade_range = 0.3;

instance uniform float hit_dissolve : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_normal;
varying vec3 world_pos;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 N = normalize(world_normal);
	vec3 L = normalize(fake_light_dir);
	float ndotl = max(dot(N, L), 0.0);
	float lit = ambient + (1.0 - ambient) * ndotl;

	float ridge = pow(clamp(1.0 - abs(UV.x - 0.5) * 2.0, 0.0, 1.0), 3.0);

	vec3 V = normalize(CAMERA_POSITION_WORLD - world_pos);
	float rim = pow(1.0 - max(dot(N, V), 0.0), 2.0) * rim_strength;

	vec3 color = mix(base_color.rgb, ridge_color.rgb, ridge) * lit;
	color += ridge_color.rgb * rim * 0.5;

	// fade in from far spawn point
	float fade_in = smoothstep(fade_in_start_z, fade_in_end_z, world_pos.z);
	// fade out once past the judgement line (not 0 — JUDGEMENT_Z is -1.25)
	float fade_out = 1.0 - smoothstep(judgement_z - judgement_fade_range, judgement_z, world_pos.z);
	float z_alpha = fade_in * fade_out;

	// instant/tweened disappearance on hit, independent of position
	float hit_alpha = 1.0 - hit_dissolve;

	ALBEDO = color;
	ALPHA = base_color.a * z_alpha * hit_alpha;
	EMISSION = color * (ridge * 0.6 + rim * 0.3) * z_alpha * hit_alpha;
}