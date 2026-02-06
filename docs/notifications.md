# Notifications Plan — Free Tier First

Goal: keep team informed without requiring Cloud Functions or billing.

## MVP (no auto-push)
### In-app notifications
Generated from Firestore state (cheap):
- New transfer published → appears on Transfers list with status `new`
- Picked (100%) → storekeeper sees badge on transfer card
- Done_unverified → admin/storekeeper sees warning badge

UI behaviors:
- snack/toast on important changes (only while app open)
- unread badge count (derived, optional)

## Later (optional)
Push via FCM + Cloud Functions:
- Transfer published → loaders
- Transfer picked → storekeeper
- Done_unverified → admin
Only add after system stabilizes and you accept billing risk.
