# BetterTouchTool Setup

## Prerequisite

BetterTouchTool 6.594 is installed at `/Applications/BetterTouchTool.app` on the
target Mac. Launch it once and grant the permissions requested by the
application. The project does not use private Apple Touch Bar frameworks;
BetterTouchTool owns the Touch Bar item.

## Create The Widget

1. Run `scripts/install.sh` from this repository.
2. Open BetterTouchTool and select the Touch Bar configuration section.
3. Add an application-specific configuration for **Codex**.
4. Add the same configuration for **Terminal** and **iTerm2** if those apps are
   used for Codex CLI.
5. Add a Shell Script Widget (the label may be "Run Shell Script and Show Return
   Value" depending on the installed BetterTouchTool version).
6. Set the script to:

   ```bash
   "$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage"
   ```

7. Set periodic refresh to **60 seconds**.
8. Enable multiline text, use a compact system font, and allow enough width for
   approximately 32 Chinese characters. Use a black background and white text.

The command performs a second activation check. It emits no content unless the
frontmost app is Codex, or the active Terminal/iTerm TTY has `codex` as its
foreground process. This prevents an unrelated background Codex process from
showing the widget.

## Expected Output

```text
5小时 ▰▰▰▰▱ 81%  4时56分
本周 ▰▰▰▰▰ 97%  周日
```

The actual percentages and reset labels come from the local Codex app-server.
A trailing `·` means a cached value is being shown after a transient failure.

## Version-specific Preset

This repository intentionally does not ship an unverified JSON preset. BTT 6.594
requires the Socket Server to be enabled interactively before its bundled
`bttcli` can modify configuration. After the widget is configured and verified,
export the application-specific group if a reusable preset is needed.

## Verification

Run the bridge directly before configuring the widget:

```bash
"$HOME/Library/Application Support/CodexTouchBar/bin/codex-usage" --force
```

It should print two rows. Then verify that the normal command is empty outside
Codex, appears while Codex is frontmost, appears while Codex CLI owns the active
terminal TTY, and disappears after the terminal returns to the shell.
