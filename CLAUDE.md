# Apocalipse Brasil — guia rápido para o Claude

Survivor-like de apocalipse zumbi no Brasil (Capítulo 1: Rio de Janeiro) em **Godot 4.7.2 / GDScript**.
**3D com câmera isométrica**, celular em **paisagem** (1280x720), testado no PC e na web.
Arte placeholder 3D gerada por código. O dono é iniciante em Godot: explique em português simples.

## Idioma
- Código, arquivos, classes: **inglês**. Comentários, docs, commits, respostas e textos do jogo: **português (BR)**.

## Comandos (Windows: `.ps1` | Linux/nuvem/CI: `.sh`)
- Testes: `.\scripts\test.ps1` | `./scripts/test.sh` (GUT headless; um arquivo: `-gtest=res://tests/x.gd`)
- Rodar no PC: `.\scripts\run.ps1` (menu) ou `.\scripts\run.ps1 res://game/world/world.tscn`
- Build web: `.\scripts\build-web.ps1` | `./scripts/build-web.sh` → `build/web/`
- Robô de playtest: `scripts/godot.(ps1|sh) --headless res://tests/perf/playtest_bot.tscn --fixed-fps 60 -- minutes=10`
- Estresse/perf: `scripts/godot.(ps1|sh) --headless res://tests/perf/stress.tscn --fixed-fps 60`
- Publicar: push na `main` → GitHub Actions testa e publica em https://marcelobq2009-cpu.github.io/survivors-game/

## Mapa de pastas
- `autoload/` Config, Events, Content, Save, GameState, Pool, Audio, Ranking, SceneFlow
- `game/meta/` personagens, mapas, conquistas, requisitos de desbloqueio, perfil/save, ranking, ProgressService
- `game/maps/` GameMap, MapGrid (obstáculos), CityMap (gerador de cidade), cenas dos mapas
- `game/player/` Player 3D, Health, PlayerStats, Progression/XpCurve
- `game/enemies/` EnemyAgent, EnemyManager (loop + MultiMesh), spawner, DifficultyDirector, ondas
- `game/weapons/` Weapon base + projétil/corpo a corpo/arremesso/aura, ProjectileManager
- `game/pickups/` PickupManager (gemas, ouro, baú) | `game/upgrades/` UpgradeData, sorteio
- `game/world/` World, CameraRig, Effects, InstanceRenderer, PlaceholderMeshes, SpatialGrid
- `ui/` menus (UiScreen/UiKit), HUD, level-up, pausa, resultado, debug, tutorial, joystick
- `data/` **todos os números do jogo** em `.tres` (characters, maps, enemies, weapons, upgrades, waves, difficulty, achievements, config)
- `tests/` GUT (`test_*.gd`) + `tests/perf/` (robô e estresse) | `scripts/` | `docs/`

## Regras de arquitetura
- **Simulação no chão (Vector2) + visual 3D**: zumbis/projéteis/gemas são agentes de dados desenhados com MultiMesh.
- **Data-driven**: conteúdo novo = novo `.tres`; código só para comportamento novo. Nada de números mágicos: use `Config.game`.
- **Sinais via `Events`**; estado da partida em `GameState`; progresso permanente em `Save.profile`.
- **Tipagem estática em tudo** (variável sem tipo = erro). `class_name` nas classes base.
- **Pausa**: use `GameState.request_pause(self)` / `release_pause(self)` (várias telas pausam juntas).
- Lógica testável em classes puras (`RefCounted`). Testes que salvam usam `Save.set_storage_path(...)`.

## Regras de trabalho (economizar tokens)
- Leia **só** os arquivos ligados ao pedido. Use Grep/Glob antes de abrir arquivos grandes.
- **Nunca** leia: `.godot/`, `addons/`, `assets/` (binários), `build/`, `tools/`, `*.import`, `*.uid`.
- Prefira gerar/ajustar `.tres`/`.tscn` mantendo o formato do Godot (veja um arquivo vizinho como modelo).
- Ao terminar: rode os testes, commit pequeno em português e **atualize `docs/PROGRESS.md`**.
- Mudou sistema? Atualize `docs/ARCHITECTURE.md` (curto). Asset externo? `assets/CREDITS.md`.

## Onde ler mais (não copie para cá)
- Design, conteúdo e modos: `docs/GDD.md`
- Sistemas e "como adicionar inimigo/arma/upgrade/personagem/mapa": `docs/ARCHITECTURE.md`
- Onde paramos, pendências e bugs: `docs/PROGRESS.md`
- Celular (web hoje; Android/iOS no futuro): `docs/MOBILE.md`

## Subagentes e comandos
- Agentes em `.claude/agents/`: `gameplay-dev`, `ui-mobile`, `qa-tester`, `balance-designer`, `perf-optimizer`.
- Comandos: `/test`, `/play-web`, `/status`, `/new-enemy`, `/new-weapon`, `/new-upgrade`.

## Nuvem (Claude Code pelo celular)
- O hook `SessionStart` (`scripts/setup-cloud.sh`) baixa o Godot Linux quando `CLAUDE_CODE_REMOTE=true`.
- Fluxo: pedido → testes (`./scripts/test.sh`) → commit + push na `main` → ~2–3 min → testar no link.
