// This is a corrected and optimized version of the triplanar shader.
// It has been updated to fix a compile error on the Mobile renderer where
// the `WORLD_VERTEX_COORDS` built-in is not available.
shader_type spatial;

// Varyings are used to pass data from the vertex to the fragment shader.
// `highp` requests high precision, which is crucial for world coordinates.
varying highp vec3 v_world_normal;
varying highp vec3 v_world_pos;

// --- UNIFORMS ---
uniform bool enable_normal_map = false;
uniform bool enable_roughness = false;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float blend_sharpness : hint_range(1.0, 16.0) = 4.0;

// Rendering hints for samplers improve quality and ensure correct tiling.
group_uniforms x_plane;
uniform sampler2D x_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D x_normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D x_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float x_scale = 1.0;

group_uniforms y_plane;
uniform sampler2D y_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D y_normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D y_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float y_scale = 1.0;

group_uniforms z_plane;
uniform sampler2D z_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D z_normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D z_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float z_scale = 1.0;


void vertex() {
	// Calculate world-space position and normal for each vertex.
	// These values will be interpolated and passed to the fragment shader.
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// A reusable function to sample from the three texture planes and blend them.
vec3 triplanar_sample(sampler2D tex_x, sampler2D tex_y, sampler2D tex_z, vec3 pos, vec3 blend_weights) {
	// Sample from each plane using the world position for UVs, adjusted by scale.
	vec3 x = texture(tex_x, pos.yz / x_scale).rgb;
	vec3 y = texture(tex_y, pos.xz / y_scale).rgb;
	vec3 z = texture(tex_z, pos.xy / z_scale).rgb;

	// Blend the samples based on the weights.
	return x * blend_weights.x + y * blend_weights.y + z * blend_weights.z;
}

void fragment() {
	// Use the interpolated values from the vertex shader.
	// It's crucial to re-normalize varyings in the fragment shader.
	highp vec3 world_pos = v_world_pos;
	highp vec3 world_normal = normalize(v_world_normal);

	// Calculate blend weights based on the world normal.
	// `pow` is used to sharpen the transition between textures.
	vec3 blend_weights = pow(abs(world_normal), vec3(blend_sharpness));
	// Normalize the weights to ensure they sum to 1.
	blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);

	// --- ALBEDO ---
	// We now use the `v_world_pos` varying. Using `highp` helps mitigate,
	// but may not completely eliminate, "swimming" artifacts on all hardware.
	// This is the necessary trade-off for mobile compatibility.
	ALBEDO = triplanar_sample(x_albedo, y_albedo, z_albedo, world_pos, blend_weights);

	// --- ROUGHNESS ---
	if (enable_roughness) {
		// Sample roughness similarly. The `.r` component is used as per the hint.
		ROUGHNESS = triplanar_sample(x_roughness, y_roughness, z_roughness, world_pos, blend_weights).r;
	} else {
		ROUGHNESS = roughness;
	}

	// --- NORMAL MAP ---
	if (enable_normal_map) {
		// Sample and blend the normal maps from the three planes.
		vec3 normal_map_sample = triplanar_sample(x_normal_map, y_normal_map, z_normal_map, world_pos, blend_weights);
		
		// This robust method calculates the final world-space normal.
		vec3 n = world_normal;
		vec3 t_up = abs(n.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
		vec3 tangent = normalize(t_up - n * dot(t_up, n));
		vec3 binormal = cross(n, tangent);
		mat3 tbn = mat3(tangent, binormal, n);

		// Convert sampled normal from [0,1] range to [-1,1] range.
		vec3 tangent_space_normal = normal_map_sample * 2.0 - 1.0;

		// Transform the tangent-space normal into world space and assign it.
		NORMAL = normalize(tbn * tangent_space_normal);
	}
}
