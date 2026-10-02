#!/usr/bin/env bash
# Abre o jogo (menu inicial). Ex.: ./scripts/run.sh res://game/world/world.tscn
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/godot.sh" --path "$ROOT" "$@"
