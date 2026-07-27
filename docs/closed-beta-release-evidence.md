# Closed-beta release evidence

Evidence date: 2026-07-27

## Scope

This record covers the requested authentication and catalog entitlement
boundary, mobile application QA, production API rollout, legal-review
preparation, and the production backup/restore verification recorded in
`docs/production-backup-restore.md`. Acquisition of additional official catalog
sources remains a separate release gate.

## Production deployment

Railway production deployment
`ec142313-3400-4b7d-befe-3c403cc32ec5` completed successfully at
`2026-07-27T06:14:21.545Z`. The running API uses:

- repository root directory `services/backend`;
- the Dockerfile builder;
- `/api/health/ready` as its health check;
- the Singapore Railway region; and
- the production PostgreSQL service through Railway private networking.

`railway config plan` reported that the production environment matched
`.railway/railway.ts` after deployment. Production catalog acquisition remains
disabled in IaC; this pass did not create or run a production catalog cron.

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

## Build and test evidence

- Flutter analysis: passed with no issues.
- Flutter unit and local-data tests: 11 passed.
- Flutter golden tests: passed.
- Android debug APK build: passed.
- iOS release no-codesign build: passed.
- Backend Ruff: passed.
- Backend MyPy strict mode: passed.
- Backend Pytest: 38 passed.
- Alembic upgrade to head: passed.
- OpenAPI regeneration and committed-spec diff: passed.
- Railway TypeScript IaC compilation: passed.
- GitHub Actions run `30244655755`: all five jobs passed
  (`backend`, `flutter`, `flutter-ios`, `infrastructure`, and
  `product-design-prototype`).

The first local iOS no-codesign attempt was blocked by Finder metadata on the
generated Flutter framework under the local Documents directory. Removing that
metadata from the generated build artifact allowed the same build to pass. The
source tree did not require an iOS code change.

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
verified replacement account.

App Store Connect reached the Apple sign-in page, but the available passkey
attempt returned an error. The local project has valid Apple Development and
Apple Distribution identities for team `GS344U4ZSG`, automatic signing, and
bundle identifier `com.medicalbox.app`. TestFlight work remains blocked until
the account owner completes Apple sign-in and two-factor authentication in the
existing browser session.

The Kakao Developers console is signed out. Railway production also lacks
`KAKAO_APP_ID`, `APPLE_TEAM_ID`, and the release `ANDROID_CERT_SHA256`. Kakao
application registration and the final Apple/Android identifiers require the
respective authenticated provider and store accounts.

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
358,203,392 bytes. The production cron and first production load require the
run-gated ingestion deployment and the documented 96 MB PostgreSQL WAL limit.

## Production monitoring

`.github/workflows/production-monitor.yml` probes the product, legal, support,
health, well-known, authentication-boundary, HSTS, and `nosniff` behavior every
15 minutes and on manual dispatch. Activation evidence requires this branch to
be merged, a manual workflow dispatch to pass, and at least one scheduled run
to complete.
