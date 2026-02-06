# Event Types (Audit Log)

## Locking
- lock_acquired
- lock_released
- lock_expired_takeover
- lock_extended (optional)
- lock_override_by_admin

## Picking scans
- scan_success
- scan_error_invalid_format
- scan_error_unknown_barcode
- scan_error_wrong_item
- scan_error_overpick
- scan_error_not_locked

## Transfer status
- transfer_published
- transfer_auto_picked
- checking_started
- checking_skipped
- transfer_completed_verified
- transfer_completed_unverified

## Sync / Offline
- offline_scan_queued
- offline_scan_synced
- sync_conflict_detected

Payload guidelines:
- Always include transferId, lineId (if applicable), userId, timestamp.
- Include barcode/article on scan events.
