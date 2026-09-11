# TaybGo Admin — Project Guide

## Overview

Flutter admin dashboard for the TaybGo delivery platform. Manages drivers, restaurants, approvals, and support tickets. Primary target is web (Firebase Hosting), with Android/iOS support.

## Commands

```bash
# Install dependencies
flutter pub get

# Run dev
flutter run -t lib/main_dev.dart --flavor dev

# Run prod
flutter run -t lib/main_prod.dart --flavor prod

# Run web (no flavor flag)
flutter run -d chrome -t lib/main_dev.dart

# Build prod web
flutter build web --release --wasm -t lib/main_prod.dart

# Build prod APK
flutter build apk -t lib/main_prod.dart --flavor prod

# Deploy web
firebase deploy --only hosting

# Analyze
flutter analyze

# Format
dart format lib/
```

## Architecture

### Entry Points

- `lib/main.dart` — Default entry, falls back to prod if no environment is set
- `lib/main_dev.dart` — Initializes `EnvConfig` with dev, then calls `main()`
- `lib/main_prod.dart` — Initializes `EnvConfig` with prod, then calls `main()`

### Environment Config

`lib/core/config/env_config.dart` holds `baseUrl` and `appName` per environment:
- **dev**: `https://dev.taybgo.com` / "Admin Dev"
- **prod**: `https://taybgo.com` / "TaybGo Admin"

Android flavors in `android/app/build.gradle.kts` set the native app name and application ID suffix (`.dev` for dev).

### State Management

Three providers via the `provider` package:
- **AuthProvider** — OTP auth flow, JWT tokens, session persistence via SharedPreferences
- **AdminProvider** — Dashboard data, driver/restaurant approvals, support tickets. Polls every 10 seconds.
- **SettingsProvider** — Theme mode and locale persistence

### API Layer

`lib/core/services/api_service.dart` — Single HTTP client using the `http` package. Reads `EnvConfig.baseUrl` at runtime. All endpoints use Bearer token auth. Throws `ApiException` on failure.

### Routing

`lib/core/router/app_router.dart` — GoRouter with redirect guards. Unauthenticated users go to `/sign-in`. Auth screens redirect to `/dashboard` when logged in.

### Theme

`lib/core/theme/` — Primary color is green (#00C853). Full light and dark themes. Spacing and typography constants in separate files.

### Localization

`lib/core/l10n/app_localizations.dart` — Supports en, ar (RTL), nl, fr, de.

## Conventions

- Feature screens live in `lib/features/<feature>/`
- Shared code lives in `lib/core/`
- Models are plain Dart classes with `fromJson` factories
- No code generation (no build_runner, no freezed)
- HTTP client is the `http` package, not Dio
- State management is Provider, not Riverpod or Bloc
- Responsive layout: bottom nav < 640px, sidebar ≥ 640px
- `AdminProvider` tracks recently-approved IDs to prevent re-display after polling refresh

## Key Files

- `lib/core/services/api_service.dart` — All API calls
- `lib/core/providers/admin_provider.dart` — Main business logic
- `lib/core/providers/auth_provider.dart` — Auth flow
- `lib/core/router/app_router.dart` — Route definitions
- `lib/core/config/env_config.dart` — Environment URLs
- `android/app/build.gradle.kts` — Android flavors
- `firebase.json` — Firebase Hosting config
- `.vscode/launch.json` — VS Code debug configs (Dev / Prod)
