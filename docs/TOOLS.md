# Per-tool support: what is verified and what is not

The rules, memory and `cap` registry are plain files, so any agent that reads `AGENTS.md` gets them.
Hooks are different for each tool. This page says exactly how far each one was checked.

| Piece | Claude Code | Codex | Gemini CLI | Antigravity (`agy`) |
|---|---|---|---|---|
| Shared rules file | symlink at `~/.claude/CLAUDE.md` | symlink at `~/.codex/AGENTS.md` | symlink at `~/.gemini/GEMINI.md`, plus `context.fileName` | symlink at `~/.agents/AGENTS.md` (**loaded, tested live**) |
| Memory notes (`~/.agent-workflow/memory/`) | read on request | read on request | read on request | read on request |
| `cap` registry | works | works | works | works |
| Gates (smoke-test, capability) | hooks, **in daily use** | `hooks.json`, **experimental** | `settings.json` via `gemini-wrap.sh`, **experimental** | `~/.agents/hooks.json` via `agy-wrap.sh` (**block and allow tested live**) |
| Task modes, warm resume (need session or prompt hooks) | yes | yes (experimental) | yes (experimental) | **no**: agy has no such hook events. Tell it to run `warm_resume.sh` at session start |
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
- **Antigravity (agy):** tested against a real agy session (CLI from this machine), using canary tokens:
  - `~/.agents/AGENTS.md` is loaded as global rules, and so is an `AGENTS.md` at the workspace root.
    `~/.agents/rules/*.md` was **not** picked up in the same test.
  - `~/.agents/hooks.json` is loaded globally (so is `<workspace>/.agents/hooks.json`).
  - Hook events: `PreToolUse` and `PostToolUse` work. `SessionStart` was rejected when the file was parsed;
    `UserPromptSubmit`, `Stop` and `SessionEnd` were not isolated, so assume they do not exist.
  - Each hook group may hold only one event; several events in one named group fail to parse.
  - Payload is agy's own (`conversationId`, `toolCall.name`, `toolCall.args`, `workspacePaths`), not
    Claude's. Tool names seen: `view_file`, `write_to_file` (args `TargetFile`, `CodeContent`),
    `run_command` (arg `CommandLine`). `agy-wrap.sh` translates to the shared scripts' format.
  - A hook blocks by printing `{"decision":"deny","reason":"..."}` on stdout. End to end: with an
    untested hook referenced in a file edit, agy was denied and quoted the gate's reason; after
    `smoketest.sh`, the same edit went through.
  - Not checked: other edit tool names (`replace_file_content` etc. are guessed to carry `TargetFile`;
    the wrapper falls back to joining all string args), and agy plugins.
  - Gemini CLI's own docs say it was replaced by Antigravity CLI on 18 June 2026, so if you are on agy
    use the agy column, not the Gemini one.

## Antigravity notes

- Plain-text hook output has no documented channel in agy, so `agy-wrap.sh` drops it; only blocks matter.
- Add this line to your own habits: at the start of a session say "run `bash ~/.agent-workflow/hooks/warm_resume.sh`".
  `core/templates/AGENTS.md.template` already tells the agent to do it when no hook printed the block.

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
