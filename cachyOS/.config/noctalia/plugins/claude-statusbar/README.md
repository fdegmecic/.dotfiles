# Claude Code Status

A Noctalia bar plugin that shows the live state of your Claude Code sessions —
aggregated across every running session — with a detail panel.

The bar widget shows a single icon coloured by the most attention-worthy state:

| State | icon | colour | meaning |
|-------|------|--------|---------|
| waiting | `bell-ringing` | error (red) | a session needs permission / your input |
| compacting | `refresh` | tertiary | a session is compacting its context |
| working | `loader` | primary | a session is thinking / running tools |
| done | `circle-check` | tertiary | finished, awaiting your next prompt |
| idle | `robot` | secondary | nothing active |

When two or more sessions are live the icon also shows a count. Left-click opens
a panel listing each session (name, directory, state, elapsed time); right-click
opens settings.

## How it works

Claude Code fires lifecycle **hooks**; a small companion binary records each
session's state to `~/.local/state/claude-statusbar/<session_id>.json`, and the
plugin runs that binary in `watch` mode so the bar updates the instant a session
changes state (push, not poll).

### Dependencies (set up outside this plugin)

1. **The `claude-statusbar` binary** on `$PATH` (or set `binaryPath` in settings).
   Source: `tools/claude-statusbar` in the dotfiles repo (`cargo build --release`,
   symlinked to `~/.local/bin/claude-statusbar`).
2. **Claude Code hooks** in `~/.claude/settings.json` mapping events to states:
   `SessionStart`→idle, `UserPromptSubmit`/`PreToolUse`/`PostToolUse`→working,
   `Notification`→waiting, `PreCompact`→compacting, `Stop`→done, `SessionEnd`→end.

## Settings

- **Icon / count colour override** — leave at default to colour by state.
- **Show count for a single session** — show the number even with one session.
- **Binary path** — path to the `claude-statusbar` binary.
