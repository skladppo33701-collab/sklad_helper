# Event Types (Audit Log) — Cost-Optimized

Цель: сохранить разборы и контроль качества, но не сжечь Spark-лимиты.
Принцип: **events = cold data** (пишем выборочно, читаем по запросу, НЕ realtime).

## 1) What we log (MVP)
### Locking
- lock_acquired
- lock_released
- lock_expired_takeover
- lock_override_by_admin

### Scan errors (always log)
- scan_error_invalid_format
- scan_error_unknown_barcode
- scan_error_wrong_item
- scan_error_overpick
- scan_error_not_locked

### Transfer lifecycle
- transfer_published
- checking_started
- checking_skipped
- transfer_completed_verified
- transfer_completed_unverified

### Offline / Sync
- offline_scan_queued
- offline_scan_synced
- sync_conflict_detected

## 2) What we DO NOT log (MVP)
- scan_success for every unit — **НЕ логируем поштучно**.
  Вместо этого храним агрегаты в line (см. data_model.md):
  - pickedBy.{uid}: int
  - lastPickedAt: timestamp

## 3) Payload guidelines
Каждый event содержит:
- type
- userId
- timestamp
- payload (map), минимум:
  - transferId
  - lineId (если применимо)
  - barcode (для scan_error_*)
  - article (если найден)
  - errorCode (для ошибок)
  - qtyBefore/qtyAfter (если меняли количество)

## 4) Read policy (важно для Spark)
- Loaders: events НЕ слушают realtime.
- Storekeeper/Admin: история грузится по кнопке “История”:
  - limit(50) + пагинация "ещё".
