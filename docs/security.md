# Security & Permissions (Product Level)

## Role capabilities

### Loader
- Read: transfers, lines, limited events
- Write:
  - acquire/release locks on lines
  - increment qtyPicked on locked lines owned by self
  - create scan events (success/error)
- Cannot:
  - publish transfers
  - finalize transfers
  - edit products catalog

### Storekeeper
- All loader actions
- Publish transfers (web)
- Start checking
- Finalize transfers verified/unverified
- Edit products if granted (optional; otherwise admin-only)

### Admin
- Full access
- Manage users and roles
- Manage catalog + barcode index
- Override locks
- Repair data (if needed) with audit events

### Guest
- Read-only (limited)

## Audit requirements
All write actions must produce events:
- lock acquired/released
- scan success/error
- checking started/skipped
- transfer finalized
- admin override actions
