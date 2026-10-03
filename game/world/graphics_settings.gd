class_name GraphicsSettings
extends RefCounted
## Aplica a "Qualidade grafica" das Configuracoes.
## BAIXA: sem sombras, resolucao 3D 70%. MEDIA: sem sombras, 100%.
## ALTA: sombras do sol + suavizacao (MSAA 2x).


static func apply(tree: SceneTree, settings: GameSettings) -> void:
	var vp := tree.root
	Engine.max_fps = settings.fps_limit
	var rig := CameraRig.find(tree)
	if rig:
		rig.apply_zoom_setting(settings.camera_zoom)
	match settings.quality:
		GameSettings.Quality.LOW:
			vp.scaling_3d_scale = 0.7
			vp.msaa_3d = Viewport.MSAA_DISABLED
		GameSettings.Quality.MEDIUM:
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_DISABLED
		_:
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_2X
	for node: Node in tree.get_nodes_in_group(&"sun"):
		var light := node as DirectionalLight3D
		if light:
			light.shadow_enabled = settings.quality == GameSettings.Quality.HIGH
