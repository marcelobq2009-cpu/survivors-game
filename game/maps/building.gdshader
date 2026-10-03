// Material dos predios: cor dos vertices + "buraco" de visao.
// Quando um pedaco de parede esta entre a camera e o jogador, ele some com
// um pontilhado suave (o jogador nunca fica escondido atras dos predios).
// `player_world_pos` e uma variavel global atualizada pelo Player a cada frame.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

global uniform vec3 player_world_pos;
uniform float hole_radius = 3.2;
uniform float min_height = 0.8;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.92;
	vec3 cam_dir = normalize(CAMERA_DIRECTION_WORLD);
	vec3 target = player_world_pos + vec3(0.0, 0.9, 0.0);
	vec3 to_frag = world_pos - CAMERA_POSITION_WORLD;
	vec3 to_player = target - CAMERA_POSITION_WORLD;
	float frag_depth = dot(to_frag, cam_dir);
	float player_depth = dot(to_player, cam_dir);
	vec3 lateral = (to_frag - cam_dir * frag_depth) - (to_player - cam_dir * player_depth);
	float d = length(lateral);
	if (frag_depth < player_depth - 0.6 && d < hole_radius && world_pos.y > min_height) {
		float fade = smoothstep(hole_radius, hole_radius * 0.55, d);
		float dither = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
		if (fade > dither) {
			discard;
		}
	}
}
