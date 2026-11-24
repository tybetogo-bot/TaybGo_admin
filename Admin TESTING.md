# TaybGo Admin — Test Scenarios & Checklist

Manual QA checklist. Work through each section top-to-bottom. Mark each item `[x]` when it passes.
Run against both **Dev** and **Prod** environments unless stated otherwise.

---

## Prerequisites

- [ ] App launches in dev: `flutter run -d chrome -t lib/main_dev.dart`
- [ ] App launches in prod: `flutter run -d chrome -t lib/main_prod.dart`
- [ ] "Admin Dev" title shown in dev; "TaybGo Admin" shown in prod
- [ ] Both environments hit different base URLs (check network requests in DevTools)

---

## 1. Authentication

### 1.1 Sign-In Screen Initial State
- [ ] Logo and app name displayed correctly
- [ ] Country picker defaults to a valid country with flag + dial code
- [ ] Phone number field is empty and accepts only numeric input
- [ ] "Get OTP" button is visible and enabled
- [ ] Language selector shows current locale (default: EN)
- [ ] No error messages shown on initial load

### 1.2 Country Code Picker
- [ ] Tapping country picker opens country selector dialog
- [ ] Countries are listed with flag emoji, name, and dial code
- [ ] Searching filters the list correctly (partial name match)
- [ ] Selecting a country updates the dial code prefix in the input
- [ ] Dial code is prepended to phone number in API call (not shown in field)

### 1.3 Language Selector
- [ ] Switching to Arabic (AR) changes UI text to Arabic and enables RTL layout
- [ ] Switching to Dutch (NL), French (FR), German (DE) changes labels correctly
- [ ] Switching back to English (EN) restores LTR layout

### 1.4 OTP Request — Happy Path
- [ ] Enter a valid registered phone number → tap "Get OTP"
- [ ] Loading spinner shown on button during request
- [ ] Button disabled during loading (no double-submit)
- [ ] On success → navigated to `/verify-otp` screen
- [ ] Dev mode: yellow test OTP banner shown on OTP screen (if API returns test_otp)
- [ ] Prod mode: test OTP banner NOT shown

### 1.5 OTP Request — Error Paths
- [ ] Submit with empty phone → appropriate error shown (no crash)
- [ ] Submit with invalid/unregistered phone → error message shown from API
- [ ] Network failure → friendly connection error shown (not a stack trace)
- [ ] Button re-enables after error so user can retry

### 1.6 OTP Verification — Happy Path
- [ ] OTP screen shows the phone number (masked or full)
- [ ] "Change phone" back button navigates back to sign-in
- [ ] Enter correct 6-digit OTP → tap verify
- [ ] Loading shown during verification
- [ ] On success → auto-redirected to `/dashboard`
- [ ] Tokens saved: close and reopen app → still logged in (no OTP prompt)

### 1.7 OTP Verification — Error Paths
- [ ] Submit with empty OTP → error shown
- [ ] Submit with wrong OTP → error message from API shown
- [ ] Submit with < 6 digits → error shown (no crash)
- [ ] Network failure → friendly error, button re-enables

### 1.8 Session Persistence
- [ ] After login, hard-refresh the web page → user stays on dashboard (not kicked to sign-in)
- [ ] Close browser tab, reopen app URL → user still authenticated
- [ ] Token clearly invalid (manually wipe SharedPreferences) → redirect to sign-in

### 1.9 Sign-Out
- [ ] Sign out via Profile screen → confirmation dialog appears
- [ ] Cancel dialog → remain on profile, still authenticated
- [ ] Confirm sign out → redirect to `/sign-in`
- [ ] After sign out, pressing browser back does NOT return to authenticated screens
- [ ] After sign out, tokens cleared (re-login required)
- [ ] After sign out, polling stops (no background API calls visible in DevTools)

---

## 2. Navigation & Routing

### 2.1 Route Guards
- [ ] Unauthenticated user visiting `/dashboard` → redirected to `/sign-in`
- [ ] Unauthenticated user visiting `/approvals` → redirected to `/sign-in`
- [ ] Unauthenticated user visiting `/support/123` → redirected to `/sign-in`
- [ ] Authenticated user visiting `/sign-in` → redirected to `/dashboard`
- [ ] Authenticated user visiting `/verify-otp` → redirected to `/dashboard`

