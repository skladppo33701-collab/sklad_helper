# Firestore Data Model (MVP-1)

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
- fcmTokens: array<string> (or subcollection for scalability)

Indexes:
- role (optional for admin views)

---

### products/{article}
Document ID: article (string)
Fields:
- article: string
- name: string
- category: string (e.g., "Refrigerators", "Washing Machines")
- brand: string? (optional)
- barcode: string? (single "customer barcode")
- updatedAt
- createdAt

Constraints:
- barcode is optional initially; later becomes set.
- barcode must be unique (enforced via barcode_index).

---

### barcode_index/{barcode}
Document ID: barcode (string)
Fields:
- barcode: string
- article: string
- createdAt
- createdBy: uid

Constraints:
- 1:1 mapping barcode -> article.
- Prevent duplicates: docId uniqueness.

---

### transfers/{transferId}
Fields:
- status: new|picking|picked|checking|done_verified|done_unverified
- number: string (e.g. "52")
- date: timestamp
- title: string (e.g. "Transfer #52 — 2026-01-22")
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
- flags:
  - needsCatalogAttention: bool (e.g., missing products in catalog)
  - hasConflicts: bool
- stats (optional cache):
  - totalLines
  - doneLines
  - totalUnitsPlanned
  - totalUnitsPicked

Indexes:
- status + publishedAt
- date + number (optional)

---

### transfers/{transferId}/lines/{lineId}
Fields:
- lineNo: int
- article: string
- nameFromDoc: string
- category: string (from catalog if exists else "Uncategorized")
- qtyPlanned: int
- qtyPicked: int
- status: open|locked|done
- lock: object|null
  - userId: uid
  - lockedAt: timestamp
  - expiresAt: timestamp

Indexes:
- article (optional)
- status (optional)

---

### transfers/{transferId}/events/{eventId}
Fields:
- type: string (see docs/events.md)
- userId: uid
- timestamp
- payload: map (flexible)
Examples payload:
- barcode
- article
- lineId
- qtyBefore, qtyAfter
- errorCode
- deviceInfo (optional)

Retention:
- configurable (30/90/180 days) via scheduled cleanup (
