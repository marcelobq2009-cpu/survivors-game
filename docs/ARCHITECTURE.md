# Arquitetura

## Ideia central
**Simulação no plano do chão (Vector2) + apresentação 3D.** Zumbis, projéteis e gemas são
"agentes" de dados (sem nós), movidos em loops únicos e desenhados em lote com `MultiMesh`
(`InstanceRenderer`). Isso permite hordas grandes no celular. `GroundPlane` converte
`Vector2(x, y)` ↔ `Vector3(x, altura, y)` (1 unidade = 1 metro).

## Fluxo de telas (`SceneFlow`)
```
main_menu ─ JOGAR/RANQUEADO ─▶ run_setup_screen (Personagem › Mapa › Confirmar) ─▶ world
          ├ PERSONAGENS/MAPAS ─▶ run_setup_screen (galeria)
          ├ RANKING ─▶ ranking_screen     ├ CONQUISTAS ─▶ achievements_screen
          └ CONFIGURAÇÕES ─▶ settings_screen (usa SettingsPanel, também usado na pausa)
world ─ fim ─▶ ResultsScreen ─▶ jogar de novo / menu / ranking
```
`SceneFlow.go_to(caminho, params)` faz fade; a tela lê `SceneFlow.params`.

## Cena da partida (`game/world/world.tscn`)
```
World            monta mapa + jogador de GameState.setup, conta tempo, encerra partida
├ Map            recebe a cena do mapa (MapData.scene, raiz GameMap)
├ EnemyManager   agentes de zumbi, SpatialGrid, contorno de obstáculos, comportamentos
├ ProjectileManager  balas e arremessos (agentes + MultiMesh)
├ PickupManager  gemas/moedas/baús (agentes + MultiMesh)
├ Effects        números de dano, partículas, explosões, golpe (pools próprios)
├ EnemySpawner   ondas (WaveTimeline) + DifficultyDirector + chefes + hordas
├ CameraRig      câmera isométrica independente (zoom, tremor, foco)
├ Player         (instanciado em runtime) CharacterBody3D + armas filhas
└ Hud / LevelUpScreen / PauseMenu / ResultsScreen / DebugPanel / TutorialOverlay / DebugOverlay
```
A ordem importa: `EnemyManager` reconstrói a grade antes de armas/projéteis buscarem alvos.

## Autoloads
| Nome | Papel |
|---|---|
| `Config` | `data/config/game_config.tres` (cópia em runtime): duração 30 min, debug, multiplicadores, limite de zumbis, ouro, pontuação |
| `Events` | Barramento de sinais (combate, progressão, avisos, partida) |
| `Content` | Carrega personagens, mapas e conquistas de `data/` |
| `Save` | Perfil (`ProfileData`) em JSON versionado, gravação segura (.tmp + .bak) |
| `GameState` | Partida atual: setup, tempo, abates, XP, ouro, dano por arma, armas, **pausa compartilhada** |
| `Pool` | Pooling genérico de nós (sobrou do protótipo; os agentes têm pools próprios) |
| `Audio` | Buses Music/SFX, sons placeholder sintetizados, troca automática por arquivos em `assets/audio/` |
| `Ranking` | Serviço de ranking; provider atual `LocalRankingProvider` (mock) |
| `SceneFlow` | Navegação com fade + aviso "gire o celular" |

