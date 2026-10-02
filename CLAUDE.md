# Survivors Game — guia rápido para o Claude

Jogo survivors-like (estilo Vampire Survivors) em **Godot 4.7.2 / GDScript**, para celular em retrato
(720x1280), testado no PC e na web. Tema ainda **não definido**: arte placeholder geométrica e
nomes genéricos (`Enemy`, `Weapon`...). O dono é iniciante em Godot: explique em português simples.

## Idioma
- Código, nomes de arquivos/classes: **inglês**. Comentários, docs, commits e respostas: **português (BR)**.

## Comandos (Windows: `.ps1` | Linux/nuvem/CI: `.sh`)
- Testes: `.\scripts\test.ps1` | `./scripts/test.sh` (GUT headless; um arquivo: `-gtest=res://tests/x.gd`)
- Rodar no PC: `.\scripts\run.ps1` (menu) ou `.\scripts\run.ps1 res://game/world/world.tscn`
- Build web: `.\scripts\build-web.ps1` | `./scripts/build-web.sh` → `build/web/`
- Godot direto: `scripts/godot.(ps1|sh) <args>` (binário local em `tools/godot/`)
- Estresse/perf: `scripts/godot.(ps1|sh) --headless res://tests/perf/stress.tscn --fixed-fps 60`
- Publicar: push na `main` → GitHub Actions testa e publica em https://marcelobq2009-cpu.github.io/survivors-game/

## Mapa de pastas
- `autoload/` singletons: `Events` (sinais), `GameState` (estado da partida), `Pool`, `Save`, `Audio`
- `game/player/` jogador, vida (`Health`), stats, XP (`Progression`, `XpCurve`)
- `game/enemies/` inimigo, `EnemyManager` (move todos + grade), spawner, classes de ondas
- `game/weapons/` `Weapon` base, `ProjectileWeapon`, `AuraWeapon`, projétil
- `game/pickups/` gemas de XP | `game/upgrades/` `UpgradeData`, sorteio, aplicação de stats
- `game/world/` cena da partida, câmera, chão, efeitos, `SpatialGrid`
- `ui/` HUD, joystick, level-up, pausa, game over, menu, debug, tema (`main_theme.tres`)
- `data/` **todos os números do jogo** em `.tres`: enemies/, weapons/, upgrades/, waves/, player/
- `tests/` testes GUT (`test_*.gd`) + `tests/perf/` | `scripts/` terminal | `docs/` documentação

## Regras de arquitetura
- **Data-driven**: stats ficam em `.tres` (`data/`). Inimigo/arma/upgrade novo = novo `.tres`;
  código novo só para comportamento novo.
- **Sinais via `Events`**: sistemas não guardam referência uns dos outros; leem `GameState`.
- **Tipagem estática em tudo** (variável sem tipo = erro de compilação). `class_name` nas classes base.
- **Pooling**: inimigos, projéteis, gemas e efeitos vêm de `Pool.acquire()`/`Pool.release()`; nunca `queue_free` neles.
- **Performance mobile**: inimigos são `Node2D` sem física; colisão/alvos via `SpatialGrid` (usa `position`,
  os pais ficam na origem). Nada de `_process` por inimigo: o `EnemyManager` faz o loop.
- Lógica testável fica em classes puras (`RefCounted`) separadas dos nós.

## Regras de trabalho (economizar tokens)
- Leia **só** os arquivos ligados ao pedido. Use Grep/Glob antes de abrir arquivos grandes.
- **Nunca** leia: `.godot/`, `addons/`, `assets/` (binários), `build/`, `tools/`, `*.import`, `*.uid`.
- Não edite `.tscn`/`.tres` à mão se der para gerar/ajustar de forma segura; mantenha o formato do Godot.
- Ao terminar uma tarefa: rode os testes, faça commit pequeno em português e **atualize `docs/PROGRESS.md`**.
- Mudou regra/sistema? Atualize o doc correspondente (curto).
- Asset externo novo? Registre em `assets/CREDITS.md`.

## Onde ler mais (não copie para cá)
- Design do jogo, loop e ideias: `docs/GDD.md`
- Como os sistemas conversam / como adicionar inimigo, arma, upgrade: `docs/ARCHITECTURE.md`
- Onde paramos, pendências e bugs: `docs/PROGRESS.md`
- Celular (web hoje; Android/iOS no futuro): `docs/MOBILE.md`

## Subagentes e comandos
- Agentes em `.claude/agents/`: `gameplay-dev`, `ui-mobile`, `qa-tester`, `balance-designer`, `perf-optimizer`.
- Comandos: `/test`, `/play-web`, `/status`, `/new-enemy`, `/new-weapon`, `/new-upgrade`.

## Nuvem (Claude Code pelo celular)
- O hook `SessionStart` (`scripts/setup-cloud.sh`) baixa o Godot Linux quando `CLAUDE_CODE_REMOTE=true`.
- Fluxo: pedido → testes (`./scripts/test.sh`) → commit + push na `main` → ~2–3 min → testar no link.
