# Architecture Contract (Source of Truth)

This file is the authoritative contract for the project architecture.
Any implementation must follow this contract first. If code conflicts with it,
the contract wins and code must be adjusted.

## 0) Project Goal
Build a warehouse helper app for Sopac operations:
- Parse transfer Excel (via web admin)
- Create transfer cards (tasks)
- Multi-user picking with barcode scanning
- Optional storekeeper verification
- Prevent wrong item/qty shipments (overpick/underpick/mismatch)

## 1) Roles & Permissions
Roles: `admin`, `storekeeper`, `loader`, `guest`.

- admin: full access, can edit catalog, rebind barcodes, override locks
- storekeeper: can publish transfers, can verify/complete transfers, can manage catalog (optional)
- loader: can pick items (lock line + scan increments), cannot complete verified/unverified transfer
- guest: minimal read-only (optional; can be disabled)

## 2) Free Tier First (Firebase Spark Constraints)
MVP must remain within free tier usage by design:
- Transfers list streams only `transfers` with `limit(20/50)`
- Do NOT stream `events` for loaders (events are cold)
- Lines are streamed ONLY while Transfer Details screen is open
- Excel files are NOT stored in Firebase Storage (parse client-side in web)
- Avoid per-scan projection updates across multiple documents

## 3) Data Model: Hot / Projection / Cold
### Hot (Operational)
`transfers/{transferId}/lines/{lineId}`:
- lock
- qtyPicked
- status open|locked|done
- pickedBy map + lastPickedAt (instead of scan_success events)

### Projection (Read model)
`transfers/{transferId}`:
- status + minimal metadata + flags
MVP list shows STATUS ONLY (no numeric progress bar on list).

### Cold (History)
`transfers/{transferId}/events/{eventId}`:
- log lifecycle + lock actions + scan errors + sync conflicts
- never realtime for loaders, load with pagination

## 4) Picking Workflow (Scan-first)
- Transfer opened → items grouped by category
- Loader taps "Prepare" on a line → line becomes locked (expiresAt)
- App immediately opens scanner (scan-first)
- Successful scan increments qtyPicked by 1 (transaction)
- When qtyPicked reaches qtyPlanned → line becomes done and lock clears
- Cancel preparation exists (release lock)

Multi-user rule:
- Only one loader can work a line at a time (lock with expiry)

## 5) Barcode Rules
- Use only customer product barcode (single barcode per product)
- Barcode lookup: `barcode_index/{barcode} -> article` (O(1))
- Client validates EAN-13/EAN-8 format (checksum in client)
- Firestore rules validate numeric + length only (cheap gate)

Unknown barcode handling:
- do not increment picking
- log scan_error_unknown_barcode
- mark transfer flag `needsCatalogAttention = true`

## 6) Status Transitions (MVP)
Statuses: `new`, `picking`, `picked`, `checking`, `done_verified`, `done_unverified`.

MVP rules:
- loaders cannot set `picked` or complete transfer
- storekeeper/admin can set:
  - `checking`
  - `done_verified`
  - `done_unverified`
- `picked` is set by storekeeper/admin when they confirm all lines are done (no Cloud Functions required for MVP)

## 7) Offline Policy (MVP-safe)
- If offline: user cannot acquire new locks
- Offline scanning only allowed for lines already locked by same user (queue locally)
- On reconnect: replay queued scans; conflicts logged as `sync_conflict_detected`

## 8) Non-negotiable Safety Rules
- lock includes expiresAt (no ghost locks)
- lock/qtyPicked changes must be transactional
- qtyPicked cannot exceed qtyPlanned
- events do not log every success scan (cost control)
- list screen never reads lines per card

## 9) Implementation Conventions
- Flutter + Riverpod (state management)
- Firestore structure follows docs/data_model.md
- UI flows follow docs/ui_flow.md
- Any changes must update:
  - docs/architecture_contract.md
  - docs/decisions_log.md (if decision-level change)
