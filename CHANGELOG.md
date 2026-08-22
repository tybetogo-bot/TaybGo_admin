# TaybGo Admin Changelog

All notable TaybGo Admin changes are documented here.

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
