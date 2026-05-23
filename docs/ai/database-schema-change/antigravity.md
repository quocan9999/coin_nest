# Antigravity Agent Rule: CoinNest SQLite Schema Changes

## Scope

Use this rule for CoinNest tasks that modify SQLite schema or stored data contracts:

- Add/change/remove table.
- Add/change/remove column.
- Add/change index, foreign key, CHECK constraint, default value.
- Add/change seed categories/accounts.
- Add/change DAO queries or model map fields.

## Repo Context

Important files:

- `lib/database/database_helper.dart`
- `lib/utils/constants.dart`
- `lib/database/*_dao.dart`
- `lib/models/*.dart`
- Related providers/services/screens

CoinNest uses `sqflite`. `DatabaseHelper` is the schema owner. `AppConstants.dbVersion` controls `onUpgrade`. `_createAllTables` is the clean-install schema.

## Team Development Rule

The app is not released yet, but every SQLite schema change must increment `AppConstants.dbVersion`. Use `dbVersion` as the team-wide schema-change signal.

During normal development, the team may reset local app data after schema changes. This makes SQLite run `onCreate` and rebuild the latest schema. That reset shortcut does not replace bumping `dbVersion`.

That is acceptable only if the handoff clearly says:

- Whether reset app data is required.
- Old and new `dbVersion`.
- Whether a migration was added or intentionally skipped.

## Best-Practice Flow

1. Inspect current schema:
   - Read `database_helper.dart`.
   - Read `constants.dart`.
   - Read affected DAO/model/provider.

2. Update clean install:
   - Add latest table/column definitions to `_createAllTables`.
   - Add latest indexes to `_createIndexes`.
   - Add seed data to existing seed methods.

3. Bump version:
   - Increment `AppConstants.dbVersion` by 1 for every schema change.

4. Decide migration:
   - Internal dev only: reset-data can be acceptable, but the version still changes.
   - Demo APK: add migration when possible, or explicitly require reset before demo install.
   - Released app: preserve data.

5. Keep code in sync:
   - Model `fromMap` and `toMap`.
   - DAO insert/update/query methods.
   - Provider state and service logic.
   - Report queries and balance side effects.

6. Check data consistency:
   - Required SQLite fields are inserted.
   - Dart nullable fields match SQLite nullable columns.
   - Foreign keys do not orphan important data unexpectedly.
   - Deleting records does not leave incorrect balances or stale relationships.

## Migration Pattern

For a demo-ready or release-ready schema change:

```dart
static const int dbVersion = 4;
```

Then add a version block:

```dart
if (oldVersion < 4) {
  await db.execute('CREATE TABLE IF NOT EXISTS new_table (...)');
  await _addColumnIfMissing(
    db,
    'existing_table',
    'new_column',
    "TEXT DEFAULT ''",
  );
}
```

Prefer additive migrations. Avoid dropping data unless the owner explicitly accepts it.

## Final Output Requirement

End every schema-change task with:

- Schema summary.
- `dbVersion` status.
- Migration status.
- Reset-data requirement.
- Affected DAO/model/provider/report files.
