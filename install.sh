#!/usr/bin/env bash
# Bootstrap enodios — clone or refresh, then run enodios install.
set -euo pipefail

REPO="${ENODIOS_REPO:-https://github.com/DataKnifeAI/enodios.git}"
DIR="${ENODIOS_DIR:-$HOME/.local/share/enodios/src}"

if [[ -d "$DIR/.git" ]]; then
  git -C "$DIR" pull --ff-only
else
  mkdir -p "$(dirname "$DIR")"
  git clone "$REPO" "$DIR"
fi

exec "$DIR/bin/enodios" install
