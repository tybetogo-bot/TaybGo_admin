# TaybGo Admin Changelog

All notable TaybGo Admin changes are documented here.

## 1.0.11+12 — 2026-09-12

### Partner management

- Switched Drivers and Restaurants management lists to their dedicated paginated admin data and backend-supported filters.
- Aligned partner search with the backend contract for names, phones, emails, vehicle plates, and restaurant owner contacts, including formatted phone input.
- Kept totals and online/offline status counts consistent with the visible partner filters.
- Added backend-compliant restaurant status controls: confirmed disable/enable actions, authoritative detail refetches, safe error handling, and filtered-list refreshes that preserve the current search and scope.

### Navigation and notifications

- Added router-backed driver detail navigation and preserved the active partner tab, search, and filter context when opening details or using browser navigation.
- Added an authenticated notifications inbox with local unread counts, newest-first ordering, read/unread actions, deletion, retry, refresh, and localized empty/error states.
- Added Firebase Messaging configuration and device-token registration for administrator notifications, including foreground banners, background/cold-start routing, and safe support-ticket destinations.

### Support workflows

- Added a reusable support-ticket composer from the support list, driver details, restaurant details, and order details with backend-compliant recipient and target mappings.
- Created tickets atomically with their initial message, UUIDv4 idempotency keys, retry-safe payloads, 200/201 handling, field/business error feedback, and optional Cloudinary attachments.
- Added support-list pagination, visible refresh controls, post-create refresh and navigation to the returned ticket conversation, and dedicated three-second polling for new ticket messages.
- Clarified support action styling and removed the Application Settings shortcut from the profile quick actions.

### Release quality

- Added regression coverage for partner pagination, backend search parameters, formatted phone searches, no-result states, and partner detail routes.
- Completed localization coverage for the latest partner, support, notification, restaurant-status, authentication, and settings UI across English, Arabic, Dutch, French, and German, including locale-aware dates/statuses and repaired malformed translation copy.

## 1.0.10+11 — 2026-08-24

### Account management

- Replaced the separate driver and restaurant creation entry points with a unified Add User flow for driver and restaurant accounts.
- Made the account name mandatory and added international phone validation, clear role selection, and focused API error feedback.
- Added optional secure password generation with copy support while preserving manual password entry.

### Password management

- Added change-password actions to every driver and restaurant details page.
- Connected password changes to the user-specific admin endpoint and clearly communicated that existing refresh sessions are revoked.

### Authentication and configuration

- Added public application configuration loading for role-based OTP or password authentication.
- Added administrator password sign-in, required-update enforcement, and editable application settings.
- Removed development OTP exposure from the administrator authentication flow.

### Release quality

- Expanded API and widget regression coverage for user creation, password changes, public configuration, authentication, and application settings.

## 1.0.9+10 — 2026-08-22

### Partner creation

- Added complete admin workflows for creating approved drivers and active restaurants.
- Added responsive, localized forms with nested API error handling and required-field validation.

### Addresses and phone numbers

- Added Google Places autocomplete and place details for precise, structured partner addresses.
- Added searchable country pickers and international dial codes to driver, owner, and restaurant phone fields.

### Driver vehicles and services

- Limited new driver vehicles to Bike and Car.
- Made car size, plate, color, make, model, and year mandatory for cars.
- Added a vehicle year selector from 1960 through the following calendar year.
- Limited taxi service availability to car drivers.

### Cloudinary uploads

- Added Cloudinary file uploads for driver documents, restaurant logos, and restaurant registration licenses.
- Made all standard driver documents mandatory while keeping Other documents optional.
- Made restaurant registration licenses mandatory and kept restaurant logos optional.
- Added upload progress, replacement, file-size, file-type, and failure states.

### Release quality

- Added API, form, address, Cloudinary, validation, vehicle-rule, and payload regression coverage.

## 1.0.8+9 — 2026-08-20

### Authentication

- Added a visible back button to the OTP verification screen.
- Fixed the Change phone number action so it reliably returns administrators to sign-in.

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