## Dados (data-driven)
| Pasta | Classe | Observação |
|---|---|---|
| `data/characters/` | `CharacterData` (extends `ContentData`) | stats, arma inicial, passiva, requisitos |
| `data/maps/` | `MapData` | cena, timeline, perfil de dificuldade, duração (0 = Config) |
| `data/maps/layouts/` | `CityLayout` | parâmetros do gerador de cidade (`CityMap`) |
| `data/enemies/` | `EnemyData` | stats, comportamento (CHASE/EXPLODER/CHARGER), drops, cores |
| `data/weapons/` | `WeaponData` | stats + `scene` (comportamento) |
| `data/upgrades/` | `UpgradeData` | NEW_WEAPON, WEAPON_STAT, PLAYER_STAT, HEAL, EVOLVE, GOLD + requisitos |
| `data/waves/` | `WaveTimeline` | QUAIS zumbis e o ritmo base |
| `data/difficulty/` | `DifficultyProfile` | COMO a dificuldade cresce (vida, dano, velocidade, elites, chefes, hordas) |
| `data/achievements/` | `AchievementData` | condição = `unlock_requirements` |
| `data/config/` | `GameConfig` | parâmetros centrais |

## Desbloqueios e progressão permanente
- `UnlockRequirement` (base) + `SurviveRequirement` (map_id, seconds; **0 = duração do modo normal**),
  `KillsRequirement`, `LevelRequirement`, `BossRequirement`, `AchievementRequirement`.
- `ProgressService.finalize_run()` (puro, testado): ouro, pontuação, recordes, conquistas e
  desbloqueios. Chamado pelo `World` no fim; depois `Save.save_data()`.
- Conteúdo com `coming_soon = true` aparece como "EM BREVE".

## Dificuldade (normal e ranqueado)
`DifficultyDirector` combina: vida, dano, velocidade (com teto), ritmo de spawn (com teto), chance
de elite (zumbi dourado, 6x vida), chefes a cada `boss_interval` (rodízio, cada vez mais fortes) e
hordas em anel. No ranqueado, depois do fim da timeline, `overtime_growth_mult` acelera tudo.
`Config.game.max_active_enemies` limita zumbis vivos (performance).

## Mapa
`GameMap` (base) expõe `grid` (`MapGrid`, obstáculos 1 m), `bounds` e `player_spawn`.
`CityMap` gera a cidade a partir de um `CityLayout`: quarteirões, prédios (malhas juntadas por
"pedaço" de 64 m), praças, carros/ônibus, barricadas, postes, entulho, orla com calçadão de ondas,
quiosques, palmeiras, morro com comunidade, Cristo e Pão de Açúcar. Colisão do jogador: camada 5
"world". Zumbis contornam obstáculos consultando a grade (custo O(1)).

## Como adicionar…
- **Zumbi**: novo `.tres` em `data/enemies/` + incluir em ondas de `data/waves/*.tres`.
  Comportamento novo = novo valor em `EnemyData.Behavior` + caso no `EnemyManager`. (`/new-enemy`)
- **Arma**: comportamento existente (projétil/corpo a corpo/arremesso/aura) = só `.tres` + upgrade
  `NEW_WEAPON`. Novo comportamento = `extends Weapon` + `attack()` + cena. (`/new-weapon`)
- **Upgrade/passiva/evolução**: `.tres` em `data/upgrades/` (stat pelo nome). (`/new-upgrade`)
- **Personagem**: `.tres` em `data/characters/` (requisitos opcionais). Modelo: `model_scene`.
- **Mapa**: `.tres` em `data/maps/` + cena com raiz `GameMap` (ou `CityMap` + novo `CityLayout`).
- **Conquista**: `.tres` em `data/achievements/` com requisitos.
- **Som**: arquivo `assets/audio/<id>.ogg|wav` (ids em `autoload/audio.gd`).
- **Ranking online**: classe que estende `RankingProvider`, trocar em `autoload/ranking.gd`.

## Convenções
- Tipagem estática obrigatória; `class_name` em classes reutilizáveis.
- Lógica testável em classes puras (`RefCounted`): `ProgressService`, `DifficultyDirector`,
  `UpgradePicker`, `Health`, `Progression`, `SpatialGrid`, `MapGrid`.
- Telas que funcionam com o jogo pausado: `process_mode = ALWAYS` e `GameState.request_pause(self)`.
- Testes usam save separado (`Save.set_storage_path`) para não mexer no progresso real.
