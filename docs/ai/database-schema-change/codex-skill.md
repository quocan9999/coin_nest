---
name: coinnest-sqlite-schema-change
description: Use when working in the CoinNest Flutter repo and changing SQLite schema, database tables, columns, indexes, seed data, DAOs, models, or migrations. Guides Codex to always bump AppConstants.dbVersion for schema changes and keep lib/database/database_helper.dart, models, DAOs, providers, migrations, and demo APK reset behavior consistent.
---

# CoinNest SQLite Schema Change

Use this workflow for any change that touches local SQLite structure or data contracts:

- New table.
- New column.
- Removed or renamed column.
- Changed CHECK constraint, foreign key, index, default value, or seed data.
- New DAO/model field that must be stored in SQLite.
- Any code that reads or writes a new database field.

## Source Files

Always inspect these first:

- `lib/database/database_helper.dart`
- `lib/utils/constants.dart`
- Related files in `lib/database/`
- Related files in `lib/models/`
- Related providers/screens/services that read or write the changed data

## Team Policy

CoinNest is not released to real users yet, but every SQLite schema change must still bump `AppConstants.dbVersion`. Treat the database version as the team's schema-change signal, not only as a production migration tool.

During active development, the team may still clear app data or uninstall the app after schema changes so `onCreate` rebuilds the SQLite database. That reset shortcut does not replace bumping `dbVersion`.

Every schema change must leave a clear trace:

- Increment `AppConstants.dbVersion`.
- Keep `_createAllTables` as the full latest schema for clean installs.
- Keep `_createIndexes` as the full latest index list.
- Decide whether the new version gets a preserving migration or a documented reset-data requirement.
- Document reset-data requirements in the final response.

## Preferred Workflow

1. Identify the schema delta:
   - Table added/removed.
   - Column added/removed/renamed.
   - Constraint/default/index/seed changed.
   - DAO/model/provider affected.

2. Update the latest clean-install schema:
   - Put new tables and columns in `_createAllTables`.
   - Put indexes in `_createIndexes`.
   - Put seed data in the existing seed methods.
   - Keep table names, column names, and Dart map keys consistent.

3. Bump database version:
   - Increment `AppConstants.dbVersion` for every schema change.
   - Use the next integer version.
   - Mention the old and new version in the final response.

4. Choose migration strategy for the new version:
   - For dev-only work: it is acceptable for the version block to require clear app data instead of preserving old data, but the reset requirement must be explicit.
   - For demo APK or release candidate: add a versioned migration in `_migratePreservingData` whenever possible, or explicitly require uninstall/clear-data before installing the demo.
   - For already-released builds: never rely only on clear app data; write additive migrations where possible.

5. If using migration:
   - Add `if (oldVersion < N)` block in `_migratePreservingData`.
   - Use helper methods such as `_addColumnIfMissing` for additive columns.
   - Use `CREATE TABLE IF NOT EXISTS` for new tables.
   - Recreate indexes after migration.
   - Avoid destructive migration unless the project owner explicitly accepts data loss.

6. Update data access:
   - Update model `fromMap`, `toMap`, and `copyWith` if applicable.
   - Update DAO queries, inserts, updates, joins, and aggregation reports.
   - Update providers/services so UI state matches stored data.
   - Check foreign-key side effects such as `ON DELETE CASCADE` and `ON DELETE SET NULL`.

7. Validate logically without running slow commands unless requested:
   - Compare all columns used in Dart against `_createAllTables`.
   - Check required columns have values on insert.
   - Check nullable Dart fields match nullable SQLite columns.
   - Check new relationship deletes do not leave wrong account balances or stale rows.

## Demo APK Rule

Before exporting an APK for demo, apply this stricter rule:

- Ensure `dbVersion` has been incremented for every schema change included in the demo branch.
- Ensure `_createAllTables` can create a fresh database from zero.
- Ensure `_migratePreservingData` can handle the previous internal demo version, or explicitly require app data reset before installing the demo APK.
- Mention the required reset/migration behavior in the handoff.

## Final Response Checklist

When finishing a database schema task, report:

- Tables/columns/indexes changed.
- Old and new `dbVersion`.
- Whether users/devs must clear app data.
- Any DAO/model/provider files updated.
- Any validation not run.
