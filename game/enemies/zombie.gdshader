// Material dos zumbis desenhados em lote (MultiMesh).
// COLOR = cor do vertice x cor da instancia (variacao de tom).
// INSTANCE_CUSTOM.r = flash branco ao levar dano (0..1)
// INSTANCE_CUSTOM.g = brilho dourado de elite (0..1)
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

varying float v_flash;
varying float v_elite;

void vertex() {
	v_flash = INSTANCE_CUSTOM.r;
	v_elite = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec3 base = COLOR.rgb;
	base = mix(base, base * vec3(1.25, 1.05, 0.55), v_elite);
	ALBEDO = mix(base, vec3(1.0), v_flash);
	EMISSION = vec3(1.0, 0.75, 0.2) * v_elite * 0.35 + vec3(v_flash * 0.6);
	ROUGHNESS = 0.9;
}
