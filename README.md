# TaybGo Admin

Platform management dashboard for the TaybGo delivery ecosystem. Built with Flutter, targeting web with responsive support for mobile, tablet, and desktop.

## Features

- **Dashboard** — Real-time overview of orders, active drivers, restaurants, and pending items with visual breakdowns
- **Driver Management** — List, filter, and locate drivers on an interactive map (OpenStreetMap)
- **Approvals** — Review and approve/reject pending driver and restaurant applications
- **Support Tickets** — Manage customer support tickets with threaded conversations, priority, and status tracking
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
| Renderer | SkWasm (WebAssembly) |

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── l10n/           # Localization (5 languages)
│   ├── models/         # Driver, Restaurant, SupportTicket, OrderStats
│   ├── providers/      # AuthProvider, AdminProvider, SettingsProvider
│   ├── router/         # GoRouter config with auth guards
│   ├── services/       # API client with Bearer token auth
│   └── theme/          # Colors, spacing, typography, light/dark themes
└── features/
    ├── auth/           # Sign-in + OTP verification
    ├── shell/          # Responsive nav shell (sidebar >= 640px, bottom nav < 640px)
    ├── dashboard/      # Stats cards, order chart, fleet status, attention items
    ├── approvals/      # Pending drivers & restaurants tabs
    ├── drivers/        # Driver list + map view with markers
    ├── support/        # Ticket list, detail view, threaded messages
    └── profile/        # Theme & language settings
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on any web browser
flutter run -d web-server --web-port 8080
```

## Web Build

```bash
# Production build (wasm, ~6.5 MB)
flutter build web --release --wasm
```

### Build Optimization

The production build targets modern browsers only (Chrome 119+, Firefox 120+, Edge 119+) using WebAssembly. Post-build cleanup to strip debug artifacts and redundant renderer variants:

```bash
cd build/web

# Remove debug symbols
find canvaskit -name "*.js.symbols" -delete

# Remove license notices
rm -f assets/NOTICES

# Remove unused renderer variants
rm -f canvaskit/skwasm_heavy.*
rm -f canvaskit/canvaskit.wasm canvaskit/canvaskit.js

# Remove JS fallback (wasm-only)
rm -f main.dart.js
rm -rf canvaskit/chromium
```

### Deploy

```bash
firebase deploy --only hosting
```

## API

All requests go to `https://taybgo.com` with Bearer token auth.

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/auth/otp/request/` | Request OTP |
| POST | `/api/auth/otp/verify/` | Verify OTP, receive tokens |
| GET | `/api/admin/home/` | Dashboard stats |
| POST | `/api/admin/drivers/{id}/verify/` | Approve/reject driver |
| POST | `/api/admin/restaurants/{id}/activate/` | Activate restaurant |
| GET | `/api/admin/support/tickets/` | List tickets (paginated) |
| GET | `/api/admin/support/tickets/{id}/` | Ticket detail |
| POST | `/api/admin/support/tickets/{id}/messages/` | Reply to ticket |

## Responsive Breakpoints

| Viewport | Layout |
|---|---|
| < 640px | Bottom navigation, card lists, single column |
| 640 - 960px | Sidebar, flexible grid |
| >= 960px | Expanded sidebar, multi-column grids, table views |
