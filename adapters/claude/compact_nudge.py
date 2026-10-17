#!/usr/bin/env python3
"""Stop hook: when a task finishes, nudge /compact if context is at or near the threshold.

Never compacts itself (hooks cannot); built-in auto-compact is the backstop
(CLAUDE_AUTOCOMPACT_PCT_OVERRIDE in settings.json env).
"""
import json, os, sys

WINDOW = int(os.environ.get("CLAUDE_CTX_WINDOW", "200000"))  # set 1000000 on a 1M-context model
NUDGE = WINDOW // 4      # 25%: compact at the next task boundary
TASK_GROWTH = 16_000     # rough context added by one prompt; tune from your own transcripts
TAIL_LINES = 400


def last_context(path):
    # Read complete records backwards; never truncate a large final JSONL record.
    with open(path, "rb") as f:
        f.seek(0, 2)
        position = f.tell()
        chunks = []
        newlines = 0
        while position and newlines <= TAIL_LINES:
            size = min(position, 65536)
            position -= size
            f.seek(position)
            chunk = f.read(size)
            chunks.append(chunk)
            newlines += chunk.count(b"\n")
        tail = [line.decode("utf-8") for line in
                b"".join(reversed(chunks)).splitlines()[-TAIL_LINES:]]
    for line in reversed(tail):
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(d, dict) or not isinstance(d.get("message"), dict):
            continue
        u = d["message"].get("usage")
        if d.get("type") != "assistant" or not isinstance(u, dict) or d.get("isSidechain"):
            continue
        keys = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
        if any(not isinstance(u.get(k, 0), int) for k in keys):
            continue
        ctx = (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
               + u.get("cache_creation_input_tokens", 0))
        if ctx:
            return ctx
    return 0


def message(ctx):
    pct = f"{100 * ctx / WINDOW:.0f}% ({ctx // 1000}k)"
    if ctx >= NUDGE:
        return f"✂ Task done, context at {pct} (25% threshold). Run /compact before the next task."
    if ctx + TASK_GROWTH >= NUDGE:
        return f"✂ Context at {pct}, near the 25% threshold. The next task will likely cross it, so /compact now."
    return None


def main():
    try:
        event = json.load(sys.stdin)
        msg = message(last_context(event["transcript_path"]))
    except (OSError, KeyError, ValueError, TypeError, AttributeError) as e:
        print(f"compact_nudge: {e}", file=sys.stderr)  # never block the session on a hook bug
        return
    if msg:
        print(json.dumps({"systemMessage": msg}, ensure_ascii=False))


if __name__ == "__main__":
    main()
