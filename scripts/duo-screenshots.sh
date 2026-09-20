#!/bin/bash
# Thin wrapper kept for muscle memory: the real script is scripts/capture-screens.sh.
exec "$(dirname "$0")/capture-screens.sh" "$@"
