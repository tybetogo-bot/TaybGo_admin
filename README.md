# TaybGo Admin

Platform management dashboard for the TaybGo delivery ecosystem. Built with Flutter, targeting web with responsive support for mobile, tablet, and desktop.

## Features

- **Dashboard** — Real-time overview of orders, active drivers, restaurants, and pending items with visual breakdowns
- **Driver Management** — List, filter, and locate drivers on an interactive map (OpenStreetMap)
- **Approvals** — Review and approve/reject pending driver and restaurant applications
- **Support Tickets** — Manage customer support tickets with threaded conversations, priority, and status tracking
- **Notifications** — Receive administrator notifications, track unread state, and open support tickets from safe push destinations
- **Localization** — English, Arabic (RTL), Dutch, French, German
- **Theming** — Light, Dark, and System-default modes
- **Auth** — Phone + OTP authentication with JWT token management and session persistence

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.38 / Dart 3.10 |
| State | Provider |
| Routing | GoRouter |
| HTTP | `http` package |
| Maps | flutter_map + latlong2 (OpenStreetMap) |
| Storage | SharedPreferences |
| Analytics | Firebase Analytics |
| Hosting | Firebase Hosting |
| Renderer | SkWasm (WebAssembly) |

## Project Structure

```
lib/
├── main.dart                # Default entry point (falls back to prod)
├── main_dev.dart            # Dev entry point → https://dev.taybgo.com
├── main_prod.dart           # Prod entry point → https://taybgo.com
├── core/
│   ├── config/          # Environment configuration (dev/prod)
│   ├── l10n/            # Localization (5 languages)
│   ├── models/          # Driver, Restaurant, SupportTicket, HomeResponse, etc.
│   ├── providers/       # AuthProvider, AdminProvider, NotificationProvider, SettingsProvider
│   ├── router/          # GoRouter config with auth guards
│   ├── services/        # API client with Bearer token auth
│   ├── theme/           # Colors, spacing, typography, light/dark themes
│   └── utils/           # Utility helpers
└── features/
    ├── auth/            # Sign-in + OTP verification
    ├── shell/           # Responsive nav shell (sidebar ≥ 640px, bottom nav < 640px)
    ├── dashboard/       # Stats cards, order chart, fleet status, attention items
    ├── approvals/       # Pending drivers & restaurants tabs with detail screens
    ├── drivers/         # Driver list + map view with markers
    ├── support/         # Ticket list, detail view, threaded messages
    └── profile/         # Theme & language settings
```

## Environments

The app supports two environments with separate entry points and Android flavors:

| Environment | App Name | Base URL | App ID |
|---|---|---|---|
| **dev** | Admin Dev | `https://dev.taybgo.com` | `com.example.taybgoadmin.dev` |
| **prod** | TaybGo Admin | `https://taybgo.com` | `com.example.taybgoadmin` |

Both flavors can be installed side-by-side on the same device.

## Getting Started

```bash
# Install dependencies
flutter pub get
```

### Run

```bash
# Dev environment
flutter run -t lib/main_dev.dart --flavor dev

# Prod environment
flutter run -t lib/main_prod.dart --flavor prod

# Web (no flavor needed)
flutter run -d chrome -t lib/main_dev.dart
flutter run -d chrome -t lib/main_prod.dart
```

### VS Code

Use the pre-configured launch configurations in `.vscode/launch.json`. Open the **Run and Debug** panel and select **Dev** or **Prod** from the dropdown.

## Build

### Android

```bash
# Dev APK
flutter build apk -t lib/main_dev.dart --flavor dev

# Prod APK
flutter build apk -t lib/main_prod.dart --flavor prod

# Prod App Bundle (for Play Store)
flutter build appbundle -t lib/main_prod.dart --flavor prod
```

### iOS

```bash
# Dev
flutter build ios -t lib/main_dev.dart --flavor dev

# Prod
flutter build ios -t lib/main_prod.dart --flavor prod
```

### Web

```bash
# Production build (wasm). FCM_WEB_VAPID_KEY is the Firebase Web Push
# certificate key from the taybgoadmin project.
flutter build web --release --wasm -t lib/main_prod.dart \
  --dart-define=FCM_WEB_VAPID_KEY=YOUR_FIREBASE_WEB_PUSH_CERTIFICATE_KEY
```

#### Build Optimization

The production build targets modern browsers only (Chrome 119+, Firefox 120+, Edge 119+) using WebAssembly. Post-build cleanup to strip debug artifacts:

```bash
cd build/web
find canvaskit -name "*.js.symbols" -delete
rm -f assets/NOTICES
rm -f canvaskit/skwasm_heavy.*
rm -f canvaskit/canvaskit.wasm canvaskit/canvaskit.js
rm -f main.dart.js
rm -rf canvaskit/chromium
```

## Deploy

```bash
# Deploy web to Firebase Hosting
firebase deploy --only hosting
```

## API

Requests are sent to the configured environment base URL with Bearer token auth.
OTP auth requests include `target_role: admin` in both the request and verify payloads so the backend scopes login to admin users.

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/auth/otp/request/` | Request OTP |
| POST | `/api/auth/otp/verify/` | Verify OTP, receive JWT tokens |
| GET | `/api/admin/home/` | Dashboard stats (drivers, restaurants, orders, pending) |
| GET | `/api/admin/drivers/verification-queue/` | Pending driver applications |
| POST | `/api/admin/drivers/{id}/verify/` | Approve/reject driver |
| POST | `/api/admin/restaurants/{id}/activate/` | Activate restaurant |
| GET | `/api/admin/support/tickets/` | List tickets (paginated) |
| GET | `/api/admin/support/tickets/{id}/` | Ticket detail |
| PATCH | `/api/admin/support/tickets/{id}/` | Update ticket status/priority |
| POST | `/api/admin/support/tickets/{id}/messages/` | Reply to ticket |
| GET | `/api/notifications` | List authenticated admin notifications |
| PATCH | `/api/notifications/{id}` | Mark a notification read or unread |
| DELETE | `/api/notifications/{id}` | Delete an authenticated admin notification |
| POST | `/api/notifications/device` | Register an authenticated FCM device/browser token |
| GET | `/api/me/` | Current user profile |
| GET | `/api/customer/restaurants/{id}/` | Restaurant detail |

## Responsive Breakpoints

| Viewport | Layout |
|---|---|
| < 640px | Bottom navigation, card lists, single column |
| 640 – 960px | Collapsed sidebar, flexible grid |
| ≥ 960px | Expanded sidebar, multi-column grids, table views |
