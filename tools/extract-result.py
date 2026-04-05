#!/usr/bin/env python3
"""Extract structured_output from stream-json, discard everything else.

Reads stream-json events from stdin.
Outputs ONLY the final result's structured_output field.
This is what enters the orchestrator's context.

Usage (tee pipeline):
  claude --bare -p "..." --output-format stream-json --verbose \
    2>&1 | tee >(python3 .claude/tools/stream-filter.py > /dev/tty) \
    | python3 .claude/tools/extract-result.py
"""
import json
import sys


def main() -> None:
    for line in sys.stdin:
        try:
            ev = json.loads(line)
        except (json.JSONDecodeError, ValueError):
            continue

        if ev.get("type") == "result":
            # Try direct structured_output first, then nested under result
            so = ev.get("structured_output")
            if so is None:
                so = ev.get("result", {}).get("structured_output")
            if so:
                # If it's already a dict/list, dump it; if string, parse then dump
                if isinstance(so, str):
                    try:
                        so = json.loads(so)
                    except (json.JSONDecodeError, ValueError):
                        pass
                print(json.dumps(so, indent=2))
                break


if __name__ == "__main__":
    main()
