# Firebase Rules Plan (Conceptual)

This is a plan for Firestore security rules (not the final code).

## General
- All access requires authenticated user, except optional guest mode.
- User role is read from `users/{uid}.role`.
- Users must have `users/{uid}.isActive == true` to write.

## users/*
- User can read own profile.
- Admin can read/write any profile.
- Storekeeper can read other users (optional).
- Role changes restricted to admin.

## products/*
- Read allowed to loaders/storekeepers/admin.
- Write allowed to admin (and optionally storekeeper) only.

## barcode_index/*
- Read allowed to authenticated roles (needed for scanning).
- Write allowed to admin/storekeeper for binding.
- Enforce docId uniqueness by design.

## transfers/*
- Read allowed to all authenticated roles (or loaders+).
- Create/publish allowed to storekeeper/admin only.
- Updates to `status` only allowed:
  - storekeeper/admin for checking/finalization
  - server function for auto-picked (preferred)
- Loaders cannot set done_*.

## transfers/*/lines/*
- Read allowed to all authenticated roles (or loaders+).
- Write allowed:
  - Loaders can set lock only on open/expired lines
  - Loaders can increment qtyPicked only if they own lock
  - Storekeeper/admin can override and can write checks

## transfers/*/events/*
- Create allowed to roles that performed the action.
- Read allowed to storekeeper/admin; loaders can read limited subset (optional).
