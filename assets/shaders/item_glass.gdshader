shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled, vertex_lighting;
uniform sampler2D atlas : source_color, filter_linear, repeat_disable;
void fragment() {
    ALBEDO = COLOR.rgb * mix(vec3(0.67), vec3(1.35), texture(atlas, UV).rgb);
    ROUGHNESS = 1.0;
    ALPHA = COLOR.a * 0.68;
}
