#!/usr/bin/env bash
# Roda todos os testes GUT em modo headless (sem janela).
# Uso: ./scripts/test.sh            (todos os testes)
#      ./scripts/test.sh -gtest=res://tests/test_pool.gd   (um arquivo)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# Importa os assets e registra as class_name antes de testar.
./scripts/godot.sh --headless --import >/dev/null 2>&1 || true
./scripts/godot.sh --headless -s addons/gut/gut_cmdln.gd "$@"
