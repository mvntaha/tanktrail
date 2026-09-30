\# TankTrail: shared-vehicle fuel and trip logger



Owner: Munawwar. Admin, builder, and learning Flutter/Firebase with AI help.

Purpose: drivers log trips and fuel fills with strict photo/video evidence; the owner reviews everything.

Goals: prevent fuel fraud, estimate running distance and efficiency.



\## How to work with the owner (read first)

\- Work step by step. Build ONE milestone at a time (see "Milestones"). After each one: summarize what changed in

&#x20; 3-5 lines, tell the owner exactly how to test it on their Android phone, then STOP and wait for their go-ahead.

\- Explain each new concept in 1-3 sentences when it first appears. Keep code simple and readable. Comment

&#x20; non-obvious decisions.

\- When a real decision is needed, ask with AskUserQuestion, recommended option first. Never invent values

&#x20; (vehicle specs, prices, IDs, secrets).

\- The owner prefers concise, direct communication and execution-ready results over long option menus. They refine

&#x20; through targeted corrections.

\- Verify package names, versions and APIs against current docs (pub.dev, Firebase, Cloudinary, Cloudflare) before

&#x20; using them. Training knowledge can be outdated. If something in this file contradicts current docs, say so and ask.

\- Never commit secrets. Ask before installing global tools or running anything destructive.

\- Earlier draft files (firestore.rules, seed.js) from the planning chat are OUTDATED. Rewrite from this spec; do not

&#x20; reuse them blindly.



\## Environment

\- Windows + PowerShell. Give PowerShell commands. Editor: VS Code (Flutter + Dart extensions).

\- Installed: Flutter SDK, Node.js. NOT installed: Android Studio, so the Android SDK, platform tools and a JDK must be

&#x20; set up in Milestone 0 (`flutter doctor` must be green for Android). The owner tests on a physical Android phone over

&#x20; USB debugging (no emulator). Ask for the phone's Android version.

\- Keep the project at a short path such as C:\\dev\\tanktrail (not in OneDrive). Windows Developer Mode must be ON

&#x20; (Flutter plugin symlinks).

\- Accounts already created: Firebase project (Spark plan), Cloudinary (free). Cloudflare account: not yet.

\- Firebase Emulator Suite needs a JDK on PATH and is awkward with a real phone. Use it only for rules unit tests.

&#x20; Ask the owner whether to create a separate `tanktrail-dev` Firebase project for phone testing.



\## Hard constraints

\- NO BILLING, ever. Firebase Spark plan only: no Cloud Functions, no Firebase Storage (verify current status), no

&#x20; billing-linked services (no google\_maps\_flutter, no paid geocoding). Cloudinary free tier, Cloudflare Workers free tier.

