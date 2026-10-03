# Progresso

_Última atualização: 2026-10-03_

## Pronto (v0.3.0 — áudio completo e polimento)
- **Áudio** (tudo gerado por código, licença própria; ver `docs/AUDIO.md`): música dinâmica em
  camadas (menu, carregamento, partida com 4 níveis de intensidade, ranqueado, chefe) e vinhetas
  (vitória, derrota, chefe); ~60 efeitos com variações (armas, evolução, zumbis por tipo, alerta do
  Inchado, elites, chefes, XP em sequência, level-up, cartas por raridade, crítico, ouro, baú,
  recompensas); ambiente do Rio por região (cidade, orla, morro) + sons ocasionais.
  7 canais com volume salvo, som posicional leve, prioridade e limite de vozes, pausa abafa a música,
  acessibilidade (legendas, setas de ameaça, mono, reduzir sons intensos, aumentar alertas, música
  mais baixa no combate). Troca por arquivos reais sem mexer em código.
- **Visual**: prédios abrem um "buraco de visão" (o personagem nunca some), Rio mais reconhecível
  (guarda-sóis, postos, letreiros COPACABANA / AV. ATLÂNTICA, orelhões, bancas, ônibus, placas,
  Túnel Novo, Cristo, Pão de Açúcar), zumbis/elites/chefes com silhuetas distintas.
- **Jogo**: cartas com raridade, eventos (horda, suprimentos, zona tóxica), avisos de explosão e
  investida, causa da morte no resultado, loja de MELHORIAS permanentes com ouro (8 itens),
  rebalanceamento (robô de playtest), correção do "esconderijo" na grade e de level-ups múltiplos.
- **Configurações**: áudio por categoria, acessibilidade, FPS 30/60, partículas e quantidade de
  zumbis reduzidas, zoom da câmera, restaurar padrão, Sobre o jogo (licença do Godot).
- **Carregamento** com barra (mapa + áudio). **Save** seguro (.tmp + .bak).
- **Debug** escondido na versão publicada (7 toques na versão do menu para abrir).
- **Publicação**: ícone, créditos, privacidade e classificação sugerida em `docs/PUBLISHING.md`.

## Pronto antes (v0.2.0 — primeira versão jogável do tema)
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
- **Testes**: 94 testes GUT (lógica, save, ranking, dificuldade, integração 3D) + robô de playtest + teste de estresse + tour visual (`tests/perf/`).

## Medições (PC, headless)
- Estresse (minuto 25, ~245–300 zumbis, 5 armas, com áudio): física ~3,5 ms/frame, desenho em lote 1,25 ms/frame, ~470 nós.
- Lição: `AudioStreamPlayer3D` tocando custava ~20 ms/frame de física → trocado por som posicional próprio.
- Robô (normal, v0.3.0): VENCEU os 30 min — nível 45, 22.656 abates, 4 chefes, vida cheia desde o min 11;
  física média 4–6 ms (picos p95 ~15 ms em chefes/hordas). Pode estar fácil para quem desvia bem: validar com pessoas.
- Robô invencível (ranqueado 45 min): dificuldade 3,6x vida / 2,6x dano, 9 chefes, nível 67, física 3–6 ms.
- Estimativa celular intermediário: 3–5x mais lento → 30–60 FPS no pior momento (confirmar no aparelho).

## Falta / próximos passos
1. Testar no celular real (FPS no minuto 20+, conforto do joystick, legibilidade).
2. Arte 3D definitiva e, se quiser, sons/músicas gravados (basta colocar os arquivos, `docs/AUDIO.md`).
3. Balancear com partidas reais (agente `balance-designer` + robô de playtest).
4. Habilidade ativa dos personagens (campos já existem em `CharacterData`).
5. Ranking online (provider HTTP) e export Android/iOS (`docs/MOBILE.md`, `docs/PUBLISHING.md`).

## Bugs / riscos conhecidos
- Balanceamento: o robô vence com folga depois do min 10; humanos no celular devem sofrer mais (testar).
- Primeira abertura: os sons são gerados e guardados em cache (alguns segundos a mais no carregamento).
- Idioma: só Português (Inglês aparece como "em breve").
- Zumbis contornam prédios por "deslizamento" (não é pathfinding completo): em becos podem enroscar.
- iPhone (Safari) não permite travar a tela em paisagem: o jogador precisa girar o aparelho.
