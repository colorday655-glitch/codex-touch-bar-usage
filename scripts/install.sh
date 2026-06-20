#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="$HOME/Library/Application Support/CodexTouchBar/bin"

"$repo_root/scripts/build.sh"
binary_path="$(cd "$repo_root" && swift build -c release --show-bin-path)/codex-usage"
mkdir -p "$install_dir"
install -m 755 "$binary_path" "$install_dir/codex-usage"

printf 'Installed %s\n' "$install_dir/codex-usage"
printf 'BetterTouchTool command:\n"%s"\n' "$install_dir/codex-usage"

