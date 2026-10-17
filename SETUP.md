# Agent: run this setup

You are a coding agent (Claude Code, Codex or Gemini/Antigravity), opened inside this repo by someone who
wants this workflow on their machine. Do the steps in order. Report what worked and what failed with the exact error; never continue
silently past a failure.

## 1. Mechanical install (no questions needed)

Run `bash install.sh` (add `--no-packages` if git, python3 and jq are already installed).
It detects which of `claude`, `codex`, `gemini`, `agy` are on PATH and wires only those; override with
`--tools claude,agy`. It is idempotent and backs up anything it replaces to
`~/.agent-workflow/backups/<timestamp>/`. It never logs in and never writes secrets.

## 2. Check for existing rules before writing anything

If any of `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.agents/AGENTS.md` already exists as a real
file (not a symlink), read it and **merge** its content into the new rules, do not overwrite. Show the
user a diff of what you would add and wait for a yes.

## 3. Interview (ask, do not guess)

Ask these in one short batch, wait for answers, and write down anything left unanswered as
`assumed: ...` instead of inventing it. Never ask for passwords, tokens or API keys.

| # | Ask | Goes into |
|---|---|---|
| 1 | What should I call you, and what do you do (role in one line)? | Profile |
| 2 | City and timezone (IANA name, e.g. `Asia/Bangkok`)? | Profile |
| 3 | Which language for replies, and which for code and docs? | Language |
| 4 | Which machine is this (OS)? Any other machine I should reach (name, how)? | Profile |
| 5 | GitHub username, and which email should outward mail default to? Is any account on this machine borrowed or shared? | Profile |
| 6 | Writing-style rules you care about (e.g. no em dashes, no filler)? | Language |
| 7 | Permission mode: ask-before-acting (recommended), accept-edits, or no-prompt (`bypassPermissions` / `--yolo`)? If they pick no-prompt, say once that nothing will gate destructive commands, then comply. | Approvals |
| 8 | Where do your git repos live? (feeds `CLAUDE_WIP_ROOTS` for the WIP autosave hook) | `~/.zshrc` or `~/.bashrc` |
| 9 | (Claude Code only) Is your model's context window 200k or 1M? | `CLAUDE_CTX_WINDOW` |
| 10 | Anything you want pinned at every session start (up to ~10 lines)? | `pinned_projects.md` |

## 4. Write the personal files

- Render `~/.agent-workflow/AGENTS.md.template` to `~/.agent-workflow/AGENTS.md`. Replace every
  `{{...}}`, delete sections the user declined. Grep the result for a leftover `{{`; there must be none.
- Re-run `bash install.sh --no-packages`. Its last step symlinks that one file into each wired tool's
  global slot (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`, `~/.agents/AGENTS.md`), so there is a
  single source of truth.
- Fill `~/.agent-workflow/pinned_projects.md` from answer 10. Delete the example note in
  `~/.agent-workflow/memory/` once a real one exists.
- Add the env lines from answers 8 and 9 to the shell rc file, only if the user agreed.

## 5. Verify, then hand back

- Run `cap hook` (should list the seeded rows; if `cap` is not found, `~/bin` is not on PATH).
- Open each wired tool's config (`~/.claude/settings.json`, `~/.codex/hooks.json`,
  `~/.gemini/settings.json`, `~/.agents/hooks.json`) and confirm the hooks are present and the user's original keys survived.
- Read [docs/TOOLS.md](docs/TOOLS.md) to the user: it says what is verified per tool and what is experimental.
- Tell the user what you cannot do for them, from `docs/ACCOUNTS.md`: log in to their agent,
  `gh auth login`, and any optional service they choose. Offer to walk them through each.

## Rules while doing this

- Outward actions (push, send, publish, deploy) need the user's yes every time, including pushing
  anything from this repo.
- No guessing silently: expensive-if-wrong means stop and ask; cheap-to-reverse means state
  `assumed: ...` and go.
- Do not install plugins, MCP servers or extra tools that the README lists as optional unless the
  user asks for them.
