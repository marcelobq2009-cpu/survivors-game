# GDD — Apocalipse Brasil (nome provisório)

## Tema
Apocalipse zumbi no Brasil. O jogador controla sobreviventes que enfrentam hordas cada vez maiores,
evolui durante a partida, monta combinações de armas/passivas e desbloqueia personagens e mapas.
Identidade brasileira forte. **Capítulo 1: Rio de Janeiro** (Copacabana, morros, Cristo, Pão de
Açúcar). Próximos: São Paulo (já jogável após desbloqueio), Salvador (em breve)…

## Direção visual
Survivor-like **3D com câmera isométrica/top-down** (referência de perspectiva: Project Zomboid —
sem copiar arte/UI). Cidade densa vista de cima, clima de fim de tarde enfumaçado. Hoje tudo é
placeholder 3D gerado por código (formas simples com cores); a arquitetura permite trocar por
modelos reais sem mexer na lógica.

## Loop
Explorar → enfrentar zumbis → matar → XP → subir de nível → escolher melhoria → ficar mais forte →
horda maior → combinações/evolução → chefe/evento → sobreviver ou morrer → recompensas →
desbloqueios → nova partida.

## Modos
- **Normal**: 30 min (`Config.game.normal_match_duration`). Vencer = recompensas + desbloqueios.
- **Ranqueado**: sem limite. Dificuldade cresce para sempre (overtime acelera). Pontuação =
  tempo + abates + nível + chefes. Ranking (mock local hoje).

## Conteúdo do MVP
| Tipo | Itens |
|---|---|
| Personagens | Sobrevivente (livre), Militar (vencer o Rio), Médica (derrotar 1 chefe) |
| Mapas | Rio de Janeiro (livre), São Paulo (vencer o Rio), Salvador (em breve) |
| Armas | Pistola, Espingarda, Metralhadora, Facão, Molotov, Gás Lacrimogêneo; evolução: Pistola Rajada |
| Zumbis | Comum, Corredor, Brutamontes, Inchado (explode), elites dourados |
| Chefes | Colosso e Mutante (investida), a cada 5 min |
| Upgrades | ~35 cartas: novas armas, melhorias por arma, passivas (dano, crítico, defesa, utilidade), evolução, cura, ouro |
| Conquistas | Primeira Sobrevivência, Sobreviveu 30 Minutos, 10.000 Zumbis, Matou um Chefe, Sobrevivente do Rio |

## Builds (exemplos)
- Dano + cadência + área + projéteis (Munição Reforçada, Mão Rápida, Explosivos, Carregador Extra)
- Crítico (Mira Treinada + Tiro Certeiro) → evolução da Pistola
- Defesa (Colete + Proteção + Kit de Primeiros Socorros)

## Controles
- Celular (paisagem): arrastar no lado esquerdo = joystick; ataque automático; botão II = pausa;
  3 dedos = overlay de FPS.
- PC: WASD/setas, Esc pausa, F3 overlay.

## Ideias futuras (não implementado)
Habilidades ativas por personagem (campo já existe), skins, melhorias permanentes com ouro,
missões diárias, eventos especiais (chuva, apagão), chefes com padrões, armas de fogo pesado,
veículos, novas cidades (SP, Salvador, Recife, Manaus), ranking online, música e arte finais.
