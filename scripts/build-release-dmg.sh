#!/bin/bash
# Eski ad — birincil build script'ine yönlendirir.
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/build-dmg.sh"
