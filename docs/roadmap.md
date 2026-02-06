# Roadmap (MVP-1)

## Sprint 0 — Foundation
- Clean project structure, naming, package id (non com.example)
- Firebase dev/prod separation
- Base Firestore rules skeleton by roles
- Docs folder introduced (this repo)

Definition of Done:
- App builds on Android
- Auth works
- Role-based routing works

## Sprint 1 — Catalog + Barcode Binding
- Import initial products dataset (from "Остатки" excel)
- Product search screen
- Bind barcode flow (scan -> validate -> save)
- barcode_index enforcement

DoD:
- Admin can bind barcode to an article
- Unknown/invalid barcode rejected
- Barcode uniqueness enforced

## Sprint 2 — Web Upload + Preview + Publish Transfers
- Web panel: upload excel, parse, show preview
- Validation errors shown
- Publish creates transfer + lines in Firestore

DoD:
- Transfer appears on mobile immediately after publish

## Sprint 3 — Mobile Transfer List + Details
- Transfer list by status
- Transfer details: categories, progress, active workers
- Realtime updates via streams

DoD:
- Multiple devices see consistent updates

## Sprint 4 — Picking System (Locks + Scanning)
- Prepare lock (5 min), cancel, timeout handling
- Scan for locked line: qtyPicked increments via transaction
- Line done at qtyPlanned
- Transfer auto moves to picked at 100%

DoD:
- Overpick prevented
- Wrong barcode prevented
- Lock conflicts handled

## Sprint 5 — Checking + Finalization
- Storekeeper start checking
- Verified/unverified completion
- Audit view (events timeline)

DoD:
- Loaders cannot finalize
- Completion metadata recorded

## Sprint 6 — Notifications
- FCM tokens
- Cloud Functions or server triggers
- Push rules: publish/picked/done_unverified

DoD:
- Push arrives to correct roles

## Sprint 7 — Polish + Release
- UI kit applied everywhere
- i18n fully wired
- Performance pass
- Release build (APK/AAB)
- App icon and splash

DoD:
- Release build installed and tested on real devices
