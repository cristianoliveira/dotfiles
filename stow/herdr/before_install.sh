#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install.py"

if [ "${1:-}" = "--prepare" ]; then
  python3 -I "$INSTALLER" --prepare
  exit 0
fi

if [ "${HERDR_DEV_PREPARED:-false}" != "true" ]; then
  python3 -I "$INSTALLER" --prepare
fi

python3 -I "$INSTALLER"
