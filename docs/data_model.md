# Firestore Data Model (MVP-1) — Updated after Research

## Collections

### users/{uid}
Fields:
- role: "admin" | "storekeeper" | "loader" | "guest"
- displayName
- photoUrl
- isActive: bool
- createdAt, updatedAt
- locale: "ru" | "kk" | "en"
- settings:
  - soundEnabled: bool
  - vibrationEnabled: bool
  - themeMode: "system" | "light" | "dark"
- fcmTokens: array<string> (optional; MVP may skip push)

---

### products/{article}
Document ID: article (string)
Fields:
- article: string
- name: string
- category: string (e.g., "Refrigerators", "Washing Machines")
- brand: string? (optional)
- barcode: string? (single “customer barcode”)
- createdAt, updatedAt

Notes:
- barcode optional initially (bind later).
- barcode uniqueness is enforced via barcode_index.

---

### barcode_index/{barcode}
Document ID: barcode (string)
Fields:
- barcode: string
- article: string
- createdAt
- createdBy: uid

Constraints:
- 1:1 mapping barcode -> article
- O(1) lookup on scan (critical for speed and low reads)

---

### transfers/{transferId}
Fields:
- status: new|picking|picked|checking|done_verified|done_unverified
- number: string
- date: timestamp
- title: string
- sender: string
- receiver: string
- createdBy: uid
- publishedBy: uid
- createdAt, publishedAt
- pickedAt
- checkingStartedAt
- completedAt
- completedBy: uid
- completedMode: "verified"|"unverified"|null

flags:
- needsCatalogAttention: bool
- hasConflicts: bool

stats (cache for cheap lists):
- totalLines: int
- doneLines: int
- totalUnitsPlanned: int
- totalUnitsPicked: int
- updatedAt: timestamp

Cost rule:
- stats обновляем **только при редких событиях**:
  - totalLines/totalUnitsPlanned при publish
  - doneLines при переходе line -> done
  - totalUnitsPicked при инкременте qtyPicked (опционально; можно считать на клиенте в details)

---

### transfers/{transferId}/lines/{lineId}
Fields:
- lineNo: int
- article: string
- nameFromDoc: string
- category: string (from catalog else "Uncategorized")
- qtyPlanned: int
- qtyPicked: int
- status: open|locked|done
- lock: object|null
  - userId
  - lockedAt
  - expiresAt

Picking attribution (instead of scan_success events):
- pickedBy: map<uid, int>       // increments with qtyPicked
- lastPickedAt: timestamp       // updated on successful increment

Notes:
- pickedBy/lastPickedAt give “who picked what” without event spam.

---

### transfers/{transferId}/events/{eventId}
Append-only, “cold data”.
Used for:
- lock actions
- scan errors
- lifecycle transitions
- sync conflicts
Read with pagination only.
