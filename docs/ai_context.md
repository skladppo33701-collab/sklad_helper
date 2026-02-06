# Product Specification (MVP-1)

## Purpose
Warehouse picking assistant to prevent shipment errors:
- wrong model
- wrong quantity
- wrong item

The app DOES NOT manage inventory levels.
1C is the source of truth for stock and documents.

## Platforms
- Mobile app (Flutter): loaders + storekeeper + admin
- Web admin panel (Flutter Web): upload/preview/publish transfers, catalog management (minimal)

## Roles
### Admin
- Full access
- Manage catalog and barcode binding
- Manage users/roles/activation
- Override locks and corrections
- View all audit logs

### Storekeeper
- Upload & publish transfers (web)
- Final checking stage
- Finish transfers verified/unverified
- Can pick if needed
- Cannot change global user roles unless granted by admin

### Loader
- View published transfers
- Prepare/lock lines
- Scan items for picking
- Cannot finalize transfers

### Guest
- Read-only access to limited pages (optional)
- No write actions

## Core entities
- Product (catalog)
- Barcode index (barcode -> article)
- Transfer (published picking document)
- Transfer line (per item and qty)
- Event (audit log record)

## Key rules
- Barcode is the primary key at scan time.
- 1 barcode must map to exactly 1 product article.
- Unknown barcode never increments quantities.
- Picking must reach 100% (qtyPicked == qtyPlanned for all lines) before moving to `picked`.
- Only storekeeper/admin can finalize transfer (`done_verified` or `done_unverified`).

## Transfer lifecycle (status machine)
- `new` -> `picking` -> `picked` -> `checking` -> `done_verified`
- `picked` -> `done_unverified` (storekeeper/admin only)

## Picking mechanics
- A loader must press "Prepare" on a line before scanning for that line.
- Prepare acquires a lock (5 minutes) visible to others.
- Line becomes `done` when qtyPicked reaches qtyPlanned.
- Transfer becomes `picked` automatically once all lines are `done`.
- Users can cancel preparation (release lock).

## Checking mechanics
- Storekeeper can start checking on a `picked` transfer.
- Checking can be performed via scanning (same barcode mapping concept).
- Storekeeper may skip checking (finalize unverified). Must be recorded as s


# State Architecture (Flutter + Riverpod + Firestore)

This document defines how state flows through the app to support:
- real-time multi-user picking
- lock-based conflict prevention
- offline tolerance
- clear separation of read vs write responsibilities

## 1) Core Principles

### 1.1 Source of Truth
Firestore is the single source of truth for:
- transfers and their statuses
- transfer lines (qtyPlanned/qtyPicked)
- locks (who is working on a line)
- audit events (who scanned/locked/completed)

The client computes UI-friendly derived state, but does not store critical business facts only locally.

### 1.2 Read vs Write Separation
- **Read layer:** Riverpod Stream providers (Firestore streams).
- **Write layer:** Services (command methods) that use Firestore transactions and create audit events.

This avoids “state spaghetti” and makes concurrent behavior reliable.

### 1.3 Three State Layers
1) **Domain state (server):** Firestore documents (truth).
2) **Derived state (client):** computed view models (progress, grouping).
3) **Ephemeral UI state:** per-screen UI details (camera state, toasts, last scans).

---

## 2) Domain State Machines

### 2.1 Transfer Statuses
Allowed statuses for `transfers/{transferId}.status`:

- `new` — published, not started
- `picking` — at least one line has lock or qtyPicked > 0
- `picked` — all lines done (100% picked)
- `checking` — storekeeper started final check
- `done_verified` — completed with check
- `done_unverified` — completed without check (only storekeeper/admin)

**Invariants**
- `done_*` can only be set by storekeeper/admin.
- Partial completion is not allowed. A transfer cannot be finalized unless 100% picked.

### 2.2 Line Statuses
For `transfers/{id}/lines/{lineId}.status`:
- `open`
- `locked`
- `done`

`done` when `qtyPicked == qtyPlanned`.

---

## 3) Firestore Data Access Strategy

### 3.1 Collections
- `users/{uid}`
- `products/{article}`
- `barcode_index/{barcode}` → { article }
- `transfers/{transferId}`
- `transfers/{transferId}/lines/{lineId}`
- `transfers/{transferId}/events/{eventId}`

### 3.2 Lock Model
`lines/{lineId}.lock`:
- `userId`
- `lockedAt`
- `expiresAt` (lockedAt + 5 minutes)

A lock is considered expired if `now > expiresAt`.

---

## 4) Riverpod Provider Graph

### 4.1 Auth & Role
- `authStateProvider`: Stream<User?>
- `userProfileProvider(uid)`: Stream<UserProfile>
- `currentRoleProvider`: derived from user profile

Used for routing, UI gating, and write permissions.

