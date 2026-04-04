# Driver & Navigation Reference

Reference for HTTP test driver endpoints, scrollable keys, screen identification, navigation patterns, Android gotchas, and error recovery.

## HTTP Driver Endpoints (port 4948)

Binds to loopback (127.0.0.1) only — no auth required.

> Sync flows use two instances: admin on port 4948, inspector on port 4949.

| Method | Endpoint | Body/Params |
|--------|----------|-------------|
| GET | /driver/ready | — |
| GET | /driver/find?key=X | — |
| GET | /driver/screenshot | — |
| GET | /driver/tree?depth=N | — |
| GET | /driver/current-route | — |
| POST | /driver/tap | {"key": "X"} |
| POST | /driver/text | {"key": "X", "text": "Y"} |
| POST | /driver/scroll | {"key": "X", "dx": 0, "dy": -300} — **key must be on the scrollable widget itself** |
| POST | /driver/scroll-to-key | {"scrollable": "X", "target": "Y", "maxScrolls": 20} — scrollable must have a ValueKey |
| POST | /driver/back | {} |
| POST | /driver/wait | {"key": "X", "timeoutMs": 10000} |
| POST | /driver/inject-photo | {"data": "<base64>", "filename": "test.jpg"} |
| POST | /driver/inject-photo-direct | {"base64Data": "...", "filename": "...", "entryId": "...", "projectId": "..."} |
| POST | /driver/inject-file | {"data": "<base64>", "filename": "doc.pdf"} |
| POST | /driver/dismiss-keyboard | {} |
| POST | /driver/dismiss-overlays | {} |
| POST | /driver/remove-from-device | {"project_id": "<uuid>"} |
| POST | /driver/inject-document-direct | {"base64Data": "...", "filename": "...", "entryId": "...", "projectId": "..."} |
| POST | /driver/navigate | {"path": "/route/path"} |
| POST | /driver/hot-restart | {} |

> `/driver/screenshot` returns `image/png` binary. Use `curl --output <path>`.

## Scrollable Keys (for /driver/scroll and /driver/scroll-to-key)

The `key` parameter in `/driver/scroll` and `/driver/scroll-to-key` must target a **ValueKey on the scrollable widget itself** — NOT a child widget. Targeting a child (e.g., a TextField or Card) will cause the child to consume the gesture and the page won't scroll.

| Screen | Scroll Key | Widget Type | Notes |
|--------|-----------|-------------|-------|
| Entry editor (create/edit) | `entry_editor_scroll` | CustomScrollView | Main entry form |
| Entry review/detail | `entry_review_scroll` | SingleChildScrollView | Entry report view |
| Project details form | `project_details_scroll` | SingleChildScrollView | Name, number, client fields |
| Project locations list | `project_locations_list` | ListView | Locations tab in project edit |
| Project contractors list | `project_contractors_list` | ListView | Contractors tab |
| Project bid items list | `project_bid_items_list` | ListView | Pay items tab |
| Project assignments list | `project_assignments_list` | ListView | Assignments tab |
| Settings screen | `settings_list` | ListView | Main settings ListView |
| Home report preview | `home_report_preview_scroll_view` | SingleChildScrollView | Already had key |

**Example — scroll entry editor down 500px:**
```bash
curl -s -X POST http://127.0.0.1:4948/driver/scroll -d '{"key":"entry_editor_scroll","dx":0,"dy":-500}'
```

**Example — scroll-to-key to find save button:**
```bash
curl -s -X POST http://127.0.0.1:4948/driver/scroll-to-key -d '{"scrollable":"entry_editor_scroll","target":"entry_wizard_save_draft","maxScrolls":10}'
```

## Screen Identification — Sentinel Keys

**Never rely on route alone to determine which screen is active.** go_router shell routes report the parent route — `/projects` could be the project list, project edit, or project create screen.

Use **sentinel key checks** to identify the current screen:

| Screen | Route Reports | Sentinel Key (exists = on this screen) |
|--------|--------------|---------------------------------------|
| Dashboard | `/` | `dashboard_new_entry_button` |
| Calendar | `/calendar` | `calendar_prev_month` |
| Project List | `/projects` | `project_create_button` + NO `project_save_button` |
| Project Create/Edit | `/projects` | `project_save_button` + `project_locations_tab` |
| Entry Editor | `/calendar` or `/` | `entry_editor_scroll` |
| Settings | `/settings` | `settings_sync_button` |
| Toolbox Hub | (nested) | `toolbox_home_screen` |
| Todos | (nested) | `todos_screen` |
| Calculator | (nested) | `calculator_screen` |
| Admin Dashboard | (nested) | `settings_admin_dashboard_tile` absent, member tiles present |

When confused about current state, check 2-3 sentinels — **do NOT take a screenshot**. Screenshots consume significant tokens and should be reserved for failure investigation only.

### State Confusion Protocol
If you are unsure what screen you're on:
1. `curl -s http://127.0.0.1:4948/driver/current-route` — check route + `hasBottomNav` + `canPop`
2. `curl -s "http://127.0.0.1:4948/driver/find?key=<sentinel>"` for 2-3 keys from the table above
3. If still unclear, `curl -s "http://127.0.0.1:4948/driver/tree?depth=5"` — text-only, low cost
4. **Only** view a screenshot as a last resort after all 3 above fail