### 2.2 Bottom Navigation (Mobile — width < 640px)
- [ ] 5 tabs shown: Dashboard, Approvals, Drivers, Support, Profile
- [ ] Active tab highlighted correctly
- [ ] Switching tabs preserves scroll position within each tab (no re-fetch on every switch)
- [ ] Approvals tab shows badge with pending count
- [ ] Support tab shows badge with open ticket count
- [ ] Badges update as polling refreshes data

### 2.3 Sidebar Navigation (Desktop — width ≥ 640px)
- [ ] Sidebar visible on left
- [ ] At width ≥ 960px: icon + label shown; at width 640–959px: icon only
- [ ] Active item highlighted
- [ ] Same badges as bottom nav for approvals and support
- [ ] Badges update in real-time from polling

### 2.4 Deep Links / Direct URL Navigation
- [ ] `/approvals/driver/123?name=John&phone=+1234` → loads driver detail directly
- [ ] `/support/456` → loads ticket detail directly
- [ ] Invalid route → redirected gracefully (no white screen/crash)

---

## 3. Dashboard

### 3.1 Initial Load
- [ ] Loading spinner shown while fetching
- [ ] Disappears once data loads
- [ ] 4 stat cards visible: Total Orders, Online Drivers, Total Restaurants, Pending Items
- [ ] Each stat card shows a number (not null, not "—" unless no data)
- [ ] Refresh button (icon) in AppBar works — reloads all data

### 3.2 Stat Cards
- [ ] "Pending Items" = count of pending drivers + pending restaurants + open tickets
- [ ] Counts update when approvals are actioned from the Approvals screen
- [ ] Counts update on polling (within ~10 seconds of a change)

### 3.3 Fleet Status Panel
- [ ] Online percentage calculated correctly (online / total * 100)
- [ ] Online/Offline/Total driver counts shown
- [ ] Shows "No drivers" state if no drivers exist

### 3.4 Needs Attention Panel
- [ ] Lists pending driver approvals
- [ ] Lists pending restaurant activations
- [ ] Lists open support tickets
- [ ] Empty panel when nothing pending
- [ ] Tapping items navigates to the appropriate screen

### 3.5 Pull-to-Refresh
- [ ] Pull down on dashboard → refreshes data
- [ ] Spinner shown during refresh
- [ ] Stat cards update after refresh

### 3.6 Error State
- [ ] Simulate network failure (DevTools → offline) → error message shown
- [ ] Retry button on error view → attempts fetch again
- [ ] Once network restored → data loads successfully

### 3.7 Polling
- [ ] No loading spinner shown during polling refreshes (silent updates)
- [ ] Data updates every ~10 seconds without user interaction
- [ ] Navigate away and back → data still fresh (poll continues in shell)

---

## 4. Approvals — Drivers

### 4.1 Driver Approvals List
- [ ] "Drivers" tab selected by default
- [ ] Pending driver cards displayed with: name, submission date, status badge ("Pending")
- [ ] Card shows a brief summary (no document details on list)
- [ ] Empty state: "No pending driver approvals" when list is empty
- [ ] Loading spinner on initial load

### 4.2 Inline Approve/Reject (from list card)
- [ ] "Approve" button on card → confirmation or direct action
- [ ] On approve: driver card removed from list immediately
- [ ] Success snackbar shown
- [ ] Driver does NOT reappear after next polling cycle
- [ ] "Reject" button on card → rejection recorded
- [ ] Rejected driver removed from list immediately
- [ ] Driver does NOT reappear after next polling cycle

### 4.3 Driver Detail Screen (from Approvals)
- [ ] Tapping a driver card navigates to `/approvals/driver/:id`
- [ ] Driver name displayed prominently with avatar initials
- [ ] Status badge shows "Pending"
- [ ] Contact info: phone number and email shown (or "—" if missing)
- [ ] Vehicle type shown (Bike / Motor / Car / Van)
- [ ] Services section: Food Delivery, Shipping, Taxi — each with ✓ or ✗
- [ ] Driving License document shown (image or link)
- [ ] ID Document shown
- [ ] Other documents shown if present
- [ ] Submission date shown
- [ ] Registration date shown

### 4.4 Document Viewing
- [ ] Tapping a document image opens zoom/fullscreen dialog
- [ ] Image loads with progress indicator
- [ ] Image load failure shows error placeholder (no crash)
- [ ] Document URL opens in browser (if link rather than image)

### 4.5 Approve from Detail Screen
- [ ] "Approve" button visible (when showActions=true)
- [ ] Tap Approve → API call made
- [ ] Loading shown during action
- [ ] On success → pop back to approvals list
- [ ] Driver not visible in list after returning
- [ ] Success snackbar shown on return

