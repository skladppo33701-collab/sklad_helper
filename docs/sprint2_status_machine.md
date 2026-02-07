# Sprint 2: Transfer Status Machine (MVP)

## Statuses
- `new`
- `picking`
- `picked`
- `checking`
- `done`

## Allowed transitions (MVP)
Forward-only:
- `new` -> `picking`
- `picking` -> `picked`
- `picked` -> `checking`
- `checking` -> `done`

Optional fast close (admin/storekeeper):
- `new` -> `done`

Disallowed:
- any backwards transition
- any status change by `loader`

## Role permissions
- `admin`, `storekeeper`: may move status forward per allowed transitions (and optional fast close).
- `loader`: read-only (no status writes).

## Write behavior (repository)
`TransferRepository.updateStatus()` runs in a Firestore transaction:
- reads transfer
- verifies current `status == from` to prevent stale updates
- validates transition (role-aware)
- updates:
  - `status`
  - `updatedAt` (server timestamp)
  - stage timestamp when entering a stage:
    - `pickedAt` when `to == picked`
    - `checkedAt` when `to == checking`
    - `doneAt` when `to == done`

## Free-tier reads policy
- Transfers list: realtime stream ONLY `transfers` (limit N). No subcollection listeners.
- Transfer details:
  - lines are streamed only while detail screen is open (autoDispose).
  - transfer doc is fetched via one-time `get()` (no realtime watch).
- Events:
  - NOT realtime; loaded on demand via `get()` pages.
