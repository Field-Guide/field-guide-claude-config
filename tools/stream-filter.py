#!/usr/bin/env python3
"""Show tool calls on terminal during headless agent execution.

Usage (tee to terminal):
  claude --bare -p "..." --output-format stream-json --verbose \
    2>&1 | tee >(python3 .claude/tools/stream-filter.py > /dev/tty) \
    | python3 .claude/tools/extract-result.py

Usage (file):
  python3 .claude/tools/stream-filter.py output.jsonl

Shows: tool name + target (file_path/pattern/command) + [PROGRESS] lines.
Writes to stdout (which is /dev/tty via tee redirection).
"""
import json
import sys


def process_line(line: str) -> None:
    try:
        ev = json.loads(line)
    except (json.JSONDecodeError, ValueError):
        return

    ev_type = ev.get("type")

    if ev_type == "assistant":
        for c in ev.get("message", {}).get("content", []):
            if c.get("type") == "tool_use":
                inp = c.get("input", {})
                detail = (
                    inp.get("file_path")
                    or inp.get("pattern")
                    or inp.get("command", "")
                )
                name = c.get("name", "?")
                print(f"  {name}: {str(detail)[:120]}", flush=True)
            elif c.get("type") == "text":
                text = c.get("text", "")
                # Only show [PROGRESS] lines from assistant text
                for text_line in text.split("\n"):
                    if "[PROGRESS]" in text_line:
                        print(text_line.strip(), flush=True)


def main() -> None:
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as f:
            for line in f:
                process_line(line)
    else:
        for line in sys.stdin:
            process_line(line)


if __name__ == "__main__":
    main()
