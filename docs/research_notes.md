# Research Notes (Deep Research) — Applied Decisions

Sources covered:
- Firestore realtime workflow patterns
- Mobile barcode validation strategies
- Modern UI design (2024–2026)
- Warehouse picking UX (WMS)
- Admin dashboard upload UX

## A) Warehouse Picking UX (WMS)
Key findings:
- Scan-first workflows outperform tap-heavy flows.
- “Minimum Viable Context” reduces cognitive load and errors.
- Thumb-zone primary actions are mandatory for fatigue/gloves/gun-grip patterns.
- Strong multi-sensory feedback (haptics + visual + optional audio) improves throughput.
Applied:
- Prepare -> auto open scanner
- Auto-advance on success
- Large bottom actions
- Exception-first error screens

## B) Barcode Validation
Key findings:
- Structural validation prevents “serial number mis-scan”.
- EAN-13 checksum validation recommended.
- Clear error messaging + quick retry loop required.
Applied:
- Client validates EAN-13/EAN-8 structure + checksum
- Firestore rules validate numeric + length only (cheap gate)
- Unknown barcode produces scan_error and does not increment qty

## C) Modern UI (2024–2026)
Key findings:
- Expressive minimalism: depth as function (not decoration)
- Spring-based motion improves interruptibility and “alive” feel
- Dark mode high-contrast is functional in variable lighting
Applied:
- Material 3 style with tasteful elevation
- Motion via spring curves where possible
- Dark mode supported from day 1

## D) Admin Upload UX
Key findings:
- Import must be a narrative pipeline: Upload → Preview → Validate → Commit
- Focus Mode (hide nav) reduces abandonment and errors
Applied:
- Web panel uses stepper flow
- Clear exit hatch
- Row-level validation errors

## E) Firestore Realtime & Cost Control
Key findings:
- Events should be cold, not streamed
- Denormalized stats are needed for cheap lists
Applied:
- transfer.stats cache
- events: log errors and lifecycle only
- success scans aggregated via pickedBy map
