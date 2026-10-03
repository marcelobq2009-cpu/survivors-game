extends Node
## Barramento global de sinais (autoload "Events").
## Os sistemas emitem e escutam sinais aqui, sem se conhecerem diretamente.
## Exemplo: zumbi morre -> Events.enemy_killed.emit(agente) -> HUD, drops,
## efeitos e estatisticas reagem cada um por conta propria.
## Posicoes sao Vector2 no "plano do chao" (ver GroundPlane).

# --- Partida ---
signal run_started
signal run_ended(result: RunResult)
signal game_paused(paused: bool)
signal pause_requested  ## Ex.: botao de pausa do HUD (toque).

# --- Jogador ---
signal player_contact(damage: float, source: String)  ## Algo feriu o jogador (source = quem, ex.: "Colosso").
signal player_damaged(amount: float)
signal player_health_changed(current: float, max_value: float)
signal player_healed(amount: float)  ## Ex.: bau.
signal player_died

# --- Combate ---
signal enemy_killed(agent: EnemyAgent)
signal damage_dealt(position: Vector2, amount: float, crit: bool)
signal explosion(position: Vector2, radius: float, sound: StringName)
## Avisos de perigo (visual + som + legenda): explosao prestes a acontecer e investida de chefe.
signal explosion_warning(position: Vector2, radius: float, duration: float)
signal charge_warning(position: Vector2, direction: Vector2, length: float, duration: float)
signal elite_spawned(data: EnemyData)
## Evento especial comecou (horde, supply, toxic) perto de `position`.
signal event_started(kind: StringName, position: Vector2)
signal boss_spawned(data: EnemyData)
signal boss_killed(data: EnemyData)

# --- Progressao na partida ---
signal xp_collected(amount: int)
signal xp_changed(current: int, needed: int, level: int)
signal level_up(new_level: int)
signal upgrade_chosen(upgrade: UpgradeData)
signal weapons_changed  ## Arma nova/evoluida (HUD atualiza os icones).
signal gold_collected(amount: int)
signal chest_opened

# --- Avisos na tela ("UM CHEFE APARECEU!", "HORDA!") ---
signal announcement(text: String, color: Color)

# --- Feedback ---
signal camera_shake_requested(strength: float)
## Legenda de um som importante (acessibilidade: "Inchado vai explodir!").
signal audio_caption(text: String)