### 4.2 Transfers List
- `transferQueryFilterProvider`: UI state (status filter, search text)
- `transfersListProvider(filter)`: Stream<List<Transfer>>

Derived:
- `transfersListViewModelProvider`: groups transfers, adds badges, etc.

### 4.3 Transfer Details (Card)
- `transferDocProvider(transferId)`: Stream<Transfer>
- `transferLinesProvider(transferId)`: Stream<List<TransferLine>>

Derived:
- `transferProgressProvider(transferId)`:
  - total lines
  - done lines
  - percent complete
  - grouped by category

- `transferActiveWorkersProvider(transferId)`:
  - set of userIds from active locks

### 4.4 Catalog & Barcode Lookup
- `productByArticleProvider(article)`: Stream<Product?>
- `catalogSearchProvider(query)`: Stream<List<Product>> (admin)
- `articleByBarcodeProvider(barcode)`: Future<String?> using `barcode_index/{barcode}`

Barcode lookup must be O(1). Do not use array-contains for barcode searches.

---

## 5) Command Services (Write Layer)

### 5.1 PickingService
Responsibilities:
- acquire/release/extend locks
- scan for a locked line
- write audit events

Key methods:
- `acquireLock(transferId, lineId)`
- `releaseLock(transferId, lineId)`
- `scanForLine(transferId, lineId, barcode)`
- `extendLockIfNeeded(transferId, lineId)` (optional)

All methods that modify Firestore must use transactions.

### 5.2 CheckingService
Responsibilities:
- start checking
- scan checks
- finalize transfer

Key methods:
- `startChecking(transferId)`
- `scanCheck(transferId, lineId, barcode)`
- `finishVerified(transferId)`
- `finishUnverified(transferId)`

### 5.3 TransferStatusService (optional but recommended)
- `markPickingIfEligible(transferId)`
- `markPickedIfEligible(transferId)`

**Preferred approach:** Cloud Functions to set `picked` automatically when 100% complete.
MVP alternative: client calls `markPickedIfEligible()` when derived state becomes 100%.

---

## 6) Prepare → Scan → Commit Flow

### 6.1 Prepare (Acquire Lock)
UI action: press “Prepare” on a line.

Transaction:
- if line.status == open and lock is null OR expired:
  - set lock {userId, lockedAt, expiresAt}
  - set status = locked
  - create event `lock_acquired`
- else:
  - show UI “Locked by {user}”

### 6.2 Scan
Scan pipeline:
1) Camera returns barcode
2) Validate barcode format (EAN-13, optionally EAN-8)
3) Lookup `barcode_index/{barcode}` → article
4) Verify article matches selected line.article
5) Transaction:
   - verify lock.userId == current user (or admin/storekeeper override)
   - verify qtyPicked < qtyPlanned
   - increment qtyPicked
   - if qtyPicked == qtyPlanned:
       set status = done
       clear lock
   - write event `scan_success`
   - on failure write `scan_error` (optional)

Unknown barcode or mismatching article → UI error, no qty changes.

### 6.3 Auto “Picked” Status
When all lines are done (100%):
- transfer.status becomes `picked`.

Recommended: Cloud Function triggers on lines changes and updates transfer status.
MVP: client calls `markPickedIfEligible(transferId)` when derived progress hits 100%.

---

## 7) Lock Timeout Strategy

Lock timeout is 5 minutes.

UI behavior:
- If lock expired: show line as available with a “Take” button.
- Allow a user to acquire the lock via transaction if expired.

Optional server cleanup:
- scheduled Cloud Function clears expired locks periodically (nice-to-have).

---

## 8) Offline Policy (MVP)

Goal: tolerate temporary network drops without corrupting workflow.

### 8.1 Allowed offline actions
- Continue scanning ONLY for lines already locked by the same user (best-effort).
- Queue scan attempts locally if write fails.

### 8.2 Disallowed offline actions
- acquiring new locks
- publishing transfers
- finalizing transfers

### 8.3 Sync behavior
When back online:
- replay queued scans
- if conflict detected (line already done):
  - log an event `sync_conflict`
  - show a visible warning to storekeeper

Local scan queue storage: Hive/SQLite/Isar (implementation choice).

---

## 9) UI State Guidelines

Ephemeral UI state (should NOT go to Firestore):
- selected tab/filter
- camera enabled/disabled
- last scan result toast/snackbar
- animation triggers
- local sound/vibration preferences (these go to user settings doc)

---

## 10) Testing Checklist (for each sprint)

- Multi-user: two devices lock different lines simultaneously
- Conflict: two users attempt same line lock
- Expired lock takeover works
- Unknown barcode rejected
- Wrong barcode rejected
- Overpick rejected (qtyPicked cannot exceed qtyPlanned)
- Auto-picked triggers correctly at 100%
- Storekeeper can finish verified/unverified; loader cannot
- Offline: scanning a previously locked line queues and syncs safely


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
