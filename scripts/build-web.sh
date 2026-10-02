#!/usr/bin/env bash
# Exporta o jogo para web em build/web/ (preset "Web", sem threads).
# Requer os templates: ./scripts/setup-godot.sh --with-templates
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Versao + hash do commit, mostrados no menu (game/build_info.gd nao vai pro git).
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then COMMIT="${COMMIT}+"; fi
printf 'extends RefCounted\n## Gerado por scripts/build-web. Nao edite.\nconst COMMIT := "%s"\n' "$COMMIT" > game/build_info.gd

mkdir -p build/web
touch build/.gdignore
./scripts/godot.sh --headless --import >/dev/null 2>&1 || true
./scripts/godot.sh --headless --export-release "Web" build/web/index.html
echo "Build web pronta em build/web/ (commit $COMMIT)"
