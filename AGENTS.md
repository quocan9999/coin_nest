# AGENTS.md

## Purpose

This file defines coding and project-structure rules for contributors working in this repository. Follow these rules to keep architecture, naming, and code placement consistent.

This file is the repo-level instruction source for Codex and for Antigravity when Antigravity is configured to read `AGENTS.md`.

## Project overview

CoinNest is a cross-platform Flutter personal finance app with Firebase Cloud Functions.

- App code: `lib/`
- Cloud Functions code: `functions/`
- Platforms: `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`

Tech stack in app code includes Flutter/Dart, Provider (`ChangeNotifier`), `sqflite`, Firebase (`firebase_core`, `firebase_auth`, `cloud_functions`, `firebase_storage`, `google_sign_in`), `intl`, `google_fonts`, `fl_chart`, `shared_preferences`, and `flutter_secure_storage`.

## Architecture and folder layout

- `lib/main.dart`: app bootstrap, Firebase and provider registration.
- `lib/app.dart`: root `MaterialApp`, theme, and initial screen.
- `lib/screens/`: screen-level UI by feature (`accounts`, `auth`, `budgets`, `categories`, `dashboard`, `home`, `loans`, `onboarding`, `reports`, `settings`, `splash`, `transactions`).
- `lib/providers/`: feature state using `ChangeNotifier`.
- `lib/models/`: plain data models/entities.
- `lib/database/`: SQLite helper and DAOs.
- `lib/services/`: external integration and service wrappers.
- `lib/theme/`: shared design tokens and app theme.
- `lib/utils/`: stateless utility functions.

Keep screen files focused on rendering and interaction. Move reusable business logic to providers/services/DAOs/utils.

## SQLite schema change rules

Follow these rules for any task that changes SQLite tables, columns, indexes, foreign keys, CHECK constraints, default values, seed data, DAOs, or stored model fields.

Required files to inspect before editing:

- `lib/database/database_helper.dart`
- `lib/utils/constants.dart`
- Affected DAO files in `lib/database/`
- Affected model files in `lib/models/`
- Affected providers/services/screens/reports that read or write the data

Implementation rules:

- Always increment `AppConstants.dbVersion` for every SQLite schema change.
- Keep `DatabaseHelper._createAllTables` as the complete latest schema for fresh installs.
- Keep `DatabaseHelper._createIndexes` as the complete latest index list.
- Keep seed data in existing seed methods such as `seedDefaultCategories` and `seedDefaultAccount`.
- Keep SQL column names, DAO map keys, and model `fromMap`/`toMap` keys in sync.
- Required SQLite columns must be supplied on insert; nullable SQLite columns should map to nullable Dart fields.
- Update affected model `fromMap`, `toMap`, `copyWith`, DAO insert/update/query methods, providers/services, and report queries.
- Review foreign-key delete behavior (`CASCADE`, `SET NULL`) and account-balance side effects before changing relationships.

Migration/reset policy:

- Internal development may still use clear app data or uninstall/reinstall to rebuild SQLite through `onCreate`, but this does not replace bumping `dbVersion`.
- For demo APK or release-candidate work, add a versioned migration in `_migratePreservingData` whenever possible.
- If a schema version intentionally relies on reset-data instead of preserving migration, state that clearly in the handoff.
- For released builds, preserve data with additive migrations; do not rely on app-data reset.

Database task handoff must include:

- Tables/columns/indexes changed.
- Old and new `dbVersion`.
- Whether a migration was added.
- Whether developers/testers must clear app data.
- DAO/model/provider/report files updated.

Detailed tool-specific versions live in `docs/ai/database-schema-change/`.

## State management rules

- Use Provider + `ChangeNotifier` for feature state.
- Keep mutable state, async orchestration, and business logic in providers/services, not screen widgets.
- Register new providers in `lib/main.dart` within existing `MultiProvider`.
- Follow the existing dependency-injection style (for example, providers receiving services in constructors).
- Do not introduce another state management library (Riverpod, Bloc, GetX, Redux, MobX, etc.) unless explicitly requested by the project owner.

## UI rules

Before any UI implementation: Read `lib\screens\CLAUDE.md`.

## File placement rules

Place code in the correct folder by responsibility:

- Screens: `lib/screens/<feature>/<name>_screen.dart`
- Providers: `lib/providers/<feature>_provider.dart`
- Models: `lib/models/<model_name>.dart`
- Database/DAO: `lib/database/<name>_dao.dart` and `lib/database/database_helper.dart`
- Services: `lib/services/<feature>/<name>_service.dart`
- Theme: `lib/theme/`
- Utils/helpers: `lib/utils/`

Widget reuse rule:

- If a widget is only used by one screen, keep it private in that screen file.
- If reused across screens, create `lib/widgets/<widget_name>.dart`.

Routing rule:

- If centralized routing is added, keep it in one dedicated route module.
- Do not scatter route tables across multiple screens.

## Naming and style rules

- Follow lint rules from `analysis_options.yaml` / `flutter_lints`.
- File names: `snake_case.dart`
- Classes/widgets: `UpperCamelCase`
- Fields/variables/methods: `lowerCamelCase`
- Private members: prefix with `_`
- Boolean names: clear predicates like `isLoading`, `hasError`

Conventions by type:

- Provider classes should end with `Provider`.
- Service classes should end with `Service`.
- Screen widgets should end with `Screen`.

Code-quality expectations:

- Prefer descriptive names and small focused widgets.
- Prefer `const` constructors where applicable.
- Avoid duplicated logic.
- Do not change unrelated files.
- Preserve existing business logic unless the task explicitly requires changes.

## Build and validation rules

Run the relevant checks before considering work complete:

- If dependencies changed (`pubspec.yaml`): run `flutter pub get`.
- After code changes: run `dart format .`.
- Always run: `flutter analyze`.
- Run `flutter test` when tests exist or when changing logic that is covered by tests.
- If touching `functions/`: run that package's npm validation scripts as well.

Current repository notes:

- No top-level `test/` directory is currently guaranteed.
- No code generation workflow (like `build_runner`) is currently required by default. If introduced, document exact generation commands.

## Important reference files

- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/main.dart`
- `lib/app.dart`
- `lib/theme/app_theme.dart`
- `DESIGN.md`
- `lib/screens/AGENTS.md`
- `.github/instructions/flutter-ui-screens.instructions.md`
- `lib/firebase_options.dart`
- `lib/database/database_helper.dart`
- `functions/index.js`
- `functions/package.json`

## Team workflow checklist (quick)

Before coding:

- Confirm target file belongs to correct folder by responsibility.
- Check directory-specific instructions (`AGENTS.md` / nested `CLAUDE.md`).
- For UI tasks, load design/theme instruction files first.

Before finishing:

- Ensure naming/style conventions are followed.
- Ensure business logic is not leaking into screen widgets.
- Run formatting and analysis commands.
- Run tests when applicable.

## Final rule

Prefer existing architecture and patterns over introducing new ones. If a requested change conflicts with these instructions, call out the conflict and align first before implementation.
