#!/bin/bash
set -euo pipefail

install_root="$HOME/Library/Application Support/CodexTouchBar"
cache_root="$HOME/Library/Caches/CodexTouchBar"

if [[ "$install_root" == "$HOME/Library/Application Support/CodexTouchBar" ]]; then
  rm -rf "$install_root"
fi
if [[ "$cache_root" == "$HOME/Library/Caches/CodexTouchBar" ]]; then
  rm -rf "$cache_root"
fi

printf 'Removed Codex Touch Bar files. BetterTouchTool was not changed.\n'