### 4.6 Reject from Detail Screen
- [ ] "Reject" / "Decline" button visible
- [ ] Tap Reject → API call made
- [ ] On success → pop back to list
- [ ] Driver not visible in list after returning

### 4.7 Driver Detail — Error Paths
- [ ] If profile fails to load → error message shown with retry
- [ ] If approve/reject fails → error snackbar shown, stay on screen
- [ ] Double-tap Approve → second tap prevented (button disabled during loading)

### 4.8 Driver Profile Loading Strategy
- [ ] Driver found in verification queue → full document data shown
- [ ] Driver NOT in queue page 1 → searches subsequent pages (no "not found" error prematurely)
- [ ] Driver not found anywhere → falls back to home data cache (shows basic info)
- [ ] Fallback data shown without crash

---

## 5. Approvals — Restaurants

### 5.1 Restaurant Approvals List
- [ ] "Restaurants" tab shows pending restaurant cards
- [ ] Restaurant name shown on card
- [ ] Submission date shown
- [ ] Status badge: "Pending"
- [ ] Empty state shown when no pending restaurants

### 5.2 Restaurant Detail Screen
- [ ] Tapping card navigates to `/approvals/restaurant/:id`
- [ ] Restaurant icon with gradient background shown
- [ ] Name displayed prominently
- [ ] "Pending" status shown
- [ ] "Activate" button visible and enabled

### 5.3 Activate Restaurant
- [ ] Tap Activate → API call made with loading indicator
- [ ] On success → pop back to list, restaurant not visible
- [ ] Success snackbar shown
- [ ] Restaurant does NOT reappear after polling
- [ ] Failure → snackbar error, stay on detail screen

---

## 6. Drivers Screen

### 6.1 Driver List — Initial Load
- [ ] Loads driver list from home data (no separate API call if already cached)
- [ ] Mini stats: Total, Online, Offline counts shown
- [ ] Each driver card: name, status (online/offline), vehicle type, location (if available)
- [ ] Online drivers shown with green indicator; offline with grey/red
- [ ] Empty state: "No drivers found" if no drivers

### 6.2 Search
- [ ] Search field visible
- [ ] Type driver name → list filters live (case-insensitive)
- [ ] Type phone number (partial) → matches shown
- [ ] Clear search → full list restored
- [ ] Search with no matches → "No drivers match filters" message (not a crash)

### 6.3 Status Filter Chips
- [ ] "All" chip selected by default
- [ ] Tap "Online" → only online drivers shown
- [ ] Tap "Offline" → only offline drivers shown
- [ ] Tap "All" → resets filter
- [ ] Chip + search work together (AND logic)

### 6.4 Region Filter
- [ ] Region dropdown populated from driver coordinates (dynamic city names)
- [ ] Selecting a region filters list to drivers in that area
- [ ] Map zooms to selected region
- [ ] "All Regions" resets filter

### 6.5 List / Map Toggle
- [ ] Toggle button switches between list and map view
- [ ] List view: table on desktop, cards on mobile
- [ ] Map view: OpenStreetMap rendered
- [ ] Toggling back to list preserves search/filter state

### 6.6 Map View
- [ ] Map renders without crash
- [ ] Online drivers shown with green markers; offline with grey/red
- [ ] Marker shows driver initials
- [ ] Tapping a marker → opens driver detail screen (read-only, no approve/reject)
- [ ] Map auto-fits bounds to show all visible drivers
- [ ] Pan and zoom work correctly
- [ ] No drivers with coordinates → "No locations available" message

### 6.7 Driver Detail (Read-Only from Drivers Screen)
- [ ] Same screen as approvals detail but without Approve/Reject buttons
- [ ] All info displayed correctly
- [ ] Back button returns to drivers screen

---

## 7. Support Tickets

### 7.1 Ticket List — Initial Load
- [ ] Ticket list loads with spinner
- [ ] Each ticket shows: subject, requester name, priority dot (color-coded), category, ticket ID
- [ ] Priority colors: Low=grey, Medium=blue, High=orange, Urgent=red
- [ ] Status tab counts shown (All, Open, In Progress, Resolved, Closed)
- [ ] Empty state for tabs with no tickets

