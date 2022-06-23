// NOTE: Shader automatically converted from Godot Engine 3.4.2.stable's SpatialMaterial.

shader_type spatial;
render_mode diffuse_lambert;
uniform vec4 u_albedo : hint_color;

void fragment() {
	ALBEDO = u_albedo.rgb;
}

