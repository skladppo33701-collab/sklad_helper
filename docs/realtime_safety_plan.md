# Realtime Safety Plan (Flutter + Firestore + Cloud Functions)

This document defines mandatory rules to avoid common realtime bugs:
- race conditions
- ghost locks
- incorrect status transitions
- offline desynchronization
- barcode mapping inconsistencies

It is a non-negotiable contract for implementation.

---

## 1) Responsibility Split (Who can change what)

### Client (Mobile/Web UI)
Client is allowed to write ONLY:
- `transfers/{id}/lines/{lineId}.lock`
- `transfers/{id}/lines/{lineId}.qtyPicked` (via transaction only)
- `transfers/{id}/events/{eventId}` (audit logs)
- `transfers/{id}.status` ONLY for:
  - `checking`, `done_verified`, `done_unverified` AND only by storekeeper/admin
  - (recommended: finalization via server as well, see section 6)

Client is NOT allowed to:
- set `transfers/{id}.status = picked`
- set any status based purely on client-side derived progress

### Server (Cloud Functions)
Server is responsible for global truth:
- set `transfer.status = picked` when 100% lines are done
- maintain transfer stats (doneLines/totalLines) for fast UI
- send push notifications for key events
- optional cleanup of expired locks

---

## 2) Mandatory Atomicity (Transactions everywhere it matters)

### 2.1 Lock acquisition MUST be transactional
When a user presses "Prepare", run a Firestore transaction:
- read line doc
- validate lock is null OR expired
- set lock with expiresAt
- set line status = locked
- write event `lock_acquired`

If lock exists and is not expired:
- transaction fails and UI shows lock owner

### 2.2 qtyPicked increment MUST be transactional
When scanning for a line, run a Firestore transaction:
- read line doc
- validate lock belongs to caller (or override role)
- validate qtyPicked < qtyPlanned
- increment qtyPicked by exactly 1
- if qtyPicked == qtyPlanned after increment:
  - set status = done
  - clear lock
- write event `scan_success`

Any validation failure produces:
- no qty change
- optional event `scan_error_*`

### 2.3 Prevent overpick by design
In transaction:
- `qtyPicked` MUST NEVER exceed `qtyPlanned`

---

## 3) Lock Model (No ghost locks)

### 3.1 Lock structure
`lock: { userId, lockedAt, expiresAt }`

### 3.2 Lock timeout
- default: 5 minutes
- lock is considered expired if `now > expiresAt`

### 3.3 Lock takeover
A user may take over an expired lock only via transaction:
- read lock
- confirm expired
- overwrite lock with new userId and expiresAt
- write event `lock_expired_takeover`

### 3.4 Lock release
Allowed:
- lock owner
- storekeeper/admin (override)

Write event `lock_released` or `lock_override_by_admin`.

### 3.5 Optional lock cleanup (server)
Scheduled function (every 5 minutes):
- remove expired locks
- write event `lock_cleared_by_server` (optional)

---

## 4) Barcode Mapping Safety

### 4.1 Canonical mapping: barcode_index
Use:
- `barcode_index/{barcode} -> { article }`

Constraints:
- 1 barcode maps to exactly 1 article
- barcode is stored as documentId for O(1) lookup

### 4.2 Barcode validation
MVP supports:
- EAN-13 (required)
- optionally EAN-8

Reject:
- non-numeric
- wrong length
- invalid check digit
- known serial number formats (if applicable)

### 4.3 Binding rules
Binding a barcode:
- validate format
- check barcode_index doc does not exist
- create barcode_index doc
- update product.barcode
- write event `barcode_bound`

If already exists:
- show conflict message
- allow admin-only "rebind" path with audit event `barcode_rebound_by_admin`

---

## 5) Transfer Status Safety

### 5.1 Transfer statuses
- `new`
- `picking`
- `picked`
- `checking`
- `done_verified`
- `done_unverified`

### 5.2 picked status MUST be server-set
Only Cloud Function is allowed to set `picked`.

Client must never set `picked`.

### 5.3 done_* statuses
Only storekeeper/admin may set:
- `done_verified`
- `done_unverified`

Rules:
- transfer must be in `picked` or `checking`
- completion must write event:
  - `transfer_completed_verified` or `transfer_completed_unverified`

### 5.4 picking status
May be set when:
- first lock is acquired OR first qtyPicked > 0

Recommended:
- server sets `picking` on first line activity

---

## 6) Server Responsibilities (Minimal Cloud Functions Set)

### 6.1 onLineWrite (core)
Trigger: create/update of `transfers/{id}/lines/{lineId}`

Responsibilities:
- recompute transfer stats:
  - totalLines (if not known)
  - doneLines (# lines where status == done)
- if doneLines == totalLines:
  - set transfer.status = `picked`
  - set pickedAt timestamp
  - write event `transfer_auto_picked`
  - send push to storekeeper

Optional:
- if first activity detected:
  - set transfer.status = `picking`

### 6.2 onTransferPublished
Trigger: transfer published (`publishedAt` set OR status becomes `new` with published flag)

Responsibilities:
- send push to loaders
- create event `transfer_published`

### 6.3 onTransferCompletedUnverified
Trigger: transfer status becomes `done_unverified`

Responsibilities:
- notify admin (QC)
- create event if missing

### 6.4 scheduled lock cleanup (optional)
Trigger: cron every 5 minutes

Responsibilities:
- remove expired locks
- optionally log cleanup events

---

## 7) Offline Policy (MVP-safe)

### 7.1 Allowed offline actions
- continue scanning ONLY for lines already locked by the same user
- queue scan attempts locally if a write fails

### 7.2 Disallowed offline actions
- acquire new locks
- publish transfers
- finalize transfers

### 7.3 Sync strategy
When connection returns:
- replay queued scans sequentially
- if a scan fails due to conflict (line already done/overpick):
  - write event `sync_conflict_detected`
  - show visible warning to storekeeper/admin

---

## 8) Firestore Security Rules Expectations

Rules must enforce:
- loaders cannot set `transfer.status = picked`
- loaders can only increment qtyPicked if they own lock
- qtyPicked cannot exceed qtyPlanned
- lock can only be set if empty/expired (or override role)
- only storekeeper/admin can finalize

Security rules should be treated as the final safety net.

---

## 9) Observability & Debugging

Every critical action must produce an audit event:
- lock_acquired/released/takeover
- scan_success / scan_error_*
- transfer_published
- transfer_auto_picked
- checking_started / checking_skipped
- transfer_completed_*

Event payload should include:
- transferId, lineId
- userId
- barcode/article (for scan events)
- qtyBefore/qtyAfter (when relevant)
- errorCode (for errors)

---

## 10) Non-negotiable MUST Checklist (Updated)
- [ ] barcode_index O(1) lookup
- [ ] EAN validation in client (checksum)
- [ ] lock includes expiresAt
- [ ] lock/qtyPicked updates are transactional
- [ ] picked status cannot be set by loaders (rules)
- [ ] strict role-based security rules
- [ ] offline policy enforced in UI
- [ ] audit events for errors + lifecycle (not every success scan)
- [ ] per-line scan attribution stored as pickedBy map + lastPickedAt
