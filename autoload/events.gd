extends Node
## Barramento global de sinais (autoload "Events").
## Os sistemas emitem e escutam sinais aqui, sem se conhecerem diretamente.
## Exemplo: o inimigo morre -> Events.enemy_killed.emit(...) -> HUD, pickups e
## efeitos reagem cada um por conta propria.

# --- Partida ---
signal run_started
signal run_ended(victory: bool)
signal game_paused(paused: bool)
signal pause_requested  ## Ex.: botao de pausa do HUD (toque).

# --- Jogador ---
signal player_contact(damage: float)  ## Um inimigo encostou no jogador.
signal player_damaged(amount: float)
signal player_health_changed(current: float, max_value: float)
signal player_died

# --- Combate ---
signal enemy_killed(position: Vector2, xp_value: int, color: Color)
signal damage_dealt(position: Vector2, amount: float)

# --- Progressao ---
signal xp_collected(amount: int)
signal xp_changed(current: int, needed: int, level: int)
signal level_up(new_level: int)
signal upgrade_chosen(upgrade: UpgradeData)

# --- Feedback (juice) ---
signal camera_shake_requested(strength: float)
