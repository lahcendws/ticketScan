# AGENTS.md

Flutter (Dart) app "TicketScan" — scans receipts with the camera, extracts data via OCR, tracks warranties. Backend is **Supabase** (migrated from Firebase; Firebase files are dead code). All UI strings and git history are French; follow that convention.

## Commands

- Run the app: `flutter run` (requires a valid `.env` — see below)
- Analyze: `flutter analyze`
- Tests: `flutter test`
- Single test file: `flutter test test/unit/subscription_test.dart` (tests live in `test/unit/` and `test/widget/`)
- Release build: bump `version:` in `pubspec.yaml`, then `flutter build apk --release`
- Regenerate launcher icons after changing assets: `dart run flutter_launcher_icons` (config lives in `pubspec.yaml`)

## Environment & backend

- `.env` (gitignored) holds `SUPABASE_URL` and `SUPABASE_ANON_KEY`. `lib/main.dart` loads it via `flutter_dotenv` and `lib/supabase_options.dart` reads it with `!` — the app **crashes at startup if `.env` is missing**. Create a local `.env` from the committed template values if the project is freshly cloned.
- Supabase schema in use: `tickets` (user rows), `profiles` (`is_premium` flag), `app_config` (`min_version`, `is_under_maintenance`, `update_url` for the version gate).
- Supabase edge functions used by the app: `analyze-ticket` (OCR, images as `base64`), `verify-purchase` (IAP receipt). They are not in this repo.
- Firebase leftovers are dead and must NOT be regenerated with `flutterfire` or relied on: `lib/firebase_options.dart`, `lib/core/services/firebase_service.dart` (commented out), `firebase.json`, Firebase constants in `lib/core/constants/app_constants.dart`.

## Entrypoints & dead-code trap

- `lib/main.dart` = the real app (Supabase + notifications + IAP + providers).
- `lib/main_simple.dart` = offline-only variant (no backend), which is the ONLY consumer of the `*_simple.dart` pages (`home_page_simple.dart`, `tickets_page_simple.dart`, `search_page_simple.dart`). Don't treat those as dead — but don't build new features into them either; they are a separate stripped build.

## Localization (custom, hand-rolled)

- No gen-l10n/ARB files. Strings are static `_fr` / `_en` maps in `lib/core/services/app_localizations.dart`, read via `AppLocalizations.of(context)?.get('key')`.
- Adding or changing a string requires editing **both** maps. Default locale is French (`Locale('fr','FR')`).
- `lib/core/constants/app_constants.dart` has `appVersion = '1.0.0'` — it is stale and NOT the source of truth; the real version is `pubspec.yaml`. Update `app_constants.dart` if it matters (nothing currently reads it).

## Business rules

- Free tier is capped at **3 tickets** (`SubscriptionService._freeLimit = 3`, enforced via `canScan()`). Premium is `profiles.is_premium` on Supabase. Recent work has been tightening these rules — check `subscription_service.dart` before touching anything limit-related.
- Warranty reminders schedule 30 days before expiry. Notifications MUST use `AndroidScheduleMode.inexactAllowWhileIdle` — exact alarms crash on Android 12+ (current branch is literally `fix-exact-alarms-not-permited`).

## Tests

- `test/unit/*` = pure logic (version compare, ticket parsing, subscription limits) — no mocking of Supabase needed.
- `test/widget/*` = pump widgets. Every widget under test must be wrapped in `MultiProvider` with `LanguageService`, `SubscriptionService`, `TicketProvider`, plus the `AppLocalizations` delegate and `Locale('fr','FR')`. Copy the pattern from `test/widget/ticket_card_test.dart`.

## Android

- Application ID / namespace is `com.devevolu.ticketscan` (`android/app/build.gradle.kts`), minSdk forced to 21, core library desugaring enabled (needed for timezone/notifications).
- Release signing: `android/key.properties` (gitignored) supplies credentials for the `release` build type. `upload-keystore.jks` is gitignored but must be present locally to build a release — keep a backup, it cannot be recovered from git. Never commit secrets or keystores.
- `avoid_print` is disabled (see `analysis_options.yaml`) and `print()` is used across services — acceptable style here.

## Workflow

- Branch-per-feature with French commit messages, merged to `main`; no CI. Version bump in `pubspec.yaml` is done manually as part of release prep (see "PASSAGE AUX TESTS FERMÉS" comment there).
