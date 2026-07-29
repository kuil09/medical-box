# Closed-beta release evidence

Evidence date: 2026-07-28

> Historical evidence notice: the anonymous mobile onboarding observations in
> this record were superseded by the required-account product decision dated
> 2026-07-29. They remain here only as evidence of the earlier build and are not
> current release requirements. Anonymous catalog requests must still fail.

## Scope

This record covers the requested authentication and catalog entitlement
boundary, mobile application QA, production API rollout, legal-review
preparation, and the production backup/restore verification recorded in
`docs/production-backup-restore.md`. Acquisition of additional official catalog
sources remains a separate release gate.

## Production deployment

The initial Railway API deployment shipped the catalog-safety release for
commit `9efed852a6eff664efccb30c65827b4d5c84a559`. Its successor then completed
successfully for commit `e205941a65281bcb713c5e9832d1f1cb366f7563`.
Deployment identifiers are retained in the private Railway audit log rather
than this public evidence record. The running API uses:

- repository root directory `services/backend`;
- the Dockerfile builder;
- `/api/health/ready` as its health check;
- the Singapore Railway region; and
- the production PostgreSQL service through Railway private networking.

Railway IaC created the `catalog-sync` function and linked its public-data key
to the existing API secret without printing it. Its start command is
intentionally a no-op. The reviewed five-change no-cost plan removed its cron
and restricted source watching to the intentionally absent
`.railway/catalog-sync-activation` sentinel. The stub cannot consume scheduled
runtime or mutate the catalog while the capacity reserve and isolated
recurring-run canary remain blocked.

The following production paths returned HTTP 200:

- `/`
- `/privacy`
- `/terms`
- `/support`
- `/account-deletion`
- `/api/health/live`
- `/api/health/ready`
- `/.well-known/apple-app-site-association`
- `/.well-known/assetlinks.json`

An anonymous request to `/api/v1/catalog/meta` returned HTTP 401. The live
response included HSTS, `nosniff`, `no-referrer`, and a restrictive permissions
policy. A request with an invalid Host header was rejected before it reached a
valid application route.

## Authentication and entitlement

Automated backend coverage passed for:

- Google, Apple, and Kakao token signature, issuer, audience, and expiry
  validation;
- forged, expired, and wrong-audience provider tokens;
- provider exchange and account creation;
- explicit `catalog:read` entitlement;
- catalog HTTP 401, 403, and 200 boundaries;
- rotating refresh tokens and refresh-token reuse detection;
- logout and immediate entitlement revocation;
- provider reauthentication and account deletion.

`services/backend/scripts/verify_deployed_auth.py` provides a token-safe
deployment probe for provider exchange, profile retrieval, catalog entitlement,
refresh rotation, and logout. It accepts short-lived credentials only through
the process environment and never prints them.

The dedicated Google Cloud project `medical-box-503706` now has an external
testing consent configuration, the account owner as a test user, production
homepage/privacy/terms URLs, and `outoftokens.ai` as an authorized domain. Web,
Android debug, and iOS OAuth clients were created. The Web client ID is
configured on the Railway production API service, and a forged Google token
receives HTTP 401 instead of a missing-configuration HTTP 503.

The Android emulator restored a real Google production session for the only
current production account. The Settings login surface reported that catalog
permission was confirmed. The same session opened the official detail for
`핀테정(에포니디핀염산염)`, rendered both pill variants and three DUR categories,
and loaded the `용량주의 · 공고 2014.10.24` rule from production. This is live
evidence for Google session restoration, `catalog:read` entitlement, product
detail, appearance variants, and DUR detail. The captured artifact is
`design/audit/flutter-09-google-production-dur.png`.

The configured Android client is restricted to `com.medicalbox.app` and the
current local debug certificate. A separate Android client must be created after
the Play App Signing SHA-1 is available. Production Kakao and Apple verification
identifiers remain incomplete. Account-deletion E2E must use a disposable beta
account rather than deleting the only entitled production identity.

## Android application QA

The debug APK was built with Flutter 3.44.7, installed on an API 35 Android
emulator, and operated through the platform accessibility tree. Distributed
builds now use the production API; local backend overrides remain available for
development.

Observed passing flows:

- the shared medicine box opens and exposes the medicine inside as selectable
  UI, then closes again;
