# Closed-beta release evidence

Evidence date: 2026-07-27

## Scope

This record covers the requested authentication and catalog entitlement
boundary, mobile application QA, production API rollout, and legal-review
preparation. Public-data key acquisition, database backup or `pg_trgm`
operations, and acquisition of additional official catalog sources were
explicitly excluded from this pass.

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
configured on the Railway production and staging API services; both variable
deployments reached `SUCCESS`, and a forged Google token now receives HTTP 401
instead of a missing-configuration HTTP 503.

Real Google provider exchange is not yet release evidence. The configured
Android client is restricted to `com.medicalbox.app` and the current local debug
certificate. A separate Android client must be created after the Play App
Signing SHA-1 is available. The emulator reached Google's account sign-in
surface, but credential entry remains a user-only step. Production Kakao and
Apple verification identifiers are also incomplete. Until a real beta-account
probe passes for each enabled provider, social-login E2E remains blocked.

## Android application QA

The debug APK was built with Flutter 3.44.7 and the staging API base URL,
installed on an API 35 Android emulator, and operated through the platform
accessibility tree.

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
  starting that flow so a build cannot continue into a backend HTTP 503.

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
- Backend Pytest: 32 passed.
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
