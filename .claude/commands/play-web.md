---
description: Testa, faz commit + push na main e devolve o link para jogar no celular
argument-hint: [mensagem de commit opcional]
---

Objetivo: colocar a versão atual no ar para eu testar no celular.

1. Rode os testes (`./scripts/test.sh` ou `.\scripts\test.ps1`). Se falharem, PARE e mostre o erro.
2. `git status`. Se houver mudanças: faça commit pequeno em português (use "$ARGUMENTS" como
   mensagem se fornecida; senão, escreva uma clara). Não commite nada de `tools/`, `build/`, `.godot/`.
3. `git push origin main` (se estiver em outra branch, pergunte antes).
4. Pegue o hash curto (`git rev-parse --short HEAD`) e acompanhe o workflow:
   `gh run list -L 1` e `gh run watch <id> --exit-status` (leva ~1–3 min).
5. Responda curto:
   - Link: https://marcelobq2009-cpu.github.io/survivors-game/
   - Hash esperado no menu: `vX.Y.Z (<hash>)` — se aparecer o antigo, recarregar a página.
   - Status do deploy (✅/❌; se falhou, a etapa e o erro principal do log).