- an existing medicine quantity was edited from one to two and persisted;
- a local medicine was added, displayed inside the open box, and removed;
- the catalog-search surface showed the signed-out permission state without
  blocking manual local registration;
- a family member and personal pouch were added;
- the personal pouch appeared as a top tab and opened from that tab;
- the family member and pouch were removed;
- Settings was available as a separate navigation destination;
- encrypted export created a versioned `.medicalbox` file and opened the
  platform share sheet;
- the selected-field medicine sharing preview excluded personal notes by
  default and included quantity, expiry status, and an official product link;
- the Android share sheet received the preview and offered Messages as a
  target; and
- the pre-configuration Google flow reached the platform Google account
  sign-in screen; the source now requires an explicit Web client ID before
  starting that flow so a build cannot continue into a backend HTTP 503; and
- a restored real Google production session opened a permissioned official
  detail and expanded a live DUR rule.

The first family-add run exposed a Flutter framework assertion caused by
disposing a dialog `TextEditingController` before the route transition had
finished. The family add and rename dialogs, plus the Settings password dialog,
now use controller-free form state. The same add, top-tab navigation, and remove
flow passed after rebuilding and reinstalling the application.

The final no-cost integration build was also installed on a separate API 35
tablet AVD so the previously retained Google session and phone QA data were not
modified. Accessibility-tree evidence confirmed:

- `/app/settings` could not bypass incomplete onboarding;
- anonymous onboarding reached the shared-box home without login;
- Settings remained a separate navigation destination;
- denying notification permission and completing the add-reminder picker left
  the reminder list empty;
- Kakao and Google controls remained disabled until the current terms and
  privacy confirmation was checked, then became enabled; and
- Apple sign-in remained absent on Android.

The first launch emitted the secure-storage package's one-time cipher migration
warning. A process restart emitted no secure-storage warning and produced no
app crash.

### Device-local data boundary

A second Android run exercised both local-data families with non-identifying
test values between `2026-07-27T15:24:26Z` and
`2026-07-27T15:37:33Z`:

- a local medicine was created with quantity 7, edited to quantity 86, and
  deleted;
- a family member and personal pouch were created and deleted; and
- the empty family list and the pre-existing inventory were restored after the
  run.

Railway production HTTP logs contained zero requests from the start of that
interval onward. A wider 25-minute control window contained only two requests,
both before the test interval: `GET /api/health/ready` with HTTP 200 and an
anonymous `GET /api/v1/catalog/meta` with HTTP 401. No production POST, PATCH,
or DELETE request occurred, and none of the local test markers appeared in
server HTTP logs. The observed local mutations therefore did not cross the
production API boundary.

## Build and test evidence

- Flutter formatting check: 41 files, no changes required.
- Flutter analysis: passed with no issues.
- Flutter unit, widget, local-data, auth-race, app-link, catalog-projection,
  account-deletion, temporary-export cleanup, reminder compensation,
  autocomplete ordering, and public-share-link tests: 68 passed.
- Flutter golden tests: passed.
- Android debug APK build: passed.
- Android notification merged-manifest verification: passed for notification
  permission, scheduled receiver, boot receiver, boot-completed, and
  package-replaced entries.
- Android compile-only unsigned release AAB: passed, 69.7 MB.
- iOS release no-codesign build: passed, 31.5 MB.
- Backend Ruff: passed.
- Backend MyPy strict mode: passed.
- Backend Pytest: 217 passed.
- Alembic upgrade to `20260728_0005 (head)`: passed on an isolated database.
- OpenAPI regeneration and committed-spec comparison: passed twice; SHA-256
  `03933ae037207b72c1f15d10b2e207f17692ce69251a7bcd2ee40acae27ea8af`.
- Local encrypted PostgreSQL backup/restore round trip: passed with one restored
  product and verified cleanup.
- Railway TypeScript IaC compilation: passed.
- Railway plan guard and production-monitor tests: 11 passed.
- CI path classifier: 7 scenarios passed.
- Workflow YAML and production-monitor shell parsing: passed.
- Product Design prototype runtime integrity: 28 protected files passed; the
  514-module production build completed.
- Repository credential scan: all tracked and non-ignored files checked, zero
  prohibited credential files and zero high-confidence secret hits.
- GitHub Actions run `30244655755`: all five jobs passed
  (`backend`, `flutter`, `flutter-ios`, `infrastructure`, and
  `product-design-prototype`).
- Pull request 8 run `30279320950`: the same five jobs reached final SUCCESS
  after the merge.

