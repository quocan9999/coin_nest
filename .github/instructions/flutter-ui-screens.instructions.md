---
name: Flutter UI screen rules
description: Rules for editing Flutter UI screens under lib/screens
applyTo: "lib/screens/**/*.dart"
---

# Flutter UI Screen Rules

## Scope

These rules apply to Flutter UI screen files in this directory and its descendants: `lib/screens/**/*.dart`.

## Required References

Before making UI changes, inspect:

- `DESIGN.md`
- `lib/theme/app_theme.dart`

If either file is unavailable in context, ask the user to attach it or open it before editing.

## Design Compliance

UI must strictly follow `DESIGN.md`. Treat it as the source of truth for the app's visual direction, including the editorial finance style, no-line layout approach, tonal layering, typography hierarchy, spacing rhythm, and component behavior.

Colors, typography, spacing, radius, shadows, surfaces, and component styles must follow `lib/theme/app_theme.dart`. Do not hard-code colors, text styles, border radius, spacing, shadows, or separators when an equivalent exists in `AppTheme`.

## Theme Token Usage

Reuse existing theme tokens and shared styles before creating new ones. Prefer tokens such as:

- `AppTheme.primary`, `AppTheme.secondary`, `AppTheme.tertiary`
- `AppTheme.surfaceContainerLow`, `AppTheme.surfaceContainerLowest`
- `AppTheme.spacing8`, `AppTheme.spacing12`, `AppTheme.spacing16`
- `AppTheme.radiusMd`, `AppTheme.radiusLg`

If a new visual value is needed, first confirm no existing `AppTheme` token fits. Prefer adding or reusing a shared theme-level definition instead of scattering constants across screen files.

## Screen Implementation Rules
New screens: `lib/screens/<feature>/<name>_screen.dart`

Keep screen widgets focused on layout and interaction. Move reusable logic into `providers/`, `services/`, `database/`, or `utils/` as appropriate.

Follow the project naming pattern: `snake_case.dart` for files and `UpperCamelCase` for widgets, for example `loan_detail_screen.dart` and `LoanDetailScreen`.

Preserve the design system's no-divider and no-heavy-shadow approach. Use surface contrast, spacing, and typography hierarchy instead of borders, decorative shadows, or hard-coded visual separators.