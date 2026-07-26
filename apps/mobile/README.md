# Medical Box Flutter app

The iOS and Android client for “우리집 구급키트.” Household members, pouches,
inventory, reminders, renewal preparation, and selected official pill
appearances remain in the encrypted on-device Drift database.

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
- Remote pill-image binaries are displayed from the official URL and are not
  copied into app-owned storage.
- Share text is assembled on device. Official appearance is opt-in, private
  notes are off by default, and the user sees a preview before sharing.

## Verification

```bash
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
fvm flutter build ios --no-codesign
```

Local Android emulator QA may inject
`http://10.0.2.2:8000/api` through `MEDICAL_BOX_API_BASE_URL`. Plain HTTP is
allowed only by the debug manifest; release builds keep the production HTTPS
boundary.