The first local iOS no-codesign attempt was blocked by Finder metadata on the
generated Flutter framework under the local Documents directory. Removing that
metadata from the generated build artifact allowed the same build to pass. The
source tree did not require an iOS code change.

## Mobile release readiness

Pull request 10 introduces fail-closed mobile release packaging:

- Android release tasks require a real keystore and complete
  `android/key.properties` values. A negative dry run without signing
  configuration failed with the expected configuration error.
- The compile-only CI escape hatch is explicit and limited to
  `MEDICAL_BOX_ALLOW_UNSIGNED_RELEASE=true`; it cannot produce a store-signed
  artifact.
- A Flutter 3.44.7 unsigned release AAB compiled successfully and measured
  69.7 MB. `keytool` confirmed that the compile-only artifact was not signed.
- An iOS release no-codesign build compiled successfully with Flutter 3.44.7 in
  a non-File-Provider temporary checkout. The output was a 31.5 MB arm64
  `Runner.app`; `codesign` confirmed that it was intentionally unsigned.
- Google and Kakao release identifiers are build-time values rather than
  committed secrets. Selecting Kakao login without a configured native app key
  now fails with an explicit configuration error.
- The protected manual `Mobile signed-build verification` workflow validates
  all required Android and iOS signing inputs, creates ephemeral signing
  material, and verifies the resulting AAB or IPA. It uploads no signed binary
  as a GitHub Actions artifact and removes the complete platform build output
  and signing material in an always-run cleanup step. The cleanup continues
  after individual failures, verifies every target is absent, and fails closed
  after all deletion attempts finish.
- The public repository's Actions artifact inventory was empty, and the signed
  verification workflow had no historical runs, so no older signed AAB or IPA
  remained exposed when this boundary was hardened.
- Korean Play Store and App Store metadata source files are committed under
  `store/metadata/ko-KR`. Medical claims are limited to organization,
  reference, renewal-readiness, and sharing functions. A support URL is used
  until a public support email is approved.

The GitHub `closed-beta` environment exists, rejects administrator bypass, and
permits deployment only from `main`. The repository is public. The environment
does not currently name an independent required reviewer; the manual workflow
remains restricted to users with repository write access, and store promotion
remains a separate account-authenticated step.

The Android upload key was generated once outside the repository at
`~/.private_keys/medical-box/medical-box-upload.jks`. Its passwords and alias
are held in macOS Keychain. The keystore, passwords, alias, production Google
Web client ID, and Google iOS client ID are installed as `closed-beta`
environment secrets. The expected upload-certificate SHA-256, Kakao native key,
and Apple distribution inputs remain activation gates. No secret value is
committed.

The upload certificate fingerprints are:

- SHA-1:
  `B0:F5:CD:F2:8C:2C:8B:4D:67:40:F2:1C:19:CC:AB:B3:E1:3C:20:18`
- SHA-256:
  `FC:04:00:2E:D5:75:85:9E:A5:EA:23:3E:F8:8B:00:1E:D0:52:8F:E4:20:4A:4F:05:85:C1:2D:85:B4:4A:1C:26`

These are upload-key fingerprints, not Play App Signing fingerprints. They
must not be used for the production Android OAuth client or
`/.well-known/assetlinks.json`.

GitHub Actions runs `30283835780` and `30285348475` previously failed before
runner allocation while the repository was private and the account had a zero
spending limit. After the repository became public, pull request 10 CI run
`30319463102` completed successfully across backend, Flutter, iOS, prototype,
and infrastructure jobs. CodeQL runs `30319461144` and `30319461448` also
completed successfully. The former billing constraint no longer blocks pull
request validation.

## Legal review

`docs/legal-review-packet.md` defines the required external decisions for
medicine wording, medical-device positioning, Singapore account-data transfer,
social-login disclosures, account deletion, public-data attribution and image
rights, and emergency sharing.

This preparation is not legal approval. External beta promotion remains blocked
until a qualified Korean reviewer records dated approval and any required edits
are implemented and reverified.

## Store-account gates

The Google Play Console account `lv0gun9` reports that the developer profile and
all apps were deleted after the account-verification deadline on 2024-08-19.
The Create app action is disabled. Internal testing cannot be created until the
account owner completes Google Play developer-account recovery or establishes a
verified replacement account. The recovery wizard is open at its first
user-controlled step. It requires an individual-or-organization choice, a
Google payments profile, account details, private contact details, and public
developer-profile details.

