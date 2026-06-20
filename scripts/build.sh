#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

swift build -c release
binary_path="$(swift build -c release --show-bin-path)/codex-usage"
test -x "$binary_path"
printf 'Built %s\n' "$binary_path"

