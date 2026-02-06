# Release Plan (MVP-1)

## Environments
- Firebase dev project
- Firebase prod project

## Android
- Update applicationId to production value
- Configure signing keys
- Build AAB for Play (optional) and APK for sideload testing

## Pre-release checklist
- rules reviewed
- crash-free test run
- offline test
- permissions: camera, notifications
- localization sanity check
- app icon + splash

## Rollout
- internal test group first
- then warehouse-wide installation
- keep a rollback APK
