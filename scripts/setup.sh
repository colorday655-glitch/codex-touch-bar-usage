#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
btt_app="/Applications/BetterTouchTool.app"
bttcli="$btt_app/Contents/SharedSupport/bin/bttcli"
preset="$repo_root/bettertouchtool/CodexTouchBarUsage.bttpreset"
widget_uuid="68EF131A-8125-4A55-8724-D422EA24C6AE"

"$repo_root/scripts/install.sh"

if [[ ! -x "$bttcli" ]]; then
  printf 'BetterTouchTool was not found at %s\n' "$btt_app" >&2
  printf 'Import %s into BetterTouchTool manually after installing the app.\n' "$preset" >&2
  exit 1
fi

"$bttcli" import_preset path="$preset"
"$bttcli" refresh_widget uuid="$widget_uuid"

printf 'Setup complete.\n'
printf 'Open BetterTouchTool and enable the imported preset: Codex Touch Bar Usage\n'
printf 'If the widget is not visible yet, switch to ChatGPT.app and wait for the next refresh.\n'
