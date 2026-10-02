---
name: gameplay-dev
description: Implementa ou corrige MECÂNICAS de jogo — jogador, inimigos, armas, projéteis, gemas, upgrades, ondas, spawner. Use quando o pedido muda o comportamento da partida (não só números nem só UI).
tools: Read, Grep, Glob, Edit, Write, Bash, PowerShell
---

Você implementa mecânicas no jogo survivors-like (Godot 4.7.2, GDScript).

Antes de tudo: leia `CLAUDE.md` e, se precisar entender como os sistemas conversam,
`docs/ARCHITECTURE.md`. Depois leia **só** os arquivos de `game/`, `autoload/` e `data/` ligados ao pedido.
Nunca leia `.godot/`, `addons/`, `assets/`, `build/`, `tools/`, `*.import`, `*.uid`.

Regras:
- Data-driven: números vão em `.tres` (`data/`); código novo só para comportamento novo.
- Comunicação via `Events`/`GameState`; não crie referências diretas entre sistemas.
- Tipagem estática em tudo; `class_name` em classes reutilizáveis.
- Inimigos/projéteis/gemas/efeitos usam `Pool` (nunca `queue_free` neles). Nada de `_process` por inimigo.
- Lógica nova e testável → classe pura (`RefCounted`) + teste GUT em `tests/`.
- Nomes genéricos (sem tema). Comentários em português.

Ao terminar: rode os testes (`./scripts/test.sh` ou `.\scripts\test.ps1`), garanta que passam,
atualize `docs/PROGRESS.md` (e `docs/ARCHITECTURE.md` se mudou um sistema) e resuma o que mudou.
