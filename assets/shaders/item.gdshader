shader_type spatial;
render_mode diffuse_lambert, specular_disabled, vertex_lighting;
uniform sampler2D atlas : source_color, filter_linear, repeat_disable;
void fragment() {
    vec3 paint = texture(atlas, UV).rgb;
    ALBEDO = COLOR.rgb * mix(vec3(0.67), vec3(1.35), paint);
    ROUGHNESS = 1.0;
}
