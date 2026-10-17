# agent-workflow-setup

A working setup for AI coding agents that does not depend on which one you use: one rules file,
guardrail hooks, a "check before you build" registry, crash-proof WIP snapshots and a plain-markdown
memory. Works with **Claude Code**, **Codex**, **Gemini CLI** and **Antigravity (`agy`)**. No personal data is in
this repo; your own details are collected by an interview and stay on your machine.

## Quick start

```bash
git clone https://github.com/Pongchayanneung/agent-workflow-setup.git
cd agent-workflow-setup
bash install.sh            # wires every agent it finds on PATH (or: --tools claude,codex,gemini,agy)
```

Log in to your agent once (see [docs/ACCOUNTS.md](docs/ACCOUNTS.md)), open it **in this folder**, and say:

> Read SETUP.md and run the setup.

It asks about 10 questions, writes `~/.agent-workflow/AGENTS.md`, and symlinks that one file into each
tool's global slot. Supports macOS (Homebrew) and Ubuntu/Debian (apt). Windows: use WSL.

## Structure

```
agent-workflow-setup/
├── AGENTS.md  CLAUDE.md  GEMINI.md   entry points: tell any agent opened here to run SETUP.md
├── SETUP.md                          agent-facing runbook + the interview questions
├── install.sh                        toolchain, hooks, registry, per-tool config merge, rules link
├── core/                             tool-neutral, installed to ~/.agent-workflow/
│   ├── hooks/                        guardrail scripts (bash/python, git-only dependencies)
│   ├── bin/cap                       capability registry search
│   └── templates/                    AGENTS.md.template, capabilities.tsv, memory/, pinned_projects.md
├── adapters/                         how each tool is wired to core/
│   ├── agy/                          ~/.agents/hooks.json groups (tested live)
│   ├── claude/                       settings.json hook wiring + compact_nudge.py
│   ├── codex/                        hooks.json (experimental)
│   └── gemini/                       settings.json: context.fileName + hooks (experimental)
└── docs/                             ACCOUNTS.md (logins), TOOLS.md (what is verified per tool)
```

What lands on your machine:

```
~/.agent-workflow/   AGENTS.md (your rules)  hooks/  capabilities.tsv  memory/  pinned_projects.md  backups/
~/bin/cap
~/.claude/CLAUDE.md -> ~/.agent-workflow/AGENTS.md   (symlink; same for ~/.codex/AGENTS.md, ~/.gemini/GEMINI.md, ~/.agents/AGENTS.md)
```

## What you get

| Piece | What it does |
|---|---|
| One rules file | Profile, approvals, push-back, never-guess-silently, verify-before-done, secret hygiene. Edit once, every agent sees it |
| Task modes | Per-prompt `light / full / block`. Editing hooks or agent config auto-escalates to `full` so the change gets reviewed |
| Smoke-test gate | Blocks wiring a hook into a config until that exact file content has been run once |
| Capability gate + `cap` | The first time an agent creates a script under `~/bin` or `~/.agent-workflow/tools`, it is stopped and shown similar registry rows. Stops you rebuilding what exists |
| Agent checkpoint gate | A background agent must be told to write findings to a file as it goes, so a crash cannot lose its work |
| WIP autosave + warm resume | Dirty git repos are snapshotted to `refs/wip/autosave-*` without touching your working tree. The next session is told what is uncommitted |
| Memory | `MEMORY.md` index plus one-fact-per-file notes (user, feedback, project, reference). Plain markdown any agent can read |

Per-tool coverage and how much of it was actually tested: [docs/TOOLS.md](docs/TOOLS.md).

## What gets asked, and what never is

Asked (answers stay on your machine): name, role, timezone, languages, OS and other machines, GitHub
username and default email, permission mode, where your repos live, context window size, pinned projects.
Never asked or stored: passwords, tokens, API keys. Logins happen in your browser.

## Choices worth knowing about

- **No-prompt mode is not the default.** The author runs one; it removes the prompt gate on every
  command, so you pick it deliberately in the interview.
- **Outward actions always need your yes** (push, send, publish, deploy). It is a rule in the file and
  the hooks assume it.
- **Nothing is overwritten silently.** Replaced files are copied to `~/.agent-workflow/backups/<timestamp>/`,
  configs are merged not replaced, an existing global rules file is never touched, re-running is safe.
- **Hooks fail open.** A bug in a gate never locks you out of editing.
- Plugins, MCP servers and status lines are optional; see [docs/ACCOUNTS.md](docs/ACCOUNTS.md).

## Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `AGENT_WORKFLOW_HOME` | `~/.agent-workflow` | Where core files, state and memory live |
| `CLAUDE_WIP_ROOTS` | `~/repos:~/projects:~/GitHub:~/code` | Colon-separated folders scanned (3 levels deep) for repos to snapshot |
| `CLAUDE_CTX_WINDOW` | `200000` | Claude only: your model's context window (set `1000000` for 1M) |

## Restoring a WIP snapshot

```bash
git -C <repo> for-each-ref refs/wip                       # list snapshots
git clone <repo> /tmp/restore && cd /tmp/restore
git fetch <repo> '+refs/wip/*:refs/wip/*'
git reset --hard refs/wip/autosave-<id>                   # in the NEW clone only
```

## Uninstall

Remove the hook entries from `~/.claude/settings.json`, `~/.codex/hooks.json`, `~/.gemini/settings.json`
and the `agent-workflow-*` groups from `~/.agents/hooks.json` (or restore them from
`~/.agent-workflow/backups/`), delete the symlinks, then remove
`~/.agent-workflow/` and `~/bin/cap`.
