#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

// draw star data
layout(set = 0, binding = 0, rgba8) uniform image2D output_image;

struct StarData {
	vec4 pos_radius; // x, y, radius, brightness (brightness unused, already baked into color)
	vec4 color;      // r, g, b, a
};

layout(set = 0, binding = 1, std430) readonly buffer StarBuffer {
	StarData stars[];
};

layout(push_constant, std430) uniform Params {
	int star_count;
	int resolution;
	float _pad0;
	float _pad1;
} params;

void main() {
	uint idx = gl_GlobalInvocationID.x;
	if (idx >= uint(params.star_count)) return;

	StarData s = stars[idx];
	vec2 center = s.pos_radius.xy;
	float radius = s.pos_radius.z;
	vec3 color = s.color.rgb;

	int r = int(ceil(radius * 3.0));
	ivec2 c = ivec2(center);

	for (int dy = -r; dy <= r; dy++) {
		for (int dx = -r; dx <= r; dx++) {
			ivec2 p = c + ivec2(dx, dy);
			if (p.x < 0 || p.y < 0 || p.x >= params.resolution || p.y >= params.resolution) continue;

			float dist_sq = float(dx * dx + dy * dy);
			float falloff = exp(-dist_sq / (2.0 * radius * radius));
			if (falloff < 0.02) continue;

			vec4 existing = imageLoad(output_image, p);
			vec3 added = existing.rgb + color * falloff;
			imageStore(output_image, p, vec4(clamp(added, 0.0, 1.0), 1.0));
		}
	}
}
