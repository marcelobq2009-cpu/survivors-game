# GDD — Documento de design (curto)

## Tema: A DEFINIR
Ainda sem história/ambientação. Toda arte é placeholder (formas geométricas) e todo nome no código
é genérico. Quando o tema for escolhido: trocar texturas/cores nos `.tres` de `data/`, textos da UI
e `display_name`/`title` dos recursos — sem mexer na lógica.

Ideias para decidir o tema: (anotar aqui)
- ...

## Pitch
Partida de ~10 minutos, sobrevivendo a ondas crescentes de inimigos. O jogador só se move;
as armas atacam sozinhas. Ao subir de nível, escolhe 1 entre 3 upgrades e monta uma "build".

## Loop principal
1. Mover (teclado ou joystick flutuante) para fugir/posicionar.
2. Armas automáticas matam inimigos → caem gemas de XP.
3. Coletar gemas (ímã ao chegar perto) → subir de nível.
4. Level-up pausa e mostra 3 cartas (nova arma, +dano, +velocidade, +área, +vida...).
5. Dificuldade sobe a cada minuto (mais inimigos, novos tipos, mais vida).
6. Fim: morrer (game over) ou sobreviver até 10:00 (vitória). Recorde salvo.

## Sistemas atuais (protótipo)
| Sistema | Estado |
|---|---|
| Inimigos | 3 tipos: básico (círculo), rápido (triângulo), tanque (quadrado) |
| Armas | Projétil (mira no mais próximo) e Aura (dano em área ao redor) |
| Upgrades | 14 cartas: 1 nova arma, 6 de arma, 6 do jogador, 1 cura (reserva) |
| Ondas | 10 ondas em 10 min (`data/waves/main_timeline.tres`) |
| Progressão | Curva de XP em `data/player/xp_curve.tres` |
| Meta | Só recorde (tempo e abates) |

## Controles
- PC: WASD/setas, Esc pausa, F3 debug.
- Celular: arrastar na metade de baixo = joystick; botão II = pausa; 3 dedos = debug.

## Ideias para depois (não implementado)
- Mais armas (bumerangue, raio em cadeia, minas), evolução de arma no nível máximo.
- Baús/chefe a cada X minutos; inimigos que atiram.
- Meta-progressão entre partidas (moedas, upgrades permanentes), personagens.
- Áudio e arte reais quando o tema existir.
