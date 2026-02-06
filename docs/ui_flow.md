# UI Flow & Navigation (Mobile + Web)

## Mobile app main nav (bottom tabs)
1) Transfers
2) Catalog (role-gated: loader has search; admin/storekeeper has edit)
3) Notifications (in-app)
4) Profile/Settings

Optional later:
- To-Do
- Pick-Up

---

## Mobile: Transfers

### Transfers List Screen
- Tabs/filters: New, Picking, Picked, Done
- Search by transfer number/title
- Card displays:
  - title (Transfer #, date)
  - status chip
  - progress (done/total)
  - active workers (avatars)
  - last updated

Actions:
- Tap card -> Transfer Details

### Transfer Details Screen
Sections:
- Header: metadata (sender/receiver/created by/published at)
- Progress summary
- Category list with expandable groups
- Line items list

Line item row:
- name
- article (optional)
- qty progress (e.g. 1/3)
- status (open/locked/done)
- lock owner avatar if locked
- button: "Prepare" (if available) / disabled if locked by others / "Continue" if locked by self

Actions:
- Prepare -> Scan Screen
- Storekeeper: "Start Checking" (when picked)
- Storekeeper: "Finish Unverified" (when picked)
- Storekeeper: "Finish Verified" (when checking complete)

### Scan Screen (Picking)
- Fullscreen camera scan
- Big status banner (Success/Error)
- Current line info
- Buttons:
  - Cancel preparation (release lock)
  - Torch (optional)
  - Manual barcode entry (optional)
- Shows last 3 scan results

### Scan Screen (Checking)
Similar, but distinct mode label "Checking".

### Transfer Audit Screen (optional in MVP)
- Events timeline

---

## Mobile: Catalog

### Catalog Search Screen
- search field
- results list with key fields
- tap -> Product Detail

### Product Detail Screen
- article, name, category, barcode
- Admin/Storekeeper: edit fields
- Admin/Storekeeper: bind barcode button

### Bind Barcode Screen
- camera scan
- validate EAN
- confirm save
- show conflicts if barcode already exists

---

## Mobile: Notifications
- list of in-app notifications
- tap -> opens related transfer/product

---

## Mobile: Profile/Settings
- profile photo
- language selection
- theme
- sound/vibration toggles
- push notification permission status

---

## Web Admin Panel

### Login Screen
- email+password

### Dashboard
- Upload Transfer (drag&drop)
- Recent uploads list
- Published transfers list

### Upload Preview Screen
- parsed metadata
- line table preview
- validation errors
- actions:
  - Publish
  - Cancel / re-upload

### Catalog (optional in MVP web)
- search products
- bind barcode
