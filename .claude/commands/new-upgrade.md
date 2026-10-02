---
description: Cria uma nova carta de upgrade (.tres em data/upgrades/)
argument-hint: <descrição, ex. "+15% de velocidade dos projéteis, até 3 vezes">
---

Crie um upgrade a partir de: "$ARGUMENTS".

Leia só: `game/upgrades/upgrade_data.gd`, um `.tres` parecido em `data/upgrades/` e, se o stat for
de arma, o `.tres` da arma em `data/weapons/`.

1. Escolha `kind`: NEW_WEAPON (0) | WEAPON_STAT (1) | PLAYER_STAT (2) | HEAL (3).
2. `stat` deve ser o nome EXATO de uma variável existente:
   - jogador (`game/player/player_stats.gd`): max_health, move_speed, pickup_radius,
     damage_mult, area_mult, cooldown_mult;
   - arma (`game/weapons/weapon.gd`): damage, cooldown, area, projectile_speed,
     projectile_count, pierce, lifetime, target_range.
   Se o stat não existir, pare e explique o que precisa de código.
3. Crie `data/upgrades/<id>.tres` com `id` único, `title` e `description` curtos em português
   (cabem num botão de celular), `value`, `is_multiplier`, `max_picks`, `weight`, `color`.
   Lembre: cooldown menor = mais rápido (use multiplicador < 1).
4. Rode os testes (um deles valida todos os upgrades da pasta); atualize `docs/PROGRESS.md`.
