# Visual Companion Guide

Browser-based visual brainstorming companion for showing mockups, diagrams, and options. Ported from `obra/superpowers/skills/brainstorming/` with Field Guide path adaptations (`.claude/brainstorm/` instead of `.superpowers/brainstorm/`) and a fixed port (`5947`).

## Table of Contents

- [When to Use](#when-to-use)
- [How It Works](#how-it-works)
- [Starting a Session](#starting-a-session)
- [The Loop](#the-loop)
- [Writing Content Fragments](#writing-content-fragments)
- [CSS Classes Available](#css-classes-available)
- [Browser Events Format](#browser-events-format)
- [Design Tips](#design-tips)
- [File Naming](#file-naming)
- [Cleaning Up](#cleaning-up)

## When to Use

Decide **per-question**, not per-session. The test: *would the user understand this better by seeing it than reading it?*

**Use the browser** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — two layouts, two color schemes, two design directions
- **Design polish** — questions about look and feel, spacing, visual hierarchy
- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams

**Use the terminal** when the content is text or tabular:

- **Intent / Scope / Vision gate questions** — the checklist items in the gates are text-first
- **Conceptual A/B/C choices** — picking between approaches described in words
- **Tradeoff lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question *about* a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts feels right?" is visual — use the browser.

**Primary earn-your-keep moment:** the UX Polish work type's options phase is where the companion most reliably beats the terminal (visual direction cards).

## How It Works

The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.

**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.

## Starting a Session

The companion is opt-in and session-scoped. The consent offer is its own standalone message, never combined with a clarifying question, and never re-asked once the user decides. On accept:

```bash
.claude/skills/brainstorming/scripts/start-server.sh --project-dir "$(pwd)"
```

Expected response:

```json
{"type":"server-started","port":5947,"host":"127.0.0.1","url_host":"localhost",
 "url":"http://localhost:5947",
 "screen_dir":".../.claude/brainstorm/<session-id>/content",
 "state_dir":".../.claude/brainstorm/<session-id>/state"}
```

Save `screen_dir`, `state_dir`, and the URL from the response. Tell the user to open the URL.

**Port collision:** The server defaults to `5947`. Other local services: `3947` (debug-server), `4948`/`4949` (HTTP test drivers). If `5947` is already in use, pass `--port <num>` to pick another high port.

**Finding connection info later:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to recover the URL.

**Platform launch notes:**

- **Windows (Claude Code)** — `start-server.sh` auto-detects MSYS/MinGW and switches to foreground mode. When calling via the Bash tool, set `run_in_background: true` so the server survives across turns. Then read `$STATE_DIR/server-info` on the next turn.
- **macOS / Linux (Claude Code)** — default mode works; the script backgrounds the server itself.
- **Remote / containerized** — if the URL is unreachable from your browser, bind a non-loopback host: `start-server.sh --host 0.0.0.0 --url-host localhost`.

## The Loop

1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
   - Before each write, check that `$STATE_DIR/server-info` exists. If it doesn't (or `$STATE_DIR/server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
   - Use semantic filenames: `layout.html`, `visual-style.html`, `entry-card.html`
   - **Never reuse filenames** — each screen gets a fresh file (for iterations, append `-v2`, `-v3`)
   - Use the Write tool — **never use cat/heredoc** (dumps noise into terminal)
   - Server automatically serves the newest file by mtime

2. **Tell user what to expect and end your turn:**
   - Remind them of the URL (every visual step, not just first)
   - Give a brief text summary of what's on screen (e.g., "Showing 3 entry card layouts")
   - Ask them to respond in the terminal: "Take a look and let me know what you think. Click to select if you want."

3. **On your next turn** — after the user responds in the terminal:
   - Read `$STATE_DIR/events` if it exists — browser interactions (clicks, selections) as JSONL
   - Merge with the user's terminal text to get the full picture
   - The terminal message is the primary feedback; `events` provides structured interaction data

4. **Iterate or advance** — if feedback changes the current screen, write a new file (e.g., `layout-v2.html`). Only move on when the current question is validated.

5. **Unload when returning to the terminal** — when the next step doesn't need the browser (clarifying question, tradeoff discussion), push a waiting screen to clear stale content:

   ```html
   <!-- filename: waiting.html (or waiting-2.html, etc.) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

6. Repeat until done.

## Writing Content Fragments

Write just the content that goes inside the page. The server wraps it in the frame template automatically.

```html
<h2>Which entry card layout works better?</h2>
<p class="subtitle">Consider glove-use and bright-sunlight legibility</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Stacked</h3>
      <p>Contractor + title stacked, timestamps inline</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Side-by-side</h3>
      <p>Contractor chip on the left, title fills remaining width</p>
    </div>
  </div>
</div>
```

No `<html>`, no CSS, no `<script>` tags needed. The server provides all of that.

## CSS Classes Available

The frame template provides these classes for your content. Full reference: `scripts/frame-template.html`.

### Options (A/B/C choices)

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content"><h3>Title</h3><p>Description</p></div>
  </div>
</div>
```

**Multi-select:** add `data-multiselect` to the container to allow toggling multiple items.

### Cards (visual designs)

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- mockup content --></div>
    <div class="card-body"><h3>Name</h3><p>Description</p></div>
  </div>
</div>
```

### Mockup container

```html
<div class="mockup">
  <div class="mockup-header">Preview: Entry Editor</div>
  <div class="mockup-body"><!-- your mockup HTML --></div>
</div>
```

### Split view (side-by-side)

```html
<div class="split">
  <div class="mockup"><!-- left --></div>
  <div class="mockup"><!-- right --></div>
</div>
```

### Pros/Cons

```html
<div class="pros-cons">
  <div class="pros"><h4>Pros</h4><ul><li>Benefit</li></ul></div>
  <div class="cons"><h4>Cons</h4><ul><li>Drawback</li></ul></div>
</div>
```

### Mock elements (wireframe building blocks)

```html
<div class="mock-nav">Logo | Home | Forms | Contact</div>
<div style="display: flex;">
  <div class="mock-sidebar">Navigation</div>
  <div class="mock-content">Main content area</div>
</div>
<button class="mock-button">Action Button</button>
<input class="mock-input" placeholder="Input field">
<div class="placeholder">Placeholder area</div>
```

### Typography and sections

- `h2` — page title
- `h3` — section heading
- `.subtitle` — secondary text below title
- `.section` — content block with bottom margin
- `.label` — small uppercase label text

## Browser Events Format

When the user clicks options in the browser, their interactions are recorded to `$STATE_DIR/events` (one JSON object per line). The file is cleared automatically when you push a new screen.

```jsonl
{"type":"click","choice":"a","text":"Option A - Stacked","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Compact","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Side-by-side","timestamp":1706000115}
```

The full stream shows the user's exploration path — they may click multiple options before settling. The last `choice` event is typically the final selection, but the pattern of clicks can reveal hesitation worth asking about.

If `$STATE_DIR/events` doesn't exist, the user didn't interact with the browser — use only their terminal text.

## Design Tips

- **Scale fidelity to the question** — wireframes for layout questions, polish for polish questions
- **Explain the question on each page** — "Which entry card feels more readable?" not just "Pick one"
- **Iterate before advancing** — if feedback changes the current screen, write a new version
- **2-4 options max** per screen
- **Mirror Field Guide design tokens conceptually** — the frame template uses generic tokens; if the question is specifically about `FieldGuideSpacing` / `FieldGuideColors`, call it out in the caption so the user knows what scale you're showing
- **Keep mockups simple** — focus on layout and structure, not pixel-perfect design

## File Naming

- Semantic names: `layout.html`, `visual-style.html`, `entry-card.html`
- Never reuse filenames — each screen is a new file
- For iterations: append version suffix (`layout-v2.html`, `layout-v3.html`)
- Server serves newest file by mtime

## Cleaning Up

```bash
.claude/skills/brainstorming/scripts/stop-server.sh "$SESSION_DIR"
```

Session directories under `.claude/brainstorm/` persist for later review. The top-level `.claude/brainstorm/` directory is `.gitignore`'d so mockup files never land in commits.

## Reference

- Frame template (CSS reference): `../scripts/frame-template.html`
- Helper script (client-side): `../scripts/helper.js`
- Server implementation: `../scripts/server.cjs`
