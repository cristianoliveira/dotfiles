#!/usr/bin/env bash
set -euo pipefail

# Ignore project Python paths; only this package owns the installation policy.
python3 -I "$(dirname "${BASH_SOURCE[0]}")/install.py"