### 7.2 Status Filter Tabs
- [ ] "All" tab shows every ticket
- [ ] "Open" tab shows only OPEN tickets
- [ ] "In Progress" tab shows only IN_PROGRESS tickets
- [ ] "Resolved" tab shows only RESOLVED tickets
- [ ] "Closed" tab shows only CLOSED tickets
- [ ] Tab badge counts match number of tickets in each tab
- [ ] Switching tabs is instant (client-side filter, no re-fetch)

### 7.3 Polling Updates
- [ ] New ticket appears in list within ~10 seconds (without manual refresh)
- [ ] Resolved tickets move to Resolved tab on next poll
- [ ] Badge counts on nav update to reflect changes

### 7.4 Ticket Detail — Load
- [ ] Tapping ticket → navigates to `/support/:id`
- [ ] Subject shown in AppBar / header
- [ ] Status badge shown (OPEN / IN_PROGRESS / RESOLVED / CLOSED)
- [ ] Priority badge shown with correct color
- [ ] Category badge shown
- [ ] Requester name shown
- [ ] Related restaurant name shown (if present)
- [ ] Related driver name shown (if present)
- [ ] Related order ID shown (if present)
- [ ] Assigned admin name shown or "Unassigned"
- [ ] Created date shown in readable format
- [ ] Closed date shown if ticket is closed

### 7.5 Ticket Conversation
- [ ] Messages displayed in chronological order
- [ ] Admin messages aligned to the right
- [ ] Customer/Driver/Restaurant messages aligned to the left
- [ ] Author name and role shown per message
- [ ] Timestamp shown per message
- [ ] "No messages" placeholder if no messages
- [ ] Attachments listed below message body (if present)
- [ ] MIME type shown for attachments (e.g., image/jpeg)

### 7.6 Replying
- [ ] Reply text input visible for non-closed tickets
- [ ] Can type and send a reply
- [ ] Loading shown while sending
- [ ] Send button disabled during loading (no double-send)
- [ ] On success: reply appears in conversation immediately
- [ ] Text input cleared after successful send
- [ ] Failure: snackbar error shown, text preserved in field

### 7.7 Status Actions
- [ ] "Mark Resolved" button visible on non-closed tickets
- [ ] Tap → status updated to RESOLVED → badge updates
- [ ] "Close" button visible on non-closed tickets
- [ ] Tap → status updated to CLOSED
- [ ] After closing: reply input hidden, status buttons hidden
- [ ] Status change reflected in ticket list on return
- [ ] Failure: error snackbar shown, status unchanged

### 7.8 Closed Ticket View
- [ ] Reply area NOT shown for CLOSED tickets
- [ ] Status action buttons NOT shown
- [ ] All history and info still readable

---

## 8. Profile & Settings

### 8.1 Profile Load
- [ ] Profile screen shows loading spinner while fetching
- [ ] User avatar initials shown (first + last name initials)
- [ ] Full name displayed
- [ ] Email displayed
- [ ] Phone number displayed
- [ ] User role(s) displayed
- [ ] Member since date shown in readable format
- [ ] Verified badge shown if account is verified
- [ ] Error state with retry if profile fetch fails

### 8.2 Theme Selector
- [ ] Three options: System, Light, Dark
- [ ] Current selection highlighted
- [ ] Switching to Dark → app-wide dark theme applied immediately
- [ ] Switching to Light → light theme applied immediately
- [ ] Switching to System → follows device OS preference
- [ ] Selection persists across app restarts

### 8.3 Language Selector (Settings)
- [ ] Language dropdown shows current locale
- [ ] Changing locale → UI text updates across the whole app
- [ ] Arabic → RTL layout applied globally
- [ ] Selection persists across app restarts

---

## 9. Responsive Design

### 9.1 Mobile (width < 640px)
- [ ] Bottom navigation bar visible (5 tabs)
- [ ] Sidebar NOT visible
- [ ] Cards displayed in single column
- [ ] Table views switch to card view
- [ ] Text sizes readable without overflow

### 9.2 Tablet / Desktop (width 640–959px)
- [ ] Sidebar visible with icons only (no labels)
- [ ] Bottom navigation NOT visible
- [ ] Cards in 2-column grid where applicable

### 9.3 Wide Desktop (width ≥ 960px)
- [ ] Sidebar expanded with icons + labels
- [ ] Dashboard stat cards in 3–4 column grid
- [ ] Driver list shows table with columns
- [ ] No text overflow or layout clipping

