#[compute]
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(set = 0, binding = 0, rgba8) uniform image2D output_image;

layout(set = 0, binding = 1, std430) readonly buffer ColorBuffer {
	vec4 colors[];
};

layout(push_constant, std430) uniform Params {
	float noise_scale;
	int   octaves;
	float intensity;
	int   seed;

	int   color_count;
	float resolution;
	float warp_strength;
	float warp_scale;

	vec4  bg_color;

	int   use_nebula; // bool 0 1
	float dist_scale;
	int   dist_octaves;
	float dist_strength;

    float curl_scale;
	float curl_strength;
	int   curl_octaves;
	float curl_eps;
} params;

// https://github.com/Auburn/FastNoiseLite/tree/master/GLSL
#include "lib/FastNoiseLite.glsl"

vec4 sample_nebula_gradient(float t) {
	int stops = params.color_count;
	if (stops <= 1) return colors[0];

	float scaled = clamp(t, 0.0, 1.0) * float(stops);
	int i0 = int(floor(scaled));
	int i1 = min(i0 + 1, stops);
	float local_t = scaled - float(i0);

	return mix(colors[i0], colors[i1], local_t);
}
// TODO fix
vec2 curl_noise(fnl_state state, vec2 p, float eps) {
	float n1 = fnlGetNoise2D(state, p.x, p.y + eps);
	float n2 = fnlGetNoise2D(state, p.x, p.y - eps);
	float n3 = fnlGetNoise2D(state, p.x + eps, p.y);
	float n4 = fnlGetNoise2D(state, p.x - eps, p.y);

	float dx = (n1 - n2) / (2.0 * eps);
	float dy = (n3 - n4) / (2.0 * eps);

	return vec2(dy, -dx);
}

vec2 rot2(vec2 p, float a) {
	float c = cos(a), s = sin(a);
	return vec2(c*p.x - s*p.y, s*p.x + c*p.y);
}
// TODO fix
float trig_turbulence(vec2 p, int iterations, float base_amp, float rot_angle) {
	float d = 0.0;
	float amp = base_amp;
	float trk = 1.0;
	for (int i = 0; i < iterations; i++) {
		p += sin(p.yx * 0.75 * trk) * amp;
		d -= abs(dot(cos(p), sin(p.yx)) * (0.57 / trk));
		trk *= 1.4;
		p = rot2(p, rot_angle);
	}
	return d;
}

void main() {
	ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
	if (pixel.x >= int(params.resolution) || pixel.y >= int(params.resolution)) return;

	if (params.use_nebula == 0) {
		imageStore(output_image, pixel, params.bg_color);
		return;
	}

	fnl_state state = fnlCreateState(params.seed);
	state.frequency = params.noise_scale / params.resolution;
	state.fractal_type = FNL_FRACTAL_FBM;
	state.octaves = params.octaves;

	vec2 p = vec2(pixel);

	float n = fnlGetNoise2D(state, p.x, p.y);
	n = (n + 1.0) * 0.5;
	n = pow(n, 2.0);

	fnl_state warp_state = fnlCreateState(params.seed + 1337);
	warp_state.frequency = params.warp_scale / params.resolution;
	warp_state.fractal_type = FNL_FRACTAL_FBM;
	warp_state.octaves = params.octaves;

	float warp_x = fnlGetNoise2D(warp_state, p.x, p.y);
	float warp_y = fnlGetNoise2D(warp_state, p.x + 999.0, p.y + 999.0);
	vec2 warp_offset = vec2(warp_x, warp_y) * params.warp_strength;

	fnl_state curl_state = fnlCreateState(params.seed + 4242);
	curl_state.frequency = params.curl_scale / params.resolution;
	curl_state.fractal_type = FNL_FRACTAL_FBM;
	curl_state.octaves = params.curl_octaves;

	float period = params.resolution / max(params.curl_scale, 0.01);
    float eps = period * 0.02; // ~2% of one noise cycle — tune the 0.02 by eye
    vec2 curl_offset = curl_noise(curl_state, p, eps) * params.curl_strength;

    //TODO tweak curl and turbulence. So fix
    //vec2 warped_p = p + warp_offset + trig_turbulence(curl_offset, 100, 2000, 33);
    vec2 warped_p = p + warp_offset;

	float n_color = fnlGetNoise2D(state, warped_p.x + 4096.0, warped_p.y + 4096.0);
	n_color = (n_color + 1.0) * 0.5;

    // distribution field — low-frequency by default, pulls color choice into large patches
	fnl_state dist_state = fnlCreateState(params.seed + 9001);
	dist_state.frequency = params.dist_scale / params.resolution;
	dist_state.fractal_type = FNL_FRACTAL_FBM;
	dist_state.octaves = params.dist_octaves;

    float n_dist = fnlGetNoise2D(dist_state, p.x, p.y);
	n_dist = (n_dist + 1.0) * 0.5;

    float t_final = mix(n_color, n_dist, params.dist_strength);

	vec4 nebula_color = sample_nebula_gradient(t_final);
	vec4 color = mix(params.bg_color, nebula_color, clamp(n * params.intensity, 0.0, 1.0));

	imageStore(output_image, pixel, color);
}

