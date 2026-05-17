# CoinNest Copilot Instructions

## Project overview
CoinNest is a Flutter personal finance / expense tracking app. The repository uses Flutter and Dart for the app, Provider for state management, `sqflite` for local storage, and Firebase (`firebase_core`, `firebase_auth`, `cloud_functions`, `firebase_storage`, `google_sign_in`) for backend integration. It also uses `intl`, `google_fonts`, `fl_chart`, `shared_preferences`, and `flutter_secure_storage`. The repo includes Android, iOS, web, macOS, Linux, and Windows folders, so treat it as cross-platform Flutter. A separate `functions/` directory contains Firebase Cloud Functions support code.

## Architecture and folder layout
- `lib/main.dart`: app bootstrap; initializes Firebase, Google Sign-In, locale/orientation, and registers providers in `MultiProvider`.
- `lib/app.dart`: root `MaterialApp`, app theme, and initial screen.
- `lib/screens/`: screen-level UI. Current feature folders are `accounts/`, `auth/`, `budgets/`, `categories/`, `dashboard/`, `home/`, `loans/`, `onboarding/`, `reports/`, `settings/`, `splash/`, and `transactions/`. Screen files should use `snake_case.dart` and `Screen` widget names, for example `lib/screens/auth/login_screen.dart`.
- `lib/providers/`: `ChangeNotifier` classes and feature state. Existing providers cover auth, accounts, transactions, categories, loans, budgets, reports, and settings.
- `lib/models/`: plain data models and entities such as `account`, `budget`, `category`, `loan`, `loan_payment`, `transaction_model`, and `user`.
- `lib/database/`: SQLite helper and DAO layer. Keep database access, queries, and transaction logic here.
- `lib/services/`: integrations and service wrappers. Authentication services currently live in `lib/services/auth/`; follow that pattern for other external integrations.
- `lib/theme/`: shared design tokens and `AppTheme`.
- `lib/utils/`: stateless helpers such as validators, formatters, constants, security helpers, phone utilities, and category icons.
- There is no dedicated `lib/widgets/` folder or central `lib/routes/` folder yet. Keep small widget helpers local to their screen when they are not shared; add a dedicated shared folder only when reuse justifies it.

## State management rules
Use Provider with `ChangeNotifier` for feature state. Keep mutable state, async orchestration, and business logic in providers or services instead of screen widgets. Do not introduce Riverpod, Bloc, GetX, Redux, MobX, or another state library unless the project owner explicitly asks. Register new providers in `lib/main.dart` inside the existing `MultiProvider`; follow the current pattern where `AuthProvider` is created with `FirebaseAuthService`. Keep UI widgets focused on rendering and interaction.

## UI rules
For any UI work, first read `.github/instructions/flutter-ui-screens.instructions.md` and follow it.

## File placement rules
- Providers: `lib/providers/<feature>_provider.dart`
- Models: `lib/models/<model_name>.dart`
- Database helpers and DAOs: `lib/database/<name>_dao.dart` and `lib/database/database_helper.dart`
- Services: `lib/services/<feature>/<name>_service.dart`
- Reusable widgets: create `lib/widgets/<widget_name>.dart` if a widget is shared across screens; otherwise keep it private to the owning screen file
- Theme code: `lib/theme/`
- Utility/helper functions: `lib/utils/`
- If centralized routing is added later, keep it in one dedicated route module instead of scattering route tables across screens

## Style
Follow `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`. Use `snake_case.dart` for files, `UpperCamelCase` for classes/widgets, and `lowerCamelCase` for fields, variables, and methods. Provider classes should end with `Provider`, services with `Service`, and screen widgets with `Screen`. Use `_` for private fields, methods, and helper widgets. Boolean names should read clearly, such as `isLoading` or `hasError`. Prefer descriptive names, small focused widgets, and `const` constructors. Avoid duplicated logic. Do not change unrelated files, and preserve existing business logic unless the task explicitly requires it.

## Build and validation
- Always run `flutter pub get` after editing `pubspec.yaml` or changing dependencies.
- Always run `dart format .` after finishing code changes.
- Always run `flutter analyze` before considering a task complete.
- Run `flutter test` when tests exist or when you change logic that is covered by tests. No top-level `test/` suite was found in this repository at present.
- No `build_runner` or other code-generation workflow was found in the inspected files. If generated code is added later, document the exact generation command next to that code.
- If you touch `functions/`, validate it with its own npm scripts as well.

## Important files
- `pubspec.yaml`: package metadata, SDK constraint, and dependencies.
- `analysis_options.yaml`: lint entrypoint.
- `lib/main.dart`: app bootstrap and provider registration.
- `lib/app.dart`: root `MaterialApp`, theme, and initial screen.
- `lib/theme/app_theme.dart`: shared theme tokens and Material 3 theme setup.
- `DESIGN.md`: visual design system and UI direction.
- `lib/screens/AGENTS.md`: screen-specific rules for `lib/screens/**/*.dart`.
- `lib/firebase_options.dart`: generated Firebase configuration used at startup.
- `lib/database/database_helper.dart`: SQLite database entry point.
- `functions/index.js` and `functions/package.json`: Firebase Cloud Functions entrypoint and scripts.
- `README.md`: short project description only.
- No `.github/workflows/` files are currently present.
- No top-level `test/` directory is currently present.

## Final instruction
Trust these instructions first. Follow the existing architecture before introducing new patterns. Search the repository only when these instructions are incomplete or when existing code contradicts them. If a requested change conflicts with these instructions, explain the conflict before implementing it.