### 9.4 Resize Behavior
- [ ] Resizing browser window dynamically switches between layouts (no restart required)
- [ ] No layout overflow errors in Flutter debug console during resize
- [ ] Map view adapts correctly when window resized

---

## 10. Polling & Real-Time Behavior

### 10.1 Polling Lifecycle
- [ ] Polling starts when AdminShell is mounted (after login)
- [ ] Polling occurs every ~10 seconds (verify in DevTools Network tab)
- [ ] Polling stops when signing out (no more requests after sign-out)
- [ ] Polling does NOT cause loading spinners (silent updates)

### 10.2 Data Freshness
- [ ] Approving a driver from device A → appears in device B's list as removed within 10s
- [ ] New support ticket created (via customer app) → appears in admin list within 10s
- [ ] Nav badge counts update without page refresh

### 10.3 Polling Doesn't Re-Show Actioned Items
- [ ] After approving a driver, wait 30+ seconds → driver does NOT reappear in pending list
- [ ] After rejecting a driver, wait 30+ seconds → driver does NOT reappear
- [ ] After activating a restaurant, wait 30+ seconds → restaurant does NOT reappear

---

## 11. Error Handling & Edge Cases

### 11.1 Network Offline
- [ ] Go offline mid-session → API calls fail gracefully
- [ ] Error messages shown (not crashes or blank screens)
- [ ] Come back online → retry works
- [ ] Polling fails silently when offline (no error flash every 10s)

### 11.2 Token Expiry / 401 Errors
- [ ] If server returns 401 → user is redirected to sign-in (or shown auth error)
- [ ] No crash or infinite loading on 401

### 11.3 Empty Data States
- [ ] Dashboard with no orders → stat cards show 0, no crash
- [ ] No drivers → drivers screen shows empty state message
- [ ] No pending approvals → approvals screen shows empty state per tab
- [ ] No tickets → support screen shows empty state
- [ ] No messages in ticket → "No messages" placeholder shown

### 11.4 Malformed / Partial API Data
- [ ] Driver with null phone → shown as "—" not crash
- [ ] Driver with null coordinates → excluded from map without crashing
- [ ] Ticket with no restaurant name → fetches from API or shows "—"
- [ ] Missing document URLs → shown as placeholder, no broken image crash
- [ ] Truncated pagination (count=0 but results=[]) → handled gracefully

### 11.5 Concurrent Actions
- [ ] Rapidly tap Approve twice → only one API call made (button disabled after first tap)
- [ ] Rapidly tap Send reply twice → only one message sent
- [ ] Rapidly switch filter tabs → no race condition / out-of-order rendering

---

## 12. Build & Deployment

### 12.1 Web Build
- [ ] `flutter build web --release --wasm -t lib/main_prod.dart` completes without errors
- [ ] `build/web/` directory created with all required files
- [ ] No analysis warnings: `flutter analyze` returns clean

### 12.2 Firebase Hosting
- [ ] `firebase deploy --only hosting` deploys successfully
- [ ] Deployed URL loads the app without a blank screen
- [ ] Console shows no JavaScript errors on production build

### 12.3 Android Build (if applicable)
- [ ] `flutter build apk -t lib/main_prod.dart --flavor prod` completes without errors
- [ ] APK installs and runs on device/emulator
- [ ] App name shows "TaybGo Admin" (not "Admin Dev")

---

## 13. Security Spot Checks

- [ ] All API requests use HTTPS (no plain HTTP calls visible in DevTools)
- [ ] Authorization Bearer token present in every authenticated request header
- [ ] No tokens or sensitive data logged to the browser console
- [ ] Sign-in page inaccessible to authenticated users (router guard works)
- [ ] Protected screens inaccessible without auth token (guard works)
- [ ] Driver document images require authentication to view (not publicly cached URLs) *(verify with backend team)*
- [ ] OTP field accepts only numeric input (no script injection vector)
- [ ] Phone field accepts only digits (no injection)

---

## Test Run Log

| Date | Tester | Environment | Browser/Device | Pass | Fail | Notes |
|------|--------|-------------|----------------|------|------|-------|
|      |        | Dev         |                |      |      |       |
|      |        | Prod        |                |      |      |       |

---

## Known Issues / Out of Scope

- Refresh token rotation is not implemented in the client; long-lived sessions depend on backend token lifetime.
- Attachment tapping shows MIME type only; viewing/downloading attachments from tickets is not yet implemented.
- Map markers do not auto-refresh driver positions during the 10s poll — positions update only on full re-render.
