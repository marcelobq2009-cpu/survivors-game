---
description: Cria uma nova arma (dados + upgrade para desbloquear; código só se o comportamento for novo)
argument-hint: <descrição, ex. "dispara 3 projéteis lentos que atravessam tudo">
---

Crie uma arma nova a partir de: "$ARGUMENTS".

Leia só: `docs/ARCHITECTURE.md` (seção "Como adicionar…"), `game/weapons/weapon.gd`,
`game/weapons/weapon_data.gd`, um `.tres` de `data/weapons/` e um de `data/upgrades/`.

1. Decida: dá para fazer com um comportamento existente só mudando números?
   `projectile_weapon.tscn` (tiro no mais próximo, leque), `melee_weapon.tscn` (golpe em arco),
   `thrown_weapon.tscn` (arremesso que explode), `aura_weapon.tscn` (área em volta). Se sim, vá ao passo 3.
2. Comportamento novo: crie `game/weapons/<nome>_weapon.gd` (`class_name`, `extends Weapon`,
   tipado, comentários em português, implementa `attack()`; alvos via `enemies.grid`, dano via
   `hit()`, disparos via `projectiles` — nada de um nó por projétil) e a cena `.tscn` (raiz Node3D).
   Escreva teste GUT se houver lógica pura nova.
3. Crie `data/weapons/<id>.tres` (`WeaponData`: `scene`, stats em metros, `color`, `projectile_visual`, `sound_id`).
4. Crie `data/upgrades/unlock_<id>.tres` (`kind = NEW_WEAPON`, `max_picks = 1`, `tag = "arma"`) e
   1–2 upgrades `WEAPON_STAT`. Sem o unlock a arma nunca aparece no jogo.
5. Rode os testes; atualize `docs/PROGRESS.md`; resuma o que criou e como testar.
