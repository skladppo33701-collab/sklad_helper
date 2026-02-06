# Warehouse App Specification

## Core Concept

Mobile-first warehouse picking assistant focused on preventing shipment errors.

System does NOT manage stock quantities.
1C remains source of truth.

App validates:
- correct product
- correct quantity
- correct picking workflow

## Roles

Admin:
- manage catalog
- bind barcodes
- manage users
- override actions

Storekeeper:
- upload transfers
- perform final check
- complete transfers

Loader:
- pick items
- scan barcodes

Guest:
- read-only

## Workflow

1. Admin uploads Excel (web)
2. Preview → Publish
3. Transfer created

Picking:
- Loader presses "Prepare"
- Line locked for 5 minutes
- Scanner opens
- Correct scans increase qtyPicked
- When all lines done → auto status = PICKED

Checking:
- Storekeeper verifies
- Can skip check
- Final status:
    done_verified
    done_unverified

## Rules

- Barcode is primary key
- 1 barcode = 1 product
- Unknown barcode = error
