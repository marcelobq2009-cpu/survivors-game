# Progresso

_Última atualização: 2026-10-03_

## Pronto (v0.2.0 — primeira versão jogável do tema)
- **Tema**: apocalipse zumbi no Brasil, Capítulo 1 Rio de Janeiro. Nome provisório "Apocalipse Brasil".
- **3D isométrico** em paisagem: CameraRig (zoom, tremor, foco, independente do jogador),
  Rio gerado por código (prédios com caixa d'água, praças, carros/ônibus, barricadas, orla com
  calçadão de ondas, quiosques, palmeiras, morro com comunidade, Cristo, Pão de Açúcar).
- **Hordas**: zumbis como agentes de dados + MultiMesh; contornam prédios pela grade do mapa;
  4 tipos (Comum, Corredor, Brutamontes, Inchado explosivo), elites dourados, 2 chefes com investida.
- **Combate**: 6 armas (Pistola, Espingarda, Metralhadora, Facão, Molotov, Gás) + evolução
  (Pistola Rajada); crítico, armadura, regeneração; ~35 cartas de upgrade com builds.
- **Progressão**: XP/nível, baús, ouro; modo Normal 30 min; Ranqueado infinito com DifficultyDirector
  (vida, dano, velocidade, elites, chefes a cada 5 min, hordas, overtime).
- **Meta**: personagens (Sobrevivente, Militar, Médica), mapas (Rio, São Paulo, Salvador em breve),
  desbloqueios por requisitos, 5 conquistas, save local versionado, ranking mock com camada de API.
- **Interface**: menu, seleção Personagem › Mapa › Confirmar, galerias, ranking, conquistas,
  configurações (áudio, idioma, qualidade, vibração, notificações, restaurar), HUD, level-up,
  pausa (continuar/configurações/reiniciar/sair), resultado, tutorial da 1ª partida, aviso "gire o celular".
- **Feedback**: flash de dano, números (crítico amarelo), partículas, explosões, golpe, anel de
  level-up, avisos (chefe/horda/nova arma/último minuto), zoom no chefe, câmera lenta no fim,
  sons placeholder sintetizados.
- **Debug**: painel DBG (tempo, XP, ouro, zumbis, chefe, horda, matar todos, invencível,
  dificuldade, teleporte, ímã, baú, desbloquear, vencer), partidas curtas (Configurações), overlay F3/3 dedos.
- **Testes**: 77 testes GUT (lógica, save, ranking, dificuldade, integração 3D) + robô de playtest + teste de estresse + tour visual (`tests/perf/`).

## Medições (PC, headless)
- Estresse (minuto 25, 245–342 zumbis, 5 armas): física 3,2 ms/frame, desenho em lote 1,0 ms/frame, 409 nós.
- Robô (jogador médio, normal): nível 24 e ~2.500 abates aos 10 min; morreu no 2º chefe (10:16).
- Robô invencível (ranqueado 45 min): dificuldade 3,6x vida / 2,6x dano, 9 chefes, nível 67, física 3–6 ms.
- Estimativa celular intermediário: 3–5x mais lento → 30–60 FPS no pior momento (confirmar no aparelho).

## Falta / próximos passos
1. Testar no celular real (FPS no minuto 20+, conforto do joystick, legibilidade).
2. Arte 3D e sons definitivos (trocar mesh/model_scene/arquivos de áudio).
3. Balancear com partidas reais (agente `balance-designer` + robô de playtest).
4. Habilidade ativa dos personagens (campos já existem em `CharacterData`).
5. Uso do ouro (melhorias permanentes/loja) e ranking online (provider HTTP).

## Bugs / riscos conhecidos
- Música: só há pontos de música; sem arquivos, fica em silêncio.
- Idioma: só Português (Inglês aparece como "em breve").
- Zumbis contornam prédios por "deslizamento" (não é pathfinding completo): em becos podem enroscar.
- iPhone (Safari) não permite travar a tela em paisagem: o jogador precisa girar o aparelho.