App Store Connect reached the Apple sign-in page, but the available passkey
attempt returned an error. The local project has automatic signing, team
`GS344U4ZSG`, and bundle identifier `com.medicalbox.app`, but the current
Keychain contains no valid Apple code-signing identity and the installed
provisioning profiles do not cover `com.medicalbox.app`. TestFlight and CI
signing remain blocked until the account owner completes Apple sign-in and
two-factor authentication, then creates or downloads the distribution
certificate and App Store profile.

The Kakao Developers console is signed out. Railway production also lacks
`KAKAO_APP_ID`, `APPLE_TEAM_ID`, and the Play App Signing
`ANDROID_CERT_SHA256`. Kakao application registration and the final
Apple/Android identifiers require the respective authenticated provider and
store accounts.

The public-data portal is also signed out in the retained browser session.
Recall, supply-interruption, and HIRA-price application or approval state cannot
be changed until the account owner signs in. Production probes for all three
currently return HTTP 403.

## Catalog promotion and staging retirement

On 2026-07-27, the validated catalog was promoted into the production
PostgreSQL database after creating and verifying a pre-promotion logical
backup. Counts and canonical fingerprints matched across all 13 catalog tables.
Authentication rows matched a disposable restore of the backup, and production
readiness, authentication enforcement, metadata, search, detail, and DUR probes
passed.

Production contains 78,090 products, 89,697 ingredient rows, 4,739 consumer
information rows, 25,363 identification variants, 860,199 DUR rules, and
1,102,783 raw source records. Database plus WAL measured 3,556,611,775 bytes on
the 5 GB volume.

The staging Railway environment and its custom domain, catalog-sync service,
databases, and volumes were then retired. Production is the only persistent
Railway environment.

An isolated PostgreSQL 18 restore subsequently loaded the official HIRA
standard-code file: 305,522 rows succeeded in 43.08 seconds, product count stayed
at 78,090, no index became invalid, and measured database growth was
358,203,392 bytes.

The first production load then succeeded in 746.69 seconds:

- raw and active standard-code records: 305,522;
- normalized standard codes: 305,522;
- unchanged products: 78,090;
- invalid indexes: 0;
- checkpoint SHA-256:
  `8f177ced6a93fefa439535125aeb4f626e9d386fa5700271094ca26bdcb50ff0`;
- PostgreSQL `max_wal_size` / `min_wal_size`: 96 MB / 32 MB; and
- database plus retained WAL: 3,865,712,319 bytes, leaving
  1,134,287,681 bytes on the configured 5 GB capacity.

The three unauthorized sources are disabled in `source_registry` and excluded
from the scheduled allowlist. Production readiness remained HTTP 200 and an
anonymous metadata request remained HTTP 401 after the load.

A read-only query against production returned one installed `pg_trgm`
extension. The pre-no-cost-graph Railway IaC plan reported production up to
date at that historical point, and the readiness endpoint returned HTTP 200.
The later five-change no-cost plan was applied on 2026-07-28. The API and
catalog stub deployments both reached `SUCCESS`, the follow-up Railway plan
reported no pending changes, and the no-cost guard passed.

## Production monitoring

`.github/workflows/production-monitor.yml` probes the product, legal, support,
health, well-known, authentication-boundary, HSTS, and `nosniff` behavior on
manual dispatch. Well-known files must return a direct HTTP 200 with
`application/json` and parse as valid JSON; redirects are rejected. Manual
dispatch requires the exact expected Apple app ID and Play App Signing SHA-256
fingerprint.

The workflow is manual-only until the external Apple and Play identifiers
exist. This allocates no scheduled runner and prevents an unconfigured skipped
job from appearing as successful ownership evidence. After both identifiers
are confirmed, a separate reviewed change may add a schedule together with
fixed expected values only after one exact manual run passes.

Manual run `30276771772` completed successfully after the original workflow was
merged. Scheduled run `30281631480` then completed successfully for commit
`cce7671dbe67a8b4342a7429c38e2c5aaebfee98`, independently proving the GitHub
scheduler path. Those runs predate the semantic metadata gate. A new passing
run must be recorded after `APPLE_TEAM_ID`, the Play App Signing
`ANDROID_CERT_SHA256`, and the two expected-identifier repository variables are
configured.
