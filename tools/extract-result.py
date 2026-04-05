#!/usr/bin/env python3
"""Extract structured_output from claude CLI JSON output.

Handles both --output-format json (single JSON object) and
--output-format stream-json (newline-delimited JSON events).

Usage:
  claude -p "..." --output-format json --json-schema '...' 2>&1 | python3 .claude/tools/extract-result.py
"""
import json
import sys


def extract_structured_output(data: dict) -> dict | None:
    """Extract structured_output from a result dict."""
    # Direct field (--output-format json)
    so = data.get("structured_output")
    if so is not None:
        if isinstance(so, str):
            try:
                return json.loads(so)
            except (json.JSONDecodeError, ValueError):
                return {"raw": so}
        return so

    # Nested under result (some stream-json formats)
    result = data.get("result")
    if isinstance(result, dict):
        so = result.get("structured_output")
        if so is not None:
            if isinstance(so, str):
                try:
                    return json.loads(so)
                except (json.JSONDecodeError, ValueError):
                    return {"raw": so}
            return so

    return None


def main() -> None:
    raw = sys.stdin.read().strip()
    if not raw:
        print("{}", file=sys.stdout)
        return

    # Try parsing as single JSON object first (--output-format json)
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            so = extract_structured_output(data)
            if so:
                print(json.dumps(so, indent=2))
                return
            # No structured_output — dump the result field as fallback
            result = data.get("result", "")
            if result:
                print(json.dumps({"raw_result": result}, indent=2))
                return
    except (json.JSONDecodeError, ValueError):
        pass

    # Try parsing as stream-json (newline-delimited)
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except (json.JSONDecodeError, ValueError):
            continue

        if not isinstance(ev, dict):
            continue

        if ev.get("type") == "result":
            so = extract_structured_output(ev)
            if so:
                print(json.dumps(so, indent=2))
                return

    # Nothing found
    print("{}", file=sys.stdout)


if __name__ == "__main__":
    main()
