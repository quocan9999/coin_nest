---
applyTo: "lib/database/**/*.dart,lib/models/**/*.dart,lib/providers/**/*.dart,lib/services/**/*.dart,lib/screens/**/*.dart,lib/utils/constants.dart"
---

# CoinNest SQLite Schema Change Instructions

Apply these rules when a change adds, removes, renames, or changes any SQLite table, column, index, foreign key, CHECK constraint, default value, seed data, DAO query, or stored model field.

## Required Files To Check

- `lib/database/database_helper.dart`
- `lib/utils/constants.dart`
- Affected DAO files under `lib/database/`
- Affected model files under `lib/models/`
- Affected providers/services/screens that read or write the data

## Development Policy

CoinNest is still in internal development, but every SQLite schema change must increment `AppConstants.dbVersion`. The version is the team-wide signal that the local database contract changed.

It is still acceptable for developers to clear app data or uninstall the app after schema changes so SQLite runs `onCreate` again. That reset shortcut does not replace bumping `dbVersion`.

If a schema change requires reset-data, mention it in comments, PR notes, or the final handoff. For demo APK builds, add an explicit migration or a documented reset requirement.

## Schema Rules

- Keep `DatabaseHelper._createAllTables` as the complete latest schema for a fresh install.
- Keep `DatabaseHelper._createIndexes` as the complete latest index list.
- Keep seed data inside existing seed methods such as `seedDefaultCategories` and `seedDefaultAccount`.
- Keep SQL column names, DAO map keys, and model `fromMap`/`toMap` keys identical.
- Required SQLite columns must always be supplied on insert.
- Nullable SQLite columns should map to nullable Dart fields.
- Update related joins and report aggregation queries when adding relational data.
- Review foreign keys and delete behavior (`CASCADE`, `SET NULL`) before changing relationships.

## Migration Rules

When preserving data matters:

- Increment `AppConstants.dbVersion`.
- Add a versioned block in `_migratePreservingData`, for example `if (oldVersion < 4)`.
- Prefer additive migration:
  - `CREATE TABLE IF NOT EXISTS`
  - `ALTER TABLE ... ADD COLUMN`
  - `CREATE INDEX IF NOT EXISTS`
- Use `_addColumnIfMissing` for new optional/defaulted columns.
- Avoid destructive migration unless the project owner explicitly approves data loss.

When preserving data does not matter:

- Still increment `AppConstants.dbVersion`.
- It is acceptable during internal development to rely on reset-data instead of a preserving migration.
- State clearly that developers must clear app data or uninstall the app after pulling the change.

## Review Checklist

Before considering a schema change complete, verify:

- Clean install path creates all new tables, columns, constraints, and indexes.
- Existing database path is either migrated for the new `dbVersion` or explicitly reset-only.
- Models, DAOs, providers, and report queries are in sync.
- Account balances, transaction history, and foreign-key deletes remain consistent.
- The handoff states the old/new `dbVersion` and whether app data reset is required.
