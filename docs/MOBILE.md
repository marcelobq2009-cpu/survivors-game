# Celular: testar hoje e publicar no futuro

## Hoje: jogar pelo navegador do celular
- Link: https://marcelobq2009-cpu.github.io/survivors-game/
- Todo push na `main` roda testes → exporta web → publica (~3 min). Acompanhe em *Actions* no GitHub.
- O menu mostra `vX.Y.Z (hash)`: confira se o hash bate com o último commit.
- Se não atualizar: recarregue a página (o navegador pode usar cache).
- Debug: escondido no site. Para abrir: toque 7 vezes na versão (canto do menu) → aparecem o botão DBG
  na partida e a seção Debug nas Configurações. Toque com 3 dedos mostra FPS e nº de zumbis.
- O jogo é em PAISAGEM. No Android, o primeiro toque pede tela cheia e trava na horizontal; no iPhone, gire o aparelho (aparece um aviso se estiver em pé).
- Celular fraco? Configurações › Gráficos: Qualidade Baixa, FPS 30, Partículas reduzidas, Zumbis reduzidos.
- Publicar em loja: checklist, privacidade e classificação em `docs/PUBLISHING.md`.

## Futuro: Android (APK/AAB) — NÃO configurado ainda
1. Instalar Android Studio (traz SDK + JDK 17). No Godot: *Editor > Editor Settings > Export > Android* → apontar SDK e JDK.
2. Baixar os export templates completos (Android vem no mesmo `.tpz`; hoje só extraímos os de web).
3. Criar keystore de release (`keytool -genkeypair ...`). **Nunca** commitar o keystore nem a senha (já estão no `.gitignore`).
4. *Project > Export > Add > Android*: package name (ex.: `com.seunome.apocalipsebrasil`), orientação paisagem, ícones.
5. Exportar `.apk` para testar (instalar via cabo/arquivo) e `.aab` para a Google Play (conta de dev: taxa única).
6. Opcional: job no GitHub Actions com o keystore em *Secrets*.

## Futuro: iOS — NÃO configurado ainda
- Exige **Mac com Xcode** e **conta Apple Developer** (anual).
- *Project > Export > iOS* gera um projeto Xcode → abrir no Mac → assinar → TestFlight / App Store.
- Alternativa sem Mac próprio: serviços de CI com macOS (ex.: GitHub Actions `macos-latest`) — mais avançado.

## Cuidados que já estão no projeto
- Renderer *Compatibility* (OpenGL ES 3 / WebGL 2), roda em aparelhos fracos.
- Tela paisagem 1280x720, `canvas_items` + `expand` (adapta a telas mais largas); orientação `sensor_landscape`.
- Área segura (notch) aplicada no HUD em Android/iOS nativos (`ui/safe_area_container.gd`).
- Botões grandes (≥ 76 px de altura) e joystick flutuante no lado esquerdo.
