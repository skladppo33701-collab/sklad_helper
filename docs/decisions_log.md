# Decisions Log

Keep a running record of product/tech decisions.

## Decisions
- Barcode is primary scan key; article is reference key.
- 1 barcode -> 1 article (strict).
- Picking requires "Prepare" and lock per line.
- Lock timeout: 5 minutes.
- Auto transition to `picked` when 100% complete.
- Checking is available and can be skipped only by storekeeper/admin.
- Excel upload via web panel with preview+publish.
- No inventory quantities stored in app.
- Locales: ru default, kk/en optional.
