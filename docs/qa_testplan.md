# QA Test Plan (MVP-1)

## Multi-user concurrency
- Two loaders lock different lines simultaneously -> OK
- Two loaders try to lock same line -> only one succeeds
- Lock expires -> another loader can take it

## Scanning correctness
- Valid EAN-13 barcode mapped to correct article -> increments qtyPicked
- Unknown barcode -> error, no qty changes
- Wrong barcode for selected line -> error, no qty changes
- Overpick attempt -> rejected, logged

## Transfer status automation
- When all lines done -> transfer becomes picked automatically
- Storekeeper start checking only when picked
- Storekeeper finalize verified/unverified
- Loader cannot finalize (permission denied)

## Offline scenarios
- Go offline after locking a line -> scanning queues
- Restore connection -> queued scans sync
- Conflict case -> sync_conflict logged and shown

## Web upload
- Parsing error blocks publish
- Preview matches excel content
- Publish creates transfer visible on mobile

## Localization
- Switch ru/kk/en -> UI updates correctly
- Statuses and error messages localized
