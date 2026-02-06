# Notifications Plan (Push + In-App)

## Push events (FCM)
1) Transfer published -> notify all loaders
2) Transfer picked (100%) -> notify storekeeper
3) Transfer completed unverified -> notify admin (quality control)
Optional:
- conflicts detected -> notify storekeeper/admin

## In-app notifications
Stored in Firestore (optional) or derived from events:
- publish
- picked
- check started
- completed verified/unverified
- conflicts

## User settings
- sound/vibration toggles
- push enabled toggle (app-side)
- language affects notification text (push may use server-side templates)
