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
