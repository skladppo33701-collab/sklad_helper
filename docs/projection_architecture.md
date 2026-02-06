# Projection Architecture (Read Models) — Free Tier Friendly

Goal:
- Fast UI (especially Transfers list)
- Low Firestore reads
- Minimal extra writes
- Avoid streaming hot subcollections everywhere

Core idea:
- Separate **hot operational data** (lines) from **read-optimized projections** (transfer stats/flags)
- Keep events as **cold** (append-only, loaded on demand)

---

## 1) Data Layers

### 1.1 Hot (Operational)
`transfers/{transferId}/lines/{lineId}`

Changes frequently:
- locks
- qtyPicked increments
- line status (open/locked/done)

Only read/stream while Transfer Details screen is open.

### 1.2 Projection (Read Model)
`transfers/{transferId}`

Changes rarely:
- stats cache (doneLines/totalLines)
- flags (attention/conflicts)
- lifecycle transitions (checking/done_*)

This is what Transfers list streams.

### 1.3 Cold (History)
`transfers/{transferId}/events/{eventId}`

Append-only, loaded on demand with pagination.
Never streamed in realtime for loaders.

---

## 2) What Projections We Keep (Minimal Set)

## MVP decision
Transfers list shows status only ("New/In progress/Picked/Done").
Exact progress is computed only inside Transfer Details by reading lines.
No stats projection updates in MVP to keep rules and writes minimal.

### 2.1 transfers.stats (list-grade metrics)
Required fields:
- totalLines: int                // set on publish
- doneLines: int                 // increment only when a line becomes done
- totalUnitsPlanned: int         // set on publish
- lastActivityAt: timestamp      // update on rare events only (e.g. line done, manual actions)

Optional fields (can be omitted in MVP):
- totalUnitsPicked: int
- activeWorkersCount: int

Cost rule:
- **Never update stats on every scan**.
- Update doneLines only when line transitions to done.
- lastActivityAt only on rare lifecycle milestones.

### 2.2 transfers.flags (badges/warnings)
- needsCatalogAttention: bool
- hasConflicts: bool
- completedUnverified: bool (or derived from status)

---

## 3) UI Read Strategy

### 3.1 Transfers List
Streams only:
- `transfers` query with `limit(20/50)` ordered by `publishedAt desc`
Uses:
- transfer.status
- transfer.stats.doneLines/totalLines
- transfer.flags

NO lines reads here.

### 3.2 Transfer Details
Streams:
- transfer doc
- lines subcollection (only while screen is visible)

Derived in client:
- category grouping
- active lock owners list
- per-category progress

### 3.3 Events
Loaded on demand:
- limit 50
- pagination with "Load more"

---

## 4) Projection Update Rules (No double counting)

### 4.1 doneLines correctness
`doneLines` must increment only when a line status changes:
- from open/locked -> done
and only once per line lifetime.

Implementation approach (no Cloud Functions):
- In the transaction that completes the final unit for a line:
  - set line.status = done
  - update transfers.stats.doneLines += 1
  - ensure the line wasn't already done (precondition from read state)

### 4.2 lastActivityAt
Update only on:
- line becomes done
- checking started / skipped
- transfer completed

Avoid updating on every scan to save writes.

---

## 5) Free Tier Guardrails
- Transfers list always uses limit.
- Lines are streamed only while the details screen is open.
- Events are never streamed by default.
- Stats writes are "rare and meaningful", not per-scan.

---

## 6) Later Upgrade (Optional)
If you enable billing or accept Functions:
- Cloud Function maintains stats and status transitions reliably server-side.
- Client writes only hot data (lines) and events.
