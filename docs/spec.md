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
