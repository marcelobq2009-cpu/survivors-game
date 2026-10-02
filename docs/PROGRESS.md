# Progresso

_Última atualização: 2026-10-02_

## Pronto
- Ambiente: Godot 4.7.2 local (`tools/godot/`), GUT 9.7.1, scripts `test`/`run`/`build-web` (ps1 + sh).
- Projeto: retrato 720x1280, Compatibility, inputs, camadas, tipagem estática obrigatória.
- Arquitetura: autoloads `Events`/`GameState`/`Pool`/`Save`/`Audio`, `SpatialGrid`, dados em `.tres`.
- Protótipo jogável: jogador + joystick flutuante, 3 inimigos, 10 ondas (10 min), projétil + aura,
  gemas de XP com ímã, level-up com 3 cartas (14 upgrades), HUD, menu, pausa, game over/vitória,
  juice (flash, números, tremor, partículas), overlay de debug (F3 / 3 dedos).
- 41 testes GUT (XP, vida, stats, sorteio, ondas, pool, grade, integração da partida).
- Web: preset sem threads; GitHub Actions testa e publica no Pages a cada push na `main`.
- Menu mostra versão + hash do commit. Hook `SessionStart` para sessões na nuvem.
- Cache-busting: `index.pck?v=<commit>` no `index.html` (Pages tem cache de 10 min).
- Contexto para o Claude: `CLAUDE.md`, docs, subagentes e comandos.

## Falta / próximos passos
1. **Definir o tema** (ver `docs/GDD.md`) e trocar arte/textos.
2. Medir FPS num celular real no minuto 8–10 (overlay 3 dedos) e ajustar se < 60.
3. Sons reais (pontos já existem em `autoload/audio.gd`).
4. Balancear com partidas reais (agente `balance-designer`).
5. Mais conteúdo: armas, inimigos, chefe/baú.

## Bugs / riscos conhecidos
- Performance no celular ainda **não medida** (PC: ~1,3 ms/frame para 400 inimigos no `EnemyManager`).
- Hook da nuvem ainda não testado numa sessão remota real.
- Textos da UI sem acentos (ex.: "Nivel", "Voce sobreviveu!").
- Gemas não se fundem: muitas gemas paradas longe do jogador podem acumular no fim da partida.
