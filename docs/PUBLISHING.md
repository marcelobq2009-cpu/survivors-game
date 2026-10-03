# Publicação: checklist e revisão

## Estado atual (revisado em 2026-10-03)
| Item | Situação |
|---|---|
| Nome | "Apocalipse Brasil" (`project.godot` › `application/config/name`). **Provisório**: pesquisar marca registrada e nomes iguais nas lojas antes de lançar |
| Versão | `application/config/version` (0.3.0). Suba a cada envio para loja |
| Ícone | `assets/icon.png` (gerado por `scripts/dev/make_icon.gd`, original) |
| Arte, sons, música | 100% originais, gerados por código (ver `assets/CREDITS.md`) |
| Licenças de terceiros | Godot Engine (MIT): aviso completo em Configurações › Sobre o jogo. GUT só nos testes (não vai no jogo) |
| Marcas e lugares reais | Só nomes geográficos (Copacabana, Cristo Redentor, Pão de Açúcar) e formas genéricas. Não usar logotipos/marcas de empresas |
| Debug | Escondido na versão publicada. Abre só com o código secreto (7 toques na versão, no menu). Para a loja, se quiser tirar de vez: `data/config/game_config.tres` › `debug_mode = false` |

## Privacidade (texto-base para a política da loja)
- O jogo **não coleta nem envia dados pessoais**. Não há contas, anúncios, analytics nem compras.
- Fica salvo **só no aparelho** (`user://save.json`): progresso, configurações e o nome escolhido
  para o ranking. O ranking hoje é local (mock).
- Ao ligar um ranking online (provider HTTP), atualize a política: ele enviaria nome + pontuação.
- Google Play e App Store exigem um link de política de privacidade mesmo assim: publique este
  texto numa página (ex.: GitHub Pages) e preencha "Segurança dos dados" / "Privacy Nutrition Label"
  como "nenhum dado coletado".

## Classificação indicativa (sugestão, confirme no questionário da loja)
Violência fantasiosa contra zumbis, sem sangue realista, sem linguagem imprópria, sem compras.
Expectativa: **ClassInd 12** (Brasil) / **IARC 12** / **PEGI 12** / **ESRB T (Teen)**.
O resultado oficial vem do questionário IARC dentro do Google Play Console.

## Antes de enviar para uma loja
1. Testar em pelo menos 1 Android fraco e 1 médio (FPS no minuto 20+, joystick, textos legíveis).
2. Configurar o export Android/iOS (`docs/MOBILE.md`), ícones adaptativos e splash.
3. `debug_mode = false` (opcional, ver acima) e subir a versão.
4. Rodar `scripts/test.ps1`, o robô (`tests/perf/playtest_bot.tscn`) e o estresse (`tests/perf/stress.tscn`).
5. Capturas de tela e vídeo (o tour visual `tests/perf/ui_tour.tscn` ajuda), descrição e política de privacidade.
6. Conferir `assets/CREDITS.md`: todo asset externo com licença compatível e atribuição no jogo.
