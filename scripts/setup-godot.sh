#!/usr/bin/env bash
# Baixa o Godot (Linux x86_64) para tools/godot/ — usado pelo CI e pela nuvem.
# Uso: ./scripts/setup-godot.sh                  (so o binario, para testes)
#      ./scripts/setup-godot.sh --with-templates (tambem templates web, para build)
set -euo pipefail

GODOT_VERSION="4.7.2"
TAG="${GODOT_VERSION}-stable"
BASE="https://github.com/godotengine/godot/releases/download/${TAG}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/tools/godot"
BIN="$DIR/Godot_v${TAG}_linux.x86_64"
TPL_DIR="$DIR/editor_data/export_templates/${GODOT_VERSION}.stable"

mkdir -p "$DIR"
touch "$ROOT/tools/.gdignore"  # O Godot nao deve importar nada de tools/.
touch "$DIR/._sc_"             # Modo autocontido: dados do editor ficam aqui.

if [[ ! -x "$BIN" ]]; then
  echo "Baixando Godot ${TAG} (Linux)..."
  curl -fsSL -o "$DIR/godot.zip" "$BASE/Godot_v${TAG}_linux.x86_64.zip"
  unzip -q -o "$DIR/godot.zip" -d "$DIR"
  rm "$DIR/godot.zip"
  chmod +x "$BIN"
fi

if [[ "${1:-}" == "--with-templates" && ! -f "$TPL_DIR/web_nothreads_release.zip" ]]; then
  echo "Baixando export templates (~1.2 GB, so os de web sao mantidos)..."
  mkdir -p "$TPL_DIR"
  curl -fsSL -o "$DIR/templates.tpz" "$BASE/Godot_v${TAG}_export_templates.tpz"
  unzip -q -o -j "$DIR/templates.tpz" "templates/web*" "templates/version.txt" -d "$TPL_DIR"
  rm "$DIR/templates.tpz"
fi

"$BIN" --headless --version
