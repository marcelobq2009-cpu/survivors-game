---
description: Cria um novo tipo de zumbi/inimigo (.tres) e o coloca nas ondas
argument-hint: <descrição, ex. "lento e muito resistente, aparece a partir do minuto 5">
---

Crie um inimigo novo a partir de: "$ARGUMENTS". Se faltar informação, escolha valores razoáveis
e explique.

Padrão do projeto (leia só estes arquivos):
- Modelo: `data/enemies/zombie_walker.tres` e a classe `game/enemies/enemy_data.gd`.
- Ondas: `data/waves/rio_timeline.tres`.

Passos:
1. Crie `data/enemies/<id>.tres` (id em inglês, snake_case) copiando a estrutura do modelo:
   `id`, `display_name` (português), stats em METROS (`speed` ~1–3 m/s, `radius` ~0.3–0.7),
   `xp_value`, drops (`gold_chance`, `chest_chance`) e visual (`body_color`, `skin_color`,
   `model_scale`) bem diferente dos zumbis existentes. Sem `mesh` = modelo 3D placeholder.
   Comportamentos prontos: `behavior` = CHASE (0), EXPLODER (1), CHARGER (2).
2. Adicione-o (ExtResource + entrada no array `enemies`) nas ondas certas da timeline.
3. Se o comportamento pedido NÃO couber no que existe (ex.: atirar), pare e explique o que
   precisa de código (novo valor em `EnemyData.Behavior` + caso no `EnemyManager`; tarefa do `gameplay-dev`).
4. Rode os testes; atualize `docs/PROGRESS.md`; resuma (stats escolhidos e em que minuto aparece).
