// NOTE: Shader automatically converted from Godot Engine 3.4.2.stable's SpatialMaterial.

shader_type spatial;
render_mode unshaded;

uniform sampler2D u_dither_tex;
uniform sampler2D u_color_tex;

uniform int u_bit_depth = 48;
uniform float u_contrast = 1.0;
uniform float u_offset = 0.0;
uniform int u_dither_size = 1;


uniform bool u_ground_enabled = true;
uniform float u_min_ground_height = 1.0;
uniform float u_max_ground_height = -5.0;
uniform vec4 u_ground_color: hint_color = vec4(1);

uniform bool u_fog_enabled = true;
uniform float u_min_fog_height = 5.0;
uniform float u_max_fog_height = 10.0;
uniform vec4 u_fog_color: hint_color = vec4(0);

void fragment() {
		// calculate pixel luminosity (https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color)
		
	vec3 c = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
		
	float lum = (c.r * 0.299) + (c.g * 0.587) + (c.b * 0.114);
	
	// adjust with contrast and offset parameter
	lum = (lum - 0.5 + u_offset) * u_contrast + 0.5;
	lum = clamp(lum, 0.0, 1.0);
	
	// reduce luminosity bit depth to give a more banded visual if desired	
	float bits = float(u_bit_depth);
	lum = floor(lum * bits) / bits;
	
	// to support multicolour palettes, we want to dither between the two colours on the palette
	// which are adjacent to the current pixel luminosity.
	// to do this, we need to determine which 'band' lum falls into, calculate the upper and lower
	// bound of that band, then later we will use the dither texture to pick either the upper or 
	// lower colour.
	
	// map lum to the range of the amount of colours, then read the texture at the correct spot
	
	// get the palette texture size mapped so it is 1px high (so the x value however many colour bands there are)
	ivec2 col_size = textureSize(u_color_tex, 0);
	col_size /= col_size.y;	
	
	float col_x = float(col_size.x) - 1.0; // colour boundaries is 1 less than the number of colour bands
	float col_texel_size = 1.0 / col_x; // the size of one colour boundary
	
	//lum = max(lum - 0.00001, 0.0); // makes sure our floor calculation below behaves when lum == 1.0
	float lum_lower = floor(lum * col_x) * col_texel_size;
	float lum_upper = (floor(lum * col_x) + 1.0) * col_texel_size;
	float lum_scaled = lum * col_x - floor(lum * col_x); // calculates where lum lies between the upper and lower bound
	
	ivec2 screen_size = textureSize(SCREEN_TEXTURE, 0);
	ivec2 noise_size = textureSize(u_dither_tex, 0) * u_dither_size;
	vec2 ratio = vec2(screen_size) / vec2(noise_size);
	//float ratio = max(float(screen_size.x) / float(noise_size.x), float(screen_size.y) / float(noise_size.y));
	//ratio = ceil(ratio);
	vec2 noise_uv = mod(SCREEN_UV * ratio, 1.0);
	float threshold = texture(u_dither_tex, noise_uv).r;

	float height = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).y;
	float fog_height_scaled = (height - u_min_fog_height) / (u_max_fog_height - u_min_fog_height);
	fog_height_scaled = log(fog_height_scaled) +1.0;
	fog_height_scaled = clamp(fog_height_scaled, 0.0, 1.0);
	float ground_height_scaled = (height - u_min_ground_height) / (u_max_ground_height - u_min_ground_height);
	
	// adjust the dither slightly so min and max aren't quite at 0.0 and 1.0
	// otherwise we wouldn't get fullly dark and fully light dither patterns at lum 0.0 and 1.0
	threshold = threshold * 0.99 + 0.005;
	
	// the lower lum_scaled is, the fewer pixels will be below the dither threshold, and thus will use the lower bound colour,
	// and vice-versa
	float ramp_val = (lum_scaled) < threshold ? 0.0f : 1.0f;
	// sample at the lower bound colour if ramp_val is 0.0, upper bound colour if 1.0
	float col_sample = mix(lum_lower, lum_upper, ramp_val);
	col_sample = clamp(col_sample, 0.05, 0.95);
	vec3 dither_col = texture(u_color_tex, vec2(col_sample, 0.5)).rgb;
	
	float fog_height_ramp = (fog_height_scaled) < threshold ? 0.0f : 1.0f;
	fog_height_ramp = (u_fog_enabled) ? fog_height_ramp : 0.0f;
	vec3 final_col = mix(dither_col, u_fog_color.rgb, fog_height_ramp);
	float ground_height_ramp = (ground_height_scaled) < threshold ? 0.0f : 1.0f;
	ground_height_ramp = (u_ground_enabled) ? ground_height_ramp : 0.0f;
	final_col = mix(final_col, u_ground_color.rgb, ground_height_ramp);
	
	// return the final colour!
	ALBEDO = final_col;
}
