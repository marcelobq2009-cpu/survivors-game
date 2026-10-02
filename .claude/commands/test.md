---
description: Roda os testes GUT (headless) e resume o resultado
argument-hint: [arquivo de teste opcional, ex. test_pool]
---

Rode os testes do projeto sem ler código antes:
- Windows: `.\scripts\test.ps1` | Linux/nuvem: `./scripts/test.sh`
- Se recebeu argumento ("$ARGUMENTS"), rode só esse arquivo: `-gtest=res://tests/<arquivo>.gd`
  (acrescente `test_` e `.gd` se faltar).

Responda em português, curto:
- ✅/❌ e totais (passou X de Y, tempo).
- Para cada falha: teste, mensagem, arquivo:linha provável. Só então leia o código necessário
  para sugerir a causa (não corrija sem eu pedir).
- Ignore o aviso esperado "Stat desconhecido: does_not_exist" (vem de um teste).
