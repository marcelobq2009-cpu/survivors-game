# Arquitetura

## Visão geral
```
ui/main_menu.tscn ──Jogar──▶ game/world/world.tscn
World (conta o tempo, começa/termina a partida)
├─ Ground            chão (grade que segue o jogador)
├─ Gems              GemSpawner: cria gema onde inimigo morre
├─ EnemyManager      move TODOS os inimigos + reconstrói a SpatialGrid a cada frame
├─ Player            movimento, vida, armas (filhas em Player/Weapons), câmera
├─ Projectiles       camada dos projéteis (grupo "projectile_layer")
├─ Effects           números de dano + partículas
├─ EnemySpawner      lê a WaveTimeline e pede inimigos ao EnemyManager
└─ Hud / LevelUpScreen / PauseMenu / GameOverScreen / DebugOverlay   (CanvasLayers)
```
A ordem importa: `EnemyManager` vem antes de `Player`/`Projectiles`, então a grade já está
atualizada quando as armas procuram alvos.

## Autoloads (singletons)
| Nome | Papel |
|---|---|
| `Events` | Barramento de sinais. Ex.: `enemy_killed`, `xp_collected`, `level_up`, `upgrade_chosen`, `player_contact`, `run_ended` |
| `GameState` | Estado da partida: tempo, abates, `progression` (nível/XP), posição/raio do jogador, upgrades escolhidos, armas que tem |
| `Pool` | `acquire(scene, parent)` / `release(node)`; nós liberados ficam escondidos e sem processar |
| `Save` | Recordes em `user://save.json` |
| `Audio` | `Audio.play(&"id")`; ids sem som ainda tocam silêncio (registrar em `SOUNDS`) |

## Fluxo de um abate
`Projectile` acha inimigo pela `SpatialGrid` → `Enemy.take_damage()` → `Events.damage_dealt`
(número de dano) → vida ≤ 0 → `Events.enemy_killed(pos, xp, cor)` → `GemSpawner` cria gema,
`Effects` solta partículas, `GameState` conta abate → jogador encosta na gema →
`Events.xp_collected` → `GameState.add_xp` → `Events.level_up` → `LevelUpScreen` pausa, sorteia
(`UpgradePicker`) → `Events.upgrade_chosen` → `Player` aplica.

## Dano no jogador
`EnemyManager` checa distância inimigo↔jogador e emite `Events.player_contact(dano)` (1x por
frame, maior dano). `Player` usa `Health` (com invencibilidade curta) e emite `player_damaged`,
`player_health_changed`, `camera_shake_requested` e, se morrer, `player_died` → `World` encerra.

## Por que inimigos sem física?
`CharacterBody2D`/`Area2D` com 300+ corpos colidindo entre si é caro no celular. Aqui cada
inimigo é um `Node2D` + `Sprite2D`; o `EnemyManager` move todos num loop, a separação usa a
`SpatialGrid` (metade dos inimigos por frame) e colisões são checagens de distância.
Camadas de física nomeadas (player, enemy, player_projectile, pickup) ficam para uso futuro.

## Como adicionar...
### Inimigo (só dados)
1. Duplicar `data/enemies/basic.tres` → `data/enemies/<id>.tres`; mudar `id`, stats, `texture`, `color`.
2. Colocar o novo recurso no array `enemies` de alguma onda em `data/waves/main_timeline.tres`.
3. Rodar testes. (Comando: `/new-enemy`)

### Arma
- **Com comportamento existente** (projétil/aura): duplicar `data/weapons/*.tres`, mudar `id` e stats,
  e criar um upgrade `NEW_WEAPON` apontando para ela (senão ninguém consegue pegá-la).
- **Comportamento novo**: criar `game/weapons/<nome>_weapon.gd` (`extends Weapon`, implementar
  `attack()`), uma cena `.tscn` com esse script, e um `WeaponData` com `scene` apontando para ela.
  Stats que upgrades mudam devem ser variáveis da classe (`damage`, `cooldown`, `area`...). (Comando: `/new-weapon`)

### Upgrade (só dados)
Criar `data/upgrades/<id>.tres` (`UpgradeData`): `kind` = NEW_WEAPON | WEAPON_STAT | PLAYER_STAT | HEAL,
`stat` (nome da variável: ex. `damage`, `move_speed`, `cooldown_mult`), `value`, `is_multiplier`,
`max_picks`, `weight`. O jogo carrega a pasta inteira sozinho. (Comando: `/new-upgrade`)

## Convenções
- Tipagem estática obrigatória; `class_name` em classes reutilizáveis.
- Nós de pool implementam `setup(...)` para reiniciar estado (opcional `on_acquire/on_release`).
- `SpatialGrid` usa `position`: itens precisam ser filhos de nós na origem do mundo.
- Ambiente: Godot em `tools/godot/` em modo autocontido (`._sc_`), templates em `tools/godot/editor_data/`.