## Bottom Nav Destinations

| Key | Destination | Sentinel Key |
|-----|------------|--------------|
| `dashboard_nav_button` | Dashboard/Home | `dashboard_new_entry_button` |
| `calendar_nav_button` | Calendar view | `calendar_nav_button` (stays highlighted) |
| `projects_nav_button` | Projects list | `project_create_button` |
| `settings_nav_button` | Settings | `settings_sync_button` |

## Common Navigation Patterns

| Action | Sequence |
|--------|----------|
| Sync via UI | `settings_nav_button` -> `settings_sync_button` (wait 3s) |
| Create entry | `dashboard_nav_button` -> `dashboard_new_entry_button` |
| Edit project | `projects_nav_button` -> `project_edit_menu_item_<id>` |
| Open toolbox | `dashboard_nav_button` -> `dashboard_toolbox_card` |
| Open todos | Toolbox -> `toolbox_todos_card` |
| Open calculator | Toolbox -> `toolbox_calculator_card` |
| Return to dashboard from toolbox sub-screen | `POST /driver/back` x2, or tap `dashboard_nav_button` |

### Canonical Sync-via-UI Sequence (dual-port)

Sync flows use ports 4948 (admin) and 4949 (inspector):

```bash
# Admin sync (port 4948)
curl -s -X POST http://127.0.0.1:4948/driver/tap -H "Content-Type: application/json" -d '{"key":"settings_nav_button"}'
sleep 1
curl -s -X POST http://127.0.0.1:4948/driver/tap -H "Content-Type: application/json" -d '{"key":"settings_sync_button"}'
sleep 3

# Inspector sync (port 4949, 2 rounds for FK deps)
curl -s -X POST http://127.0.0.1:4949/driver/tap -H "Content-Type: application/json" -d '{"key":"settings_nav_button"}'
sleep 1
curl -s -X POST http://127.0.0.1:4949/driver/tap -H "Content-Type: application/json" -d '{"key":"settings_sync_button"}'
sleep 3
curl -s -X POST http://127.0.0.1:4949/driver/tap -H "Content-Type: application/json" -d '{"key":"settings_sync_button"}'
sleep 3
```

### Project-Related Key Disambiguation

| Key Pattern | Purpose |
|-------------|---------|
| `project_card_<id>` | Tap to select/open project |
| `project_edit_menu_item_<id>` | Tap to enter project edit mode |
| `project_create_button` | Create new project (also aliased as `add_project_fab`) |
| `project_save_button` | Save project edits |
| `project_remove_<id>` | Delete project (triggers two-step confirmation) |

## Android Gotchas

### Keyboard Blocking
After entering text in any field on Android, the soft keyboard covers the bottom ~40% of the screen. Taps on widgets behind the keyboard return `200 {tapped: true}` but the tap never reaches the widget.

**Fix:** Always call `POST /driver/dismiss-keyboard` before tapping buttons after text entry:
```bash
curl -s -X POST http://127.0.0.1:4948/driver/dismiss-keyboard -H "Content-Type: application/json" -d '{}'
sleep 0.3
curl -s -X POST http://127.0.0.1:4948/driver/tap -d '{"key":"save_button"}'
```

### Snackbar Blocking
Persistent snackbars (e.g., sync errors) overlay the bottom of the screen and block taps on project cards and action buttons.

**Fix:** Call `POST /driver/dismiss-overlays` to clear all snackbars and banners:
```bash
curl -s -X POST http://127.0.0.1:4948/driver/dismiss-overlays -H "Content-Type: application/json" -d '{}'
```

### Toolbox Navigation Depth
Toolbox sub-screens (Todos, Calculator, Gallery, Forms) are **two levels deep** from Dashboard:
- Dashboard -> Toolbox Hub -> Sub-screen
- Back from sub-screen -> Toolbox Hub (NOT dashboard)
- Back from Toolbox Hub -> Dashboard
- Bottom nav is NOT visible inside Toolbox sub-screens

Always use `POST /driver/back` twice, or tap `dashboard_nav_button` to return to dashboard directly.

## Error Recovery Protocol

### Tap returns 200 but nothing happens
1. Check `GET /driver/current-route` — you may be on the wrong screen
2. Call `POST /driver/dismiss-keyboard` — keyboard may be blocking
3. Call `POST /driver/dismiss-overlays` — snackbar may be blocking
4. Verify widget with `GET /driver/find?key=X` — check `enabled` and `visible` fields
5. Take screenshot to visually confirm state

### Widget not found (404)
1. Check you are on the correct screen: `GET /driver/current-route`
2. Try scrolling: the widget may be off-screen (use `POST /driver/scroll-to-key`)
3. Read `testing_keys/*.dart` to verify the exact key name
4. As last resort, use `/driver/tree?filter=<partial>` to discover the actual key

### Sync appears to fail
1. Check sync logs: `curl -s "http://127.0.0.1:3947/logs?category=sync&format=text&last=10"`
2. Check for errors: `curl -s "http://127.0.0.1:3947/logs/errors?since=<START>"`
3. Dismiss any error snackbars: `POST /driver/dismiss-overlays`
4. Retry sync via UI (settings_nav_button -> settings_sync_button)
5. If still failing, take screenshot and record as bug
