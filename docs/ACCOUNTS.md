# Accounts and logins

What needs a human, a browser or a secret. The installer never touches any of these.

| What | Command | Needed for | Notes |
|---|---|---|---|
| Your agent | `claude`, `codex login`, `gemini`, or `agy` | everything | Run it once; it opens a browser. On a headless server it prints a URL: open it on another device and paste the code back. Use a plan that includes the CLI. |
| GitHub | `gh auth login` | push, PRs, `gh` commands | Choose HTTPS and "Login with a web browser". Skip if you do not use GitHub. |
| Git identity | `git config --global user.name "..."` and `user.email` | commits | Use the email you want public on commits. |

## Optional, only if you want them

| What | How | Why you might want it |
|---|---|---|
| Plugins | Claude: `/plugin` | The author uses [ponytail](https://github.com/DietrichGebert/ponytail) (bias toward the smallest working change). Review any plugin before enabling it; plugins run code and hooks on your machine. |
| MCP servers | `claude mcp add ...`, `codex mcp add ...` or the tool's connectors UI | Gmail, Calendar, Drive, Notion and similar. Each one asks you to authorize in a browser. Add only the ones you will use. |
| Cloud drive | `rclone config` | Only if you want Claude to read or write a cloud drive. Create the OAuth client yourself; do not share tokens. |
| Remote machine | Tailscale + `ssh <host>` | Only if you drive a second computer. |
| Status line (Claude) | [claude-statusline-starter](https://github.com/Pongchayanneung/claude-statusline-starter) | Model, directory, git branch and context in the footer. |
| Gemini as a second opinion | [claude-gemini-bridge](https://github.com/Pongchayanneung/claude-gemini-bridge) | Independent review from a different model. Sends your prompt and files to Google; keep confidential material out of it. |

## What the installer needs permission for

`brew install` or `sudo apt-get install` for git, python3 and jq. With `--install-claude` it also
downloads Claude Code from `claude.ai/install.sh`; other agent CLIs you install yourself.
Read `install.sh` before running it; it is about 140 lines.
