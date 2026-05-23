# Claude Code Instruction: CoinNest SQLite Schema Changes

Use this instruction whenever a task changes CoinNest local SQLite schema or database contracts.

## Trigger

Follow this when changing:

- `lib/database/database_helper.dart`
- `lib/utils/constants.dart` database version/name
- Any `*_dao.dart`
- Any model `fromMap`, `toMap`, or stored field
- SQLite tables, columns, indexes, foreign keys, CHECK constraints, defaults, or seed data

## Required Context

Read these before editing:

- `lib/database/database_helper.dart`
- `lib/utils/constants.dart`
- The affected DAO in `lib/database/`
- The affected model in `lib/models/`
- The affected provider/service/screen that reads or writes the data

## Policy

The app has not been released to real users yet, but every SQLite schema change must still increment `AppConstants.dbVersion`. Use `dbVersion` as the team-wide signal that the schema changed.

During normal development, the team may clear app data or uninstall the app after schema changes so `onCreate` rebuilds SQLite. That reset shortcut does not replace bumping `dbVersion`.

For work that may be used in a demo APK, treat schema changes more carefully:

- Always increase `AppConstants.dbVersion`.
- Keep `_createAllTables` as the latest full schema for fresh installs.
- Add a clear migration in `_migratePreservingData` when preserving demo data matters.
- If no migration is added, explicitly say that app data must be cleared after installing the build.

## Implementation Rules

- Do not scatter schema creation outside `DatabaseHelper`.
- Add new tables/columns to `_createAllTables`.
- Add new indexes to `_createIndexes`.
- Add default categories/accounts through existing seed methods.
- Keep column names consistent across SQL, DAO maps, and model maps.
- Keep nullability consistent between SQLite and Dart fields.
- Prefer additive migrations: `ALTER TABLE ADD COLUMN`, `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`.
- Do not drop user data unless the owner explicitly accepts reset-data behavior.
- Check foreign key delete behavior before changing `ON DELETE`.
- If a table affects balances or reports, inspect the related DAO/provider/report query too.

## Migration Decision

Use this decision path:

1. For every schema change:
   - Increment `AppConstants.dbVersion` by 1.
   - Update the latest clean-install schema.

2. If this is a throwaway internal dev branch and team accepts clearing app data:
   - Keep the migration minimal if appropriate.
   - State: "Clear app data/uninstall app is required after pulling this schema change."

3. If this is for demo/export APK:
   - Add an `if (oldVersion < N)` migration block, or explicitly require reset before demo install.

4. If this is after release:
   - Preserve data with migrations.
   - Avoid destructive reset.

## Final Handoff

Always include:

- Schema files changed.
- Old and new `dbVersion`.
- Reset-data requirement.
- Migration behavior.
- Files that must stay in sync: model, DAO, provider, report query, UI.
