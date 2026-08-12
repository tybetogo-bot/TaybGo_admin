# TaybGo Admin Changelog

All notable TaybGo Admin changes are documented here.

## 1.0.7+8 — 2026-08-11

### Overview

- Reworked the Overview statistics into a compact two-column mobile layout.
- Preserved the four-column layout on larger screens while improving responsive spacing.

### Partners and management

- Redesigned the Partners workspace with a smaller app bar, a toggleable shared search action, and a clearer Drivers/Restaurants switcher.
- Tightened status cards, list controls, restaurant filters, driver list presentation, and map/list browsing.
- Made the driver map more compact so the page scrolls naturally.
- Removed unreliable client-side city inference for drivers; driver filtering now stays aligned with API-provided data.

### Drivers and addresses

- Added optional driver address parsing to the shared data models.
- Preserved address data through driver lists, profiles, detail screens, polling refreshes, and status updates.
- Added address-aware search and profile details while keeping live GPS coordinates separate.
- Added regression coverage for complete, nested, empty, and GPS-preserving address responses.

### Orders

- Added app-bar search controls with a toggleable search field.
- Consolidated order statistics into a compact four-column row.
- Improved filter spacing and mobile readability.

### Release quality

- Updated the in-app release history and localized release notes for this version.
- Kept release APK binaries out of source control; development and production split-ABI artifacts are generated separately.
