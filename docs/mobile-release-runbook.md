# Mobile closed-beta release runbook

## Boundary

The `Mobile signed-build verification` workflow creates signed Android and iOS
store outputs only on an ephemeral protected runner. It verifies them and then
deletes the complete platform build directory and signing material in an
always-run cleanup step. It never uploads signed binaries to GitHub Actions
artifacts or to either store.

Cleanup records each failed deletion, continues attempting every remaining
target, verifies their absence, and fails the job only after all attempts finish.

This workflow is a signing-configuration gate, not an artifact distribution
channel. Store promotion requires a separately reviewed path that builds and
uploads directly within the same protected trust boundary, or an
operator-controlled machine. Do not reintroduce a public-repository Actions
artifact as an intermediate handoff.

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

The protected `closed-beta` environment also uses two non-secret variables for
Apple feature activation:

| Variable | Purpose |
| --- | --- |
| `APPLE_SIGN_IN_ENABLED` | Explicit operator request to expose native Apple sign-in in the iOS artifact |
| `APPLE_ACCOUNT_REVOCATION_READY` | Attestation that production Apple token exchange/revocation variables are configured and disposable-account deletion E2E passed |

The iOS build injects `APPLE_SIGN_IN_ENABLED=true` only when both variables are
exactly `true`. Missing or false values compile the app with Apple sign-in
hidden. Requesting Apple sign-in without the readiness attestation fails before
signing material is installed. The workflow never receives the Apple `.p8`
private key; it remains only in the backend secret boundary.

This artifact gate does not enable the production API. Railway must independently
set the backend `APPLE_SIGN_IN_ENABLED=true`, and the API still requires a valid
team ID, key ID, client ID, and private key before accepting Apple token
exchange. The backend flag defaults to false, so an unset deployment fails
closed even if a signed app accidentally exposes the button.

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

The workflow validates the keystore and alias before building and verifies the
AAB signature and exact upload-certificate fingerprint. The signed AAB,
certificate report, and signing material remain runner-local and are deleted by
the always-run, fail-closed cleanup step.

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
signature and entitlements, and deletes the full iOS build output, temporary
keychain, and profile. A failed deletion does not suppress later cleanup
attempts, and any remaining target fails the job. The IPA is never persisted as
a GitHub Actions artifact.

`ios/Flutter/ReleaseSecrets.xcconfig` carries the Kakao callback value and the
Google reversed client ID derived from `GOOGLE_IOS_CLIENT_ID` only during the
protected build and is ignored by Git. The archive verification step confirms
that the resulting callback scheme matches the configured iOS OAuth client.

## Build

Run `Mobile signed-build verification` manually with:

- `platform`: `android`, `ios`, or `both`;
- `build_name`: a three-part store version such as `0.1.0`; and
- `build_number`: a positive integer that has never been uploaded before.

Both platform jobs fail before compilation if any required input or secret is
missing. A successful job is evidence that an ephemeral signed output passed
local signature checks and cleanup completed. It does not produce a retrievable
artifact and is not evidence of store acceptance.

## Store promotion

1. Recover or verify the Google Play developer account.
2. Create the Play app, enable Play App Signing, and register the resulting
   signing fingerprints with Google OAuth and the production API.
3. Approve a store-connected promotion path that signs, verifies, and uploads
   directly from a protected runner, or perform the equivalent sequence on an
   operator-controlled machine. Do not copy a signed binary through GitHub
   Actions artifacts.
4. Upload the verified AAB to the internal track and complete Data safety,
   content rating, target audience, privacy, support, and tester access.
5. Sign in to App Store Connect, create the app record, and verify bundle ID,
   Sign in with Apple, privacy, support, and export-compliance metadata.
6. Upload the verified IPA, wait for processing, attach it to an internal
   TestFlight group, and complete beta-review metadata if external testing is
   requested.
7. Perform Google, Apple, and Kakao login, reauthentication, logout, and
   disposable-account deletion on store-installed builds.

Record store build IDs, signing fingerprints, tester-group evidence, and the
provider E2E results in `docs/closed-beta-release-evidence.md`.
