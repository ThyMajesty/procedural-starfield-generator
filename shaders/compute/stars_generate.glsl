#[compute]
#version 450

layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

struct StarData {
	vec4 pos_radius;
	vec4 color;
};

layout(set = 0, binding = 0, std430) buffer Counter {
	uint count;
} counter;

// generate star data
layout(set = 0, binding = 1, std430) writeonly buffer StarBuffer {
	StarData stars[];
};

layout(push_constant, std430) uniform Params {
	int   attempt_count;
	int   max_stars;
	int   resolution;
	int   seed;

	float density_noise_scale;
	float density_bias;
	int   use_density_noise; // bool 0 1
	float brightness_power;

	float min_brightness;
	float max_brightness;
	float min_radius;
	float max_radius;

	int   size_follows_brightness; // bool 0 1
	int   use_color_variation;     // bool 0 1
	float warm_chance;
	float blue_chance;

    float giant_chance;
	float giant_size_multiplier;
	float _pad1;
	float _pad2;
} params;

// https://github.com/Auburn/FastNoiseLite/tree/master/GLSL
#include "lib/FastNoiseLite.glsl"

// PCG hash -> [0,1) float
uint pcg_hash(uint x) {
    uint state = x * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

float hash_to_float(uint h) {
	return float(h) / 4294967295.0;
}

void main() {
	uint idx = gl_GlobalInvocationID.x;
	if (idx >= uint(params.attempt_count)) return;

	uint base_seed = uint(params.seed) * 747796405u + idx * 2891336453u;

	float rx = hash_to_float(pcg_hash(base_seed + 0u));
	float ry = hash_to_float(pcg_hash(base_seed + 1u));
	float r_density = hash_to_float(pcg_hash(base_seed + 2u));
	float r_bright   = hash_to_float(pcg_hash(base_seed + 3u));
	float r_size     = hash_to_float(pcg_hash(base_seed + 4u));
	float r_color    = hash_to_float(pcg_hash(base_seed + 5u));
	float r_giant    = hash_to_float(pcg_hash(base_seed + 6u));

	float x = rx * float(params.resolution);
	float y = ry * float(params.resolution);

	if (params.use_density_noise == 1) {
		fnl_state state = fnlCreateState(params.seed);
		state.frequency = params.density_noise_scale / float(params.resolution);
		float n = (fnlGetNoise2D(state, x, y) + 1.0) * 0.5;
		n = pow(n, params.density_bias);
		if (r_density > n) return;
	}

	float brightness = mix(params.min_brightness, params.max_brightness, pow(r_bright, params.brightness_power));

	bool is_giant = r_giant < params.giant_chance;
	float size_t;
	if (is_giant) {
		size_t = mix(0.5, 1.0, r_size) * params.giant_size_multiplier;
	} else if (params.size_follows_brightness == 1) {
		size_t = brightness;
	} else {
		size_t = pow(r_size, 4.0) * 0.7;
	}
	float radius = mix(params.min_radius, params.max_radius, size_t);

	vec4 color;
	if (params.use_color_variation == 1) {
		vec3 base = vec3(1.0);
		if (r_color < params.warm_chance) {
			base = vec3(1.0, 0.85, 0.65);
		} else if (r_color < params.warm_chance + params.blue_chance) {
			base = vec3(0.75, 0.85, 1.0);
		}
		color = vec4(base * brightness, 1.0);
	} else {
		color = vec4(brightness, brightness, brightness, 1.0);
	}

	uint slot = atomicAdd(counter.count, 1u);
	if (slot >= uint(params.max_stars)) return;

	stars[slot].pos_radius = vec4(x, y, radius, brightness);
	stars[slot].color = color;
}
