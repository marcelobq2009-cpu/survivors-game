---
description: Cria um novo tipo de inimigo (.tres) e o coloca nas ondas
argument-hint: <descrição, ex. "lento e muito resistente, aparece a partir do minuto 5">
---

Crie um inimigo novo a partir de: "$ARGUMENTS". Se faltar informação, escolha valores razoáveis
e explique.

Padrão do projeto (leia só estes arquivos):
- Modelo: `data/enemies/basic.tres` e a classe `game/enemies/enemy_data.gd`.
- Ondas: `data/waves/main_timeline.tres`.

Passos:
1. Crie `data/enemies/<id>.tres` (id em inglês, genérico, snake_case — sem tema) copiando a
   estrutura do modelo: `id`, `display_name`, stats, `radius`, `knockback_resistance`, `texture`
   (uma de `res://assets/sprites/placeholder/`: circle, square, triangle, diamond) e uma `color`
   bem diferente dos inimigos existentes. Não reutilize o `uid`/ids de ExtResource de outro arquivo
   de forma inconsistente; se gerar `uid`, use um novo ou omita a linha `uid=`.
2. Adicione-o (ExtResource + entrada no array `enemies`) nas ondas certas da timeline.
3. Se o comportamento pedido NÃO couber nos stats existentes (ex.: atirar), pare e explique o
   que precisa de código (tarefa para o `gameplay-dev`).
4. Rode os testes; atualize `docs/PROGRESS.md`; resuma (stats escolhidos e em que minuto aparece).
