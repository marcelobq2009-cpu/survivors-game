---
description: Cria uma nova arma (dados + upgrade para desbloquear; código só se o comportamento for novo)
argument-hint: <descrição, ex. "dispara 3 projéteis lentos que atravessam tudo">
---

Crie uma arma nova a partir de: "$ARGUMENTS".

Leia só: `docs/ARCHITECTURE.md` (seção "Como adicionar... Arma"), `game/weapons/weapon.gd`,
`game/weapons/weapon_data.gd`, um `.tres` de `data/weapons/` e um de `data/upgrades/`.

1. Decida: dá para fazer com um comportamento existente (`projectile_weapon.tscn` ou
   `aura_weapon.tscn`) só mudando stats? Se sim, pule para o passo 3.
2. Comportamento novo: crie `game/weapons/<nome>_weapon.gd` (`class_name`, `extends Weapon`,
   tipado, comentários em português, implementa `attack()`, usa `enemies.grid` para alvos e `Pool`
   para qualquer nó criado em massa) e `game/weapons/<nome>_weapon.tscn` com esse script.
   Escreva um teste GUT se houver lógica pura nova.
3. Crie `data/weapons/<id>.tres` (`WeaponData`, `scene` apontando para a cena certa, textura de
   `assets/sprites/placeholder/`, cor própria).
4. Crie `data/upgrades/unlock_<id>.tres` (`kind = NEW_WEAPON`, `max_picks = 1`) e 1–2 upgrades
   `WEAPON_STAT` para ela (ex.: dano, área). Sem isso a arma nunca aparece no jogo.
5. Rode os testes; atualize `docs/PROGRESS.md`; resuma o que criou e como testar.
