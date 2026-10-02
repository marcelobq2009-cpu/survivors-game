#!/usr/bin/env bash
# Hook SessionStart (.claude/settings.json). So age em sessoes do Claude Code
# na nuvem (CLAUDE_CODE_REMOTE=true): instala o Godot se ele nao existir.
# Localmente (Windows) nao faz nada.
set -euo pipefail

if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" ]]; then
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if ! ls tools/godot/Godot_v*_linux.x86_64 >/dev/null 2>&1; then
  ./scripts/setup-godot.sh >/dev/null
fi
# Importa o projeto para os testes rodarem rapido.
./scripts/godot.sh --headless --import >/dev/null 2>&1 || true
echo "Godot pronto em tools/godot/ (use ./scripts/test.sh para testar)."
