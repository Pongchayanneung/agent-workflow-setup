# Per-tool support: what is verified and what is not

The rules, memory and `cap` registry are plain files, so any agent that reads `AGENTS.md` gets them.
Hooks are different for each tool. This page says exactly how far each one was checked.

| Piece | Claude Code | Codex | Gemini CLI | Antigravity (`agy`) |
|---|---|---|---|---|
| Shared rules file | symlink at `~/.claude/CLAUDE.md` | symlink at `~/.codex/AGENTS.md` | symlink at `~/.gemini/GEMINI.md`, plus `context.fileName` | reads `AGENTS.md` natively (author's setup) |
| Memory notes (`~/.agent-workflow/memory/`) | read on request | read on request | read on request | read on request |
| `cap` registry | works | works | works | works |
| Task modes, gates, warm resume | hooks, **in daily use** | `hooks.json`, **experimental** | `settings.json` hooks via `gemini-wrap.sh`, **experimental** | not wired |
| WIP autosave | on `SessionEnd` | on `Stop` (idempotent) | cron/launchd, see below | cron/launchd, see below |
| Compact nudge | yes | no | no | no |

## What "verified" means here

- **Claude Code:** the author runs these exact scripts every day. `install.sh` was also run in a
  throwaway `$HOME` with pre-existing settings, twice (second run changes nothing).
- **Codex and Gemini hooks:** each gate was fed Codex-shaped and Gemini-shaped JSON payloads on stdin
  and returned the right exit code (block = 2, allow = 0); the Gemini wrapper's output parsed as JSON.
  **They were not run inside a live Codex or Gemini session**, so field names such as the file-edit
  tool names (`apply_patch`, `write_file`, `replace`) come from documentation and are the first thing
  to check if a gate never fires.
- **Antigravity:** only the shared rules file is relied on. Gemini CLI's own docs state it was replaced
  by Antigravity CLI on 18 June 2026; its hook system was not checked.

## Codex notes

- Global rules: `~/.codex/AGENTS.md`; project rules are read from the repo root downward.
- Hooks live in `~/.codex/hooks.json`. Third-party guides say they sit behind a feature flag
  (`features.codex_hooks = true` in `~/.codex/config.toml`, or `codex -c features.codex_hooks=true`)
  and need a recent CLI. Confirm against OpenAI's current Codex docs before relying on them.
- Codex has no `SessionEnd` event in those guides, so autosave runs on `Stop`. It is idempotent:
  an unchanged tree creates no new snapshot.

## Gemini CLI notes

- Global rules: `~/.gemini/GEMINI.md`; `@file.md` imports work inside it. `install.sh` also sets
  `context.fileName` to `["AGENTS.md", "GEMINI.md"]` so project `AGENTS.md` files are read too.
- Hook stdout must be one JSON object. `core/hooks/gemini-wrap.sh <script>` runs a shared script and
  re-wraps its text output as `hookSpecificOutput.additionalContext`; exit code 2 still blocks.
- Hook timeouts are in milliseconds in Gemini (seconds in Claude and Codex); the adapter file handles it.

## Autosave without hooks (any tool)

`wip_autosave.sh` only needs git. Run it on a schedule:

```bash
# cron, every 15 minutes
*/15 * * * * bash "$HOME/.agent-workflow/hooks/wip_autosave.sh"
```

On macOS, a `launchd` agent with `StartInterval` 900 does the same.
