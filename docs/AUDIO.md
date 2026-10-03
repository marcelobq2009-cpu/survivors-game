# Áudio

Todo som passa pelo autoload `Audio` (`autoload/audio.gd`). Hoje **todos os sons e músicas são
gerados por código** (licença própria). Para trocar por arquivos reais, basta colocar o arquivo
na pasta certa: o jogo usa o arquivo no lugar do som gerado.

## Peças
| Arquivo | Papel |
|---|---|
| `autoload/audio.gd` | AudioManager: vozes, prioridade, loops, música em camadas, ambiente, canais, ducking |
| `game/audio/sound_catalog.gd` | **Lista de todos os sons** (id, canal, prioridade, variações, volume, cooldown, limite, posicional, loop, legenda) |
| `game/audio/sfx_recipes.gd` + `synth.gd` | "Receitas" que sintetizam cada efeito |
| `game/audio/music_composer.gd` | Compõe as trilhas (camadas sincronizadas) e as vinhetas |
| `game/audio/game_audio_director.gd` | Na partida: escuta os `Events` e decide o que tocar (intensidade, chefes, vozes dos zumbis, ambiente por região, coração) |

## Canais (volumes salvos nas Configurações)
`Music`, `SFX`, `Ambience`, `Zombies`, `UI`, `Bosses`, `Alerts` → `Master` (com limitador).
Sons posicionais saem por `<canal>_L` / `<canal>_R` (panner) quando vêm da esquerda/direita da tela.

## Regras de performance
- Vozes fixas e reaproveitadas: 12 efeitos, 16 posicionais, 5 de interface. Sem voz livre, um
  som de prioridade maior rouba a de prioridade menor.
- Cada som tem cooldown e máximo de cópias simultâneas (evita "metralhar").
- **Não usar `AudioStreamPlayer3D`**: cada um tocando custava ~20 ms por frame de física no
  Godot 4.7. O som posicional é feito à mão (volume pela distância + lado por bus).
- Sons gerados ficam em cache em `user://audio_cache/v3/` (troque a versão se mudar uma receita).
- Carregamento (`Audio.prepare_for_game`): só efeitos + música do modo escolhido. Chefe, outras
  trilhas e vinhetas são compostos em segundo plano durante a partida (3 ms por frame).

## Trocar por arquivos reais
Nome: `<id>_NN.ogg` (ou `.wav`/`.mp3`), `NN` = variação (01, 02…). Ids em `sound_catalog.gd`.
| Canal | Pasta |
|---|---|
| SFX (armas, impactos, XP) | `assets/audio/sfx/` |
| Zombies | `assets/audio/sfx/zombies/` |
| UI | `assets/audio/sfx/ui/` |
| Bosses | `assets/audio/sfx/bosses/` |
| Alerts | `assets/audio/sfx/alerts/` |
| Ambience | `assets/audio/ambient/` |
| Música | `assets/audio/music/<trilha>_NN.ogg` (NN = camada; todas com o mesmo tamanho) e `<vinheta>_01.ogg` |

Trilhas: `menu`, `loading`, `music_game` (4 camadas), `ranked`, `boss`. Vinhetas: `victory`,
`defeat`, `boss_intro`, `boss_defeated`. Loops em `.ogg`: marque "Loop" na importação.
**Registre todo arquivo externo em `assets/CREDITS.md`** (só CC0/CC-BY ou licença comprada).

## Adicionar um som novo
1. `_add(...)` em `sound_catalog.gd` com uma receita em `sfx_recipes.gd` (ou só o arquivo).
2. Tocar: `Audio.play(&"id")`, `Audio.play_at(&"id", pos)` ou `Audio.start_loop(&"chave", &"id", 0.0, pos)`.
3. O teste `tests/test_audio.gd` confere que todo som do catálogo gera áudio válido.