\- Android only, distributed manually as an APK (Firebase App Distribution, free, is the intended channel; verify it

&#x20; works on Spark). Keep code platform-neutral but do no iOS work.

\- One shared vehicle (a petrol Alto with automatic transmission), about 10 drivers, about 30 logs a day, one admin.

\- Offline-first is mandatory. Drivers are offline for hours during the day and sync when they get internet.

\- English UI, km, liters, PKR, Asia/Karachi time.

\- Never delete data. No retention or cleanup jobs.

\- Never store or commit: service-account key, Cloudinary API secret, driver passwords, release keystore.



\## Roles and auth

\- Firebase Auth email/password with REAL emails. No sign-up screen. No change-password or forgot-password UI.

\- Accounts are created only by `backend/seed.js` (Admin SDK). The owner supplies each driver's email and initial

&#x20; password in gitignored `backend/drivers.local.json`; if a password is omitted, the script generates one and writes it

&#x20; to a gitignored credentials file. Resets: `node seed.js --reset <email>` run on the owner's computer.

\- Roles are custom claims `role: driver | admin`. Exactly one admin account. The owner also has a SEPARATE driver

&#x20; account for when they drive. There is no role switching inside one account.

\- Rules must reject any signed-in user without a valid role claim. Claims take effect after re-login.

\- `users/{uid}.active = false` disables the Auth user (done by the seed script).

\- First login: show a one-time location-disclosure notice: "This app records your location when you log a trip or a

&#x20; fill." Store `locationNoticeAcceptedAt` on the user's own doc (rules allow only that field to be self-updated).



\## Product behavior

\### Trips

\- Manual entry only, no route tracking. Driver starts a trip: odometer reading (typed) + REQUIRED odometer photo.

&#x20; GPS is captured automatically at that moment. Driver ends the trip the same way. A trip is finished only when the

&#x20; end reading with its photo is entered.

\- Two drivers may have open trips at once (offline makes hard blocking unreliable). The app WARNS if another driver

&#x20; has an open trip; it never blocks.

\### Fuel fills

\- Independent of trips. Fills are by AMOUNT (rupees), not full tank. Fields: odometer, liters, pricePerL, total,

&#x20; fuelType (petrol default; petrol|diesel|cng|other), paidBy (`company\_cash` | `own`).

\- Required evidence per fill: odometer photo, pump-display photo, pump video (up to 60s). All captured in-app only

&#x20; (no gallery picker), GPS at capture, SHA-256 per file.

\- There is no station name and no place picker: drivers never choose or type places. The fuel gauge is broken, so

&#x20; there is no gauge input.

\### Editing

\- Drivers may edit their own log's typed fields (odometer, liters, pricePerL, total, fuelType, paidBy) while it is

&#x20; `pending`. Media, location and timestamps are never editable. Every edit appends the previous values to

&#x20; `edits/{id}` (server timestamp) in the same batch; the feed shows an "edited" badge (WhatsApp style) and the admin

&#x20; can see the full history. Approval locks a log; the admin can reopen it (status back to `pending`).

\- CONFIRM WITH THE OWNER before building: apply the same edit rules to trips.

\### Feed (drivers)

\- Drivers see all drivers' logs like an automated group chat: driver name, time, liters, amount, odometer, status,

&#x20; edited badge, photos/thumbnails and video. Drivers do NOT see any location or place name.

\- Pending offline entries show as "sending..." and become normal after sync.

\### Admin

\- Sees everything plus locations, maps, computed estimates and flags. Approves/rejects fills (with reason), reopens

&#x20; logs, marks flags reviewed, edits vehicle settings, manages named places, runs reports.

\- Reports: CSV export, PDF export, and share to WhatsApp (Android share sheet). Weekly/monthly, per driver and overall.

&#x20; Includes a reimbursement view: approved `own`-paid fills per driver per period.



\## Location and privacy rules (important)

\- GPS is captured at log moments only (trip start/end, fill, each evidence capture). NO continuous background

&#x20; tracking. If the owner asks for it later, stop and discuss (foreground-service notification, battery, offline

&#x20; buffering, disclosure). Do NOT build covert or hidden tracking; the disclosure notice above is mandatory.

\- If location services or permission are off, the app prompts the driver to enable it and does not allow capture

&#x20; until it is on. Record accuracy and the mock-location flag (Android).

\- Only the admin can read coordinates. Firestore rules cannot hide single fields, so ALL coordinates live in an

&#x20; admin-read-only subcollection `private/geo` under each trip and fuelLog. Public documents and evidence items

&#x20; contain no lat/lng. Strip GPS/EXIF location metadata from photos and videos before upload.

\- Named places: the admin keeps a list (name, lat, lng, radiusM, default 150 m). Logs inside a radius show that name

&#x20; in the admin view only. Added after the core build.



\## Data model (Firestore, client-generated document IDs everywhere)

\- `users/{uid}`: name, email, role, active, locationNoticeAcceptedAt. Written by the seed script (+ the one self field).

\- `vehicle/main`: name, plate, fuelType, tankCapacityL?, baselineKmPerL?, referencePricePerL?. Admin writes.

&#x20; Optional fields start empty; dependent flags stay OFF until set. Do not guess values.

\- `places/{id}`: name, lat, lng, radiusM. Admin only (read and write).

\- `trips/{id}`: driverId, driverName, startOdo, startedAt, startEvidence\[], createdAt (server), status open|closed;

&#x20; on close: endOdo, endedAt, endEvidence\[], closedAt (server). Admin may set reviewed, adminNote. edited, editedAt.

&#x20; - `trips/{id}/private/geo`: startLoc, endLoc {lat,lng,acc,mock}, per-evidence locations.

&#x20; - `trips/{id}/edits/{id}`: previous values + editedAt (server) + editedBy.

\- `fuelLogs/{id}`: driverId, driverName, odometer, liters, pricePerL, total, fuelType, paidBy, evidence\[3..6],

&#x20; capturedAtDevice, createdAt (server), status pending|approved|rejected, edited, editedAt; admin sets reviewNote,

&#x20; reviewedAt, flagsReviewed.

&#x20; - `fuelLogs/{id}/private/geo`, `fuelLogs/{id}/edits/{id}`: as above.

\- Evidence item (public): {type odometer|pump|video, url, publicId, sha256, capturedAtDevice, durationSec?}.

\- `createdAt` = FieldValue.serverTimestamp(), enforced by rules (== request.time). `capturedAtDevice` is the device

&#x20; clock; the gap between them is an admin-side flag.

\- Last known odometer is derived by query (highest odometer/endOdo), never stored, so out-of-order offline syncs

&#x20; cannot corrupt it. Keep queries limited/paginated (Spark quota is roughly 50k reads and 20k writes a day; check

&#x20; current numbers). Feed: page size \~20 with cursors; no unbounded listeners.



\## Firestore rules principles

\- Drivers: create their own trips and fills only; edit only per the edit rules; cannot touch status, reviewNote,

&#x20; flags, or others' data. Read all public log docs. Cannot read `private/geo`, `places`, or others' geo.

\- Admin: read everything; update only review fields, adminNote, reopen, vehicle, places. Deletes always denied.

\- Rules NEVER reject on odometer order or plausibility; offline writes must not lose evidence. Anomalies are flags in

&#x20; the admin UI. Rules can't loop over lists, so evidence item contents are validated in the app and by admin review.

\- Write emulator-based rules tests (`@firebase/rules-unit-testing`) for every rule above, including "driver cannot

&#x20; read geo" and "edit without history entry is denied".



\## Evidence and offline pipeline

Capture in-app -> save file locally -> compute SHA-256 -> enqueue in drift -> compress video (aim 480p-720p, \~15 fps)

\-> upload to Cloudinary with a signature from the Worker -> ONLY when ALL media of a log are uploaded, write the log

doc + its `private/geo` doc in one batch. Local state "uploading" is never a Firestore status. Uploads resume after

app restart. A trip's end update must be ordered after its start doc exists (chain the queue).

\- Cloudflare Worker (free): verifies the Firebase ID token and returns a Cloudinary upload signature. The Cloudinary

&#x20; API secret lives ONLY in the Worker. Hide media behind an `EvidenceUploader` interface.

\- Upload on any connection with background retry. Capture screens: framing guide, tap-to-focus, torch toggle, crop to

&#x20; the LCD before OCR, and a reminder to show ODO (not the trip meter).

\- OCR (google\_mlkit\_text\_recognition) is a SOFT flag only: typed values are the source of truth; OCR never blocks a

&#x20; log. The odometer is a low-contrast digital LCD and the pump has a tilted 7-segment display, so expect misses.

&#x20; Run an OCR test on the owner's three sample photos (two dashboards, one pump) at the start of Milestone 4 and report

&#x20; results honestly before relying on it.



\## Admin calculations (computed in the admin UI, never trusted from drivers)

\- Order all readings (trips and fills) by odometer value, not arrival time. Distance = next minus previous.

\- Efficiency = liters bought over a window / km driven in that window (fills are by amount, not full tank).

\- Expected km = liters x baselineKmPerL, compared with actual km. Cost per km = total / km.

\- Flags: reading lower than an earlier one with a later device time; unlogged km gap; duplicate reading; large

&#x20; createdAt minus capturedAtDevice delay; mock location; OCR mismatch; odometer km less than straight-line GPS

&#x20; distance between trip start and end; edited after submission (show diff); pricePerL differs from referencePricePerL

&#x20; (only if set); liters or expected km off by more than a tolerance (only if baselineKmPerL is set).

\- Rejected logs are excluded from efficiency and cost; pending logs are included and marked.



\## Stack (verify every package and version before use)

Flutter, Riverpod, go\_router, plain Dart models (fromMap/toMap), firebase\_auth, cloud\_firestore (offline

persistence on), firebase\_app\_check (do NOT enforce; sideloaded APKs may fail Play Integrity), camera, geolocator

(mock-location flag), google\_mlkit\_text\_recognition, video\_compress, drift, background\_downloader, crypto, flutter\_map

\+ OpenStreetMap tiles (respect the tile usage policy), pdf, csv, share\_plus, bundled Inter font (no runtime font

downloads). Backend (Node): firebase-admin, @firebase/rules-unit-testing. Worker: Cloudflare Wrangler.



\## UI and theme

\- Material 3 plus an `AppTokens` ThemeExtension in `app/lib/core/theme/app\_tokens.dart` mirroring the owner's

&#x20; shadcn-style CSS variables. Light theme ONLY is wired for now; dark tokens exist but are unused. All colors, radii

&#x20; and shadows come from tokens; never hard-code colors in widgets. A future theme change = replace that one file.

\- Full token source of truth: `docs/design-tokens.css` (owner's CSS, incl. card/popover-foreground, sidebar-\*,

&#x20; the full shadow scale and --spacing). The summary below is a subset.

\- Light: background #f4f5f7, foreground #0c121a, card #ffffff, popover #ffffff, primary #297cef, primary-foreground

&#x20; #ffffff, secondary #e9ebee, secondary-foreground #222933, muted #eceff1, muted-foreground #565e69, accent #d9e6f9,

&#x20; accent-foreground #002c78, destructive #ee343b, destructive-foreground #ffffff, border #dbdee2, input #e2e5e8,

&#x20; ring #297cef, chart 1-5: #297cef #00a381 #864ad2 #f3680f #ec2773. Radius 24px (24 base; sm 20, md 22, xl 28).

&#x20; Shadow: 0 2px 28px, color hsl(214.7 10.9% 34.3%) at 10% (sm adds 0 1px 2px -1px). Font Inter.

\- Dark (defined, unused): background #090b0f, foreground #f0f2f4, card #13161b, popover #1a1d22, primary #3a8cff,

&#x20; primary-foreground #040609, secondary #1c2024, secondary-foreground #d9dfe5, muted #181b1f, muted-foreground #8f9aa4,

&#x20; accent #152946, accent-foreground #a5d0ff, destructive #ff515a, border #26292e, input #26292e, ring #3a8cff,

&#x20; chart 1-5: #3a8cff #00b793 #9b61ea #ff7527 #fb3a7f. Shadow 0 4px 40px, black at 45%.

\- Driver screens: large touch targets, one-handed use, readable in bright sun, minimal typing.



\## Repo layout (one repo, three folders)

\- `app/` Flutter app. `lib/core` (theme, router, firebase init, utils), `lib/features/{auth,trips,fuel,feed,

&#x20; evidence,admin,reports}`, each with data/ (repositories), domain/ (models), presentation/.

\- `backend/` firestore.rules, firebase.json, seed.js, drivers.example.json, drivers.local.json (gitignored),

&#x20; package.json, tests/ (rules tests).

\- `worker/` Cloudflare Worker (wrangler.toml, src/). `docs/` notes and `docs/samples/` for the OCR sample photos.

\- Root `.gitignore` covers: service-account keys, credentials files, drivers.local.json, keystore, .env, node\_modules,

&#x20; build outputs.



\## Commands (PowerShell)

\- App: `cd app; flutter pub get; flutter doctor; flutter devices; flutter run`

\- Seed: `cd backend; $env:GOOGLE\_APPLICATION\_CREDENTIALS="C:\\secrets\\tanktrail-sa.json"; node seed.js`

\- Reset a password: `node seed.js --reset user@example.com`

\- Rules: `firebase deploy --only firestore:rules`; tests: `firebase emulators:exec --only firestore "npm test"`

\- Release APK: `flutter build apk --release`. The SAME signing keystore is required for every future update; keep it

&#x20; gitignored and tell the owner to back it up safely. Losing it means drivers must uninstall to update.



\## Git

\- Remote: https://github.com/mvntaha/tanktrail.git (private). `main` holds only milestones the owner has confirmed.

\- One branch per milestone, named `m<N>-<short-name>` (e.g. `m0-environment`), created from `main` before any work.

\- Small commits. Before each commit: review `git status` and `git diff --staged`, and check that no secrets are staged.

\- After the owner confirms on the phone: `git checkout main; git merge --no-ff m<N>-...; git tag m<N>; git push origin main --tags`

&#x20; (push the milestone branch too). Never force-push `main`. Never rewrite pushed history.



\## Milestones (one at a time; stop after each for the owner's check on the phone)

0\. Environment: Android SDK + JDK, `flutter doctor` green, phone connected via USB, hello-world runs, Firebase/FlutterFire

&#x20;  CLI login, decide dev vs single Firebase project, Windows Developer Mode, git init + private repo.

1\. Backend: firebase.json, rules v1, seed script + drivers files, create accounts, rules tests pass.

2\. App skeleton: theme tokens, login, role routing, first-login location notice, empty driver/admin homes.

3\. Trips: start/end with typed odometer + required photo + GPS (local only, no upload yet).

4\. Fuel log form + in-app capture (odometer, pump photo, pump video) + hash + local save. Start with the OCR test.

5\. Cloudflare Worker + Cloudinary signed uploads + drift queue + background upload + full offline test (airplane mode).

6\. Driver feed + edit flow with history and "edited" badge.

7\. Admin: dashboard, log detail with evidence viewer and map, approve/reject/reopen, flags, vehicle settings, places.

8\. Reports: CSV, PDF, WhatsApp share, reimbursement view.

9\. Hardening: rules review + tests, release signing, App Distribution, real-device offline soak test.



\## Decisions to ask the owner when reached (do not assume)

\- Dev vs single Firebase project (M0). Phone Android version (M0). Package ID (default suggestion com.tanktrail.app).

\- Alto tank size, typical km/L, current petrol price per liter (blank is fine; flags stay off).

\- Apply edit rules to trips too? Edit time limit? Report layouts. Video size/quality trade-off after real tests.

\- Cloudflare signup (must not require a card; if it does, stop and discuss). App Check enforcement.



\## Unverified facts (check before relying on them)

Cloudinary free-tier limits; whether Firebase Storage still requires Blaze; whether App Check / Play Integrity

accepts sideloaded APKs; App Distribution availability on Spark; current Firestore free quotas; current maintenance

status and versions of every package above.

