# UI Flow & Navigation (Mobile + Web) — Updated after UX Research

Research-driven principles:
- **Scan-first**: минимизируем клики, система ведёт пользователя потоком.
- **Minimum Viable Context**: на экране только то, что нужно для микродействия.
- **Thumb zone**: основные кнопки снизу (удобно для “gun-grip”/телефона).
- **Strong feedback**: haptics + sound + big banner success/error.
- **Exception handling**: ошибки обрабатываются отдельными понятными сценариями.

## Mobile app main nav (bottom tabs)
1) Transfers
2) Catalog
3) Notifications (in-app)
4) Profile/Settings

Optional later:
- To-Do
- Pick-Up

---

## Mobile: Transfers

### Transfers List
Transfers List (MVP):
- Show status only (New/In progress/Picked/Done)
- No numeric progress bar on list
- Exact progress computed in Transfer Details (lines streamed only there)

Reads policy (Free Tier):
- Transfers list streams only `transfers` (limit 20/50).
- It uses lightweight fields only: `status` + minimal metadata + `flags` (badges).
- It does NOT stream/read `lines` for each card.
- Lines are streamed ONLY inside Transfer Details while that screen is open.
- Events are loaded on demand with pagination (no realtime).

### Transfer Details (Scan-first picking)
Layout:
- Header metadata (minimal)
- Progress + “Ready/Locked/Done” legend
- Category accordion groups
- Lines list

Line row (Minimum context):
- name (1–2 lines)
- qty progress (e.g., 1/3) large
- state: open/locked/done
- action:
  - "Prepare" / disabled if locked by others / "Continue" if locked by self

### Prepare → Scan flow
- Tap “Prepare” locks the line and immediately opens Scan screen.
- Cancel preparation available (rare).

### Scan Screen (Picking)
- Fullscreen camera
- Big status banner at top (success/error)
- Current target line (name + remaining qty)
- Bottom actions (thumb zone):
  - Cancel (release lock)
  - Torch
  - Manual entry (optional, admin-only toggle)

Auto-advance:
- If scan success and qtyPicked hits qtyPlanned → auto close scanner and return to details.

### Checking
- Storekeeper sees "Start checking" and "Finish unverified"
- Verified flow can reuse scan screen in “checking mode”

---

## Mobile: Catalog (Admin/Storekeeper heavy)
### Catalog Search
- search by article (primary) + name prefix (optional)
- result row: article + name + category + barcode presence badge
- tap -> Product Detail

### Product Detail
- view fields
- bind barcode (scan) action
- admin edit fields

---

## Mobile: Notifications (in-app, MVP)
- Derived from transfer changes (publish/picked/done) OR stored as docs later
- No push required for MVP

---

## Mobile: Settings
- language ru/kk/en
- theme (dark mode strongly recommended)
- sound/vibration toggles
- camera permissions / notifications permission status

---

## Web Admin Panel (Upload Focus Mode)
### Dashboard
- Upload transfer (drag&drop)
- Recent uploads list
- Published transfers list

### Upload Flow (Focus Mode)
1) Upload
2) Parse Preview
3) Validate (error table)
4) Publish

Focus Mode behavior:
- hide global nav/sidebar
- show linear stepper + clear “Exit”
- preview with column headers and row-level errors
