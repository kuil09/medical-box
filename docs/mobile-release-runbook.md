# Mobile closed-beta release runbook

## Boundary

The `Mobile release build` workflow creates signed Android and iOS store
artifacts. It does not upload them to Google Play or App Store Connect. Store
upload remains a separate, account-authenticated promotion step so an artifact
cannot reach testers merely because signing secrets exist.

Normal pull-request CI performs two compile-only release checks:

- an unsigned Android App Bundle built only with
  `MEDICAL_BOX_ALLOW_UNSIGNED_RELEASE=true`; and
- an unsigned iOS release build.

The Android Gradle configuration rejects any other release task unless all four
signing properties are present and the keystore file exists. Debug builds remain
independent of release credentials.

## Protected GitHub environment

Create a GitHub environment named `closed-beta`, disable administrator bypass,
and permit deployment only from `main`. When the repository billing plan
supports required reviewers, require an account-owner approval before
deployment. Until then, workflow dispatch itself is restricted to repository
writers and store promotion remains a separate manual approval. Store the
following values as environment secrets. Do not use repository variables or
committed files for signing passwords, certificate archives, provisioning
profiles, or provider configuration.

### Shared provider configuration

| Secret | Purpose |
| --- | --- |
| `GOOGLE_SERVER_CLIENT_ID` | Backend Web OAuth audience embedded in both apps |
| `GOOGLE_IOS_CLIENT_ID` | Native iOS Google OAuth client |
| `KAKAO_NATIVE_APP_KEY` | Kakao native application key and callback scheme |

### Android signing

| Secret | Purpose |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded upload keystore |
| `ANDROID_STORE_PASSWORD` | Upload keystore password |
| `ANDROID_KEY_ALIAS` | Upload key alias |
| `ANDROID_KEY_PASSWORD` | Upload private-key password |
| `ANDROID_UPLOAD_CERT_SHA256` | Expected upload certificate SHA-256 fingerprint |

Generate the upload key once on an operator-controlled machine and keep at least
one encrypted offline recovery copy. The repository contains only
`apps/mobile/android/key.properties.example`; actual `key.properties`, JKS, and
keystore files are ignored.

The workflow validates the keystore and alias before building, verifies the AAB
signature and exact upload-certificate fingerprint, and publishes the signed AAB
plus its certificate description as a seven-day GitHub artifact.

The upload certificate is not the Google Play App Signing certificate. After a
Play app is created, use the Play App Signing SHA-1 for the production Android
Google OAuth client and its SHA-256 for
`/.well-known/assetlinks.json` through `ANDROID_CERT_SHA256`.

### Apple signing

| Secret | Purpose |
| --- | --- |
| `APPLE_DISTRIBUTION_CERTIFICATE_BASE64` | Base64-encoded distribution P12 |
| `APPLE_CERTIFICATE_PASSWORD` | P12 import password |
| `APPLE_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile |
| `APPLE_EXPORT_OPTIONS_PLIST_BASE64` | Export options for App Store Connect |
| `APPLE_KEYCHAIN_PASSWORD` | Ephemeral CI keychain password |

The provisioning profile must cover `com.medicalbox.app`, Associated Domains,
and Sign in with Apple for team `GS344U4ZSG`. The workflow imports all signing
material into an ephemeral keychain, creates the IPA, verifies its code
signature and entitlements, uploads a seven-day artifact, and deletes the
temporary keychain and profile.

`ios/Flutter/ReleaseSecrets.xcconfig` carries the Kakao callback value and the
Google reversed client ID derived from `GOOGLE_IOS_CLIENT_ID` only during the
protected build and is ignored by Git. The archive verification step confirms
that the resulting callback scheme matches the configured iOS OAuth client.

## Build

Run `Mobile release build` manually with:

- `platform`: `android`, `ios`, or `both`;
- `build_name`: a three-part store version such as `0.1.0`; and
- `build_number`: a positive integer that has never been uploaded before.

Both platform jobs fail before compilation if any required input or secret is
missing. A successful job is evidence only for a signed artifact, not for store
acceptance.

## Store promotion

1. Recover or verify the Google Play developer account.
2. Create the Play app, enable Play App Signing, and register the resulting
   signing fingerprints with Google OAuth and the production API.
3. Upload the verified AAB to the internal track and complete Data safety,
   content rating, target audience, privacy, support, and tester access.
4. Sign in to App Store Connect, create the app record, and verify bundle ID,
   Sign in with Apple, privacy, support, and export-compliance metadata.
5. Upload the verified IPA, wait for processing, attach it to an internal
   TestFlight group, and complete beta-review metadata if external testing is
   requested.
6. Perform Google, Apple, and Kakao login, reauthentication, logout, and
   disposable-account deletion on store-installed builds.

Record store build IDs, signing fingerprints, tester-group evidence, and the
provider E2E results in `docs/closed-beta-release-evidence.md`.
