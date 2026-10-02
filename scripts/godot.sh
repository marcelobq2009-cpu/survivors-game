#!/usr/bin/env bash
# Chama o Godot local (tools/godot/) repassando todos os argumentos.
# Uso: ./scripts/godot.sh --version
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$(ls "$ROOT"/tools/godot/Godot_v*_linux.x86_64 2>/dev/null | head -n 1 || true)"
if [[ -z "$BIN" ]]; then
  echo "Godot nao encontrado em tools/godot/. Rode scripts/setup-godot.sh" >&2
  exit 1
fi
exec "$BIN" "$@"
