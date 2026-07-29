# Medical Box Flutter app

The iOS and Android client for “우리집 구급키트.” Household members, pouches,
inventory, reminders, renewal preparation, and selected official pill
appearances remain in the encrypted on-device Drift database.

## Access and local-data boundary

- App access requires a Kakao, Apple, or Google account.
- Authentication controls app entry, catalog permission, and future purchase
  restoration.
- Household, member, inventory, reminder, visit, and private-note data remain in
  the encrypted device database.
- Signing out locks the app without deleting the encrypted device database.

## On-device medicine recognition

The item editor can capture a package photo, run Korean OCR on-device, derive a
small set of search terms, and query the authenticated official catalog. The
temporary capture is deleted after recognition. The user must select a catalog
candidate explicitly; recognition never saves an item automatically.

## Monetization boundary

Provider-independent access tiers and privacy-safe banner placements are
defined, but live advertising is disabled by default. A production ad adapter,
store receipt verification, product identifiers, and prices require separate
approval.

## Toolchain

Flutter is pinned to `3.44.7` through FVM.

```bash
fvm install
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

## Catalog behavior

- Search and product detail require an authenticated account with the
  server-side `catalog:read` permission.
- Product detail shows all current official pill-identification variants.
- Selecting a variant stores its key, appearance summary, and official HTTPS
  image URL in the encrypted local inventory.
- DUR detail begins with category counts. Rules load only when a category is
  expanded and are never personalized against a household member.
- Official product-level concomitant contraindications are fetched for only the
  selected catalog item and matched against official item sequence values in
  the encrypted local inventory. The server never receives the household
  inventory list.
- The local match covers only catalog-linked medicines registered on this
  device. It is not a complete medication review and never replaces confirmation
  by a physician or pharmacist.
- Remote pill-image binaries are displayed from the official URL and are not
  copied into app-owned storage.
- Share text is assembled on device. Official appearance is opt-in, private
  notes are off by default, and the user sees a preview before sharing.

## Verification

```bash
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
ORG_GRADLE_PROJECT_MEDICAL_BOX_ALLOW_UNSIGNED_RELEASE=true \
  fvm flutter build appbundle --release
fvm flutter build ios --release --no-codesign
```

Local Android emulator QA may inject
`http://10.0.2.2:8000/api` through `MEDICAL_BOX_API_BASE_URL`. Plain HTTP is
allowed only by the debug manifest; release builds keep the production HTTPS
boundary.

Google builds must inject the Web OAuth client ID as
`GOOGLE_SERVER_CLIENT_ID`. iOS builds must additionally inject the iOS OAuth
client ID as `GOOGLE_IOS_CLIENT_ID`. The protected release workflow derives the
matching reversed callback URL scheme and injects it through
`GOOGLE_REVERSED_CLIENT_ID`; local builds may override the checked-in
development default in `LocalSecrets.xcconfig`. Kakao builds must provide
`KAKAO_NATIVE_APP_KEY` both as a build environment variable and a Dart define.
Provider client IDs are configuration values, not secrets; the IDs used by Dart
remain environment-specific build inputs.

## Release artifacts

Android distribution builds require `android/key.properties` and the referenced
upload keystore. Gradle rejects a release task when signing is incomplete;
`MEDICAL_BOX_ALLOW_UNSIGNED_RELEASE=true` exists only for compile-only CI and
must never be used for a store artifact.

iOS release builds read the Kakao callback value and Google reversed client ID
from the ignored `ios/Flutter/ReleaseSecrets.xcconfig`. Signed AAB and IPA
artifacts are produced only by the protected `Mobile release build` workflow
described in `docs/mobile-release-runbook.md`.
