# Closed beta release checklist

Evidence date: 2026-07-30

## Automated gates

- [x] Product Design runtime integrity and production build
- [x] Flutter analyze, unit/widget/golden tests, Android build, and iOS no-codesign
  build
- [x] Android merged notification manifest, reboot receivers, permission-denial
  persistence boundary, and reminder rollback tests
- [x] Reminder enable/delete and inventory/pouch cascade mutations compensate
  across SQLite and the OS scheduler; permission state is refreshed on resume
  and before scheduling
- [x] Catalog autocomplete rejects stale responses and clears every official
  linkage on manual edits; shared product links use the public MFDS detail page
- [x] Ruff, MyPy, Pytest, Alembic upgrade, and OpenAPI drift check
- [x] Local inventory CRUD and encrypted export/import round trip
- [x] Provider token and refresh-token rotation/reuse tests
- [x] Refresh/logout concurrency is serialized by token family, and destructive
  reauthentication requires a provider proof issued or authenticated within five
  minutes
- [x] Account deletion fail-closed tests cover grant-provider linkage, Google
  and Kakao client revocation boundaries, and Apple authorization-code
  exchange, subject matching, and server-side token revocation
- [x] Login requires an explicit current terms/privacy confirmation, and the
  API rejects missing, false, or stale terms acceptance before creating an
  account
- [x] Catalog routes return `401` without a token, `200` for every registered
  account by default, and `403` after an explicit operator revocation that
  persists across later provider sign-ins
- [x] Catalog pagination, retry, duplicate, schema, partial-failure, and count-drop
  tests

## Infrastructure gates

- [x] Reviewed Railway desired-state plan reports `0 add, 5 change, 0 destroy`;
  it creates no backup service, bucket, or Operations group and only removes
  the catalog cron/automatic watches plus sets three documented variables.
- [x] Applied the reviewed no-cost plan and verified production has no catalog
  cron or ordinary-source watch
- [x] API and PostgreSQL run in Railway Singapore
- [ ] Railway-native or approved off-device daily, weekly, and monthly backups
  enabled. The encrypted bucket worker, signed manifests, retention logic, and
  disposable-restore workflow pass local validation; the Railway bucket and
  dedicated Singapore restore runner are excluded from the no-cost release.
- [x] Disposable production-backup restore performed and documented within the
  current month
- [ ] Dedicated production backup private key copied to an approved offline
  recovery location. The local mode-`0600` key set exists, but a second
  recovery copy has not been authorized.
- [x] `pg_trgm` activated once in production
- [x] DNS CNAME, automatic TLS, HSTS, allowed-host filtering, web/legal/API/health,
  and HTTP delivery of both `/.well-known` paths verified
- [ ] Production well-known metadata passes the semantic release gate with a
  configured Apple team app ID and at least one Play App Signing SHA-256
  fingerprint. The monitor fails closed on `UNCONFIGURED` and empty lists.
- [ ] Approved-source recurring catalog mutation enabled. The current remote
  cron can start only the no-op stub; the reviewed no-cost desired state removes
  that schedule until the capacity reserve and isolated recurring-run canary
  pass.
- [x] GitHub Actions manual production-monitor run `30276771772` and scheduled
  run `30281631480` passed the previous availability-only HTTP and header probes
- [ ] A manually dispatched production-monitor run passes with the exact Apple
  app ID and Play App Signing SHA-256 fingerprint. The workflow is manual-only
  and allocates no scheduled runner until those external identifiers exist.
  Add a schedule only with fixed expected values after an exact manual run
  passes; an availability-only or skipped run is not release evidence.

## Product and privacy gates

- [x] First-use onboarding requires account creation or sign-in before entering
  organizer routes; returning users see an explicit session-restoration gate
- [x] Signing out locks all organizer routes without deleting encrypted local
  household data
- [x] Camera OCR is available only to an authenticated account with
  `catalog:read`, keeps the image on-device, deletes the temporary capture, and
  requires explicit confirmation of an official candidate
- [x] Account deletion offers an explicit account-only or account-and-device-data
  choice after provider reauthentication
- [x] Local deletion leaves the required account unless the user separately
  deletes it
- [x] Local deletion removes app-created temporary `.medicalbox` exports while
  preserving unrelated files and accurately warning that externally saved or
  shared copies require separate deletion
- [x] Lock-screen notifications hide medicine names by default
- [x] Android local medicine and family/pouch CRUD completes while the matching
  production HTTP-log interval remains empty
- [ ] Full approved official catalog load and source attribution pass review.
  HIRA standard codes are loaded; recall, supply-interruption, and HIRA-price
  APIs still return HTTP 403 and remain disabled.
- [ ] Legal review approves medicine wording and Singapore cross-border processing
  disclosure
- [ ] Mandatory-account App Review rationale and store disclosures pass legal
  and platform-policy review
- [ ] Advertising remains disabled until a provider is selected, sensitive
  categories are blocked, privacy/store disclosures are updated, and proxy
  tests show zero account or health identifiers in requests

## Provider and distribution gates

- [x] Real Google production login, restored session, entitlement, official
  detail, appearance, and DUR flow
- [x] Android release signing is fail-closed; compile-only unsigned AAB and iOS
  release no-codesign builds pass locally with Flutter 3.44.7
- [x] Protected manual mobile-release workflow validates secrets, signs and
  verifies runner-local store outputs, can upload the verified IPA directly to
  TestFlight, persists no signed AAB/IPA as a public Actions artifact, and uses
  an always-attempt, fail-closed cleanup for build outputs, upload keys, and
  signing material
- [x] GitHub `closed-beta` environment exists, permits only `main`, and rejects
  administrator bypass. Store promotion remains a separate account-authenticated
  action.
- [x] Android upload key is stored outside the repository with credentials in
  macOS Keychain, and its signing secrets plus both Google client IDs are
  installed in the protected environment
- [x] The protected environment contains and successfully validates all Apple
  distribution-signing and App Store Connect upload inputs
- [ ] The protected environment contains the expected Android upload-certificate
  SHA-256
- [ ] Kakao native key is installed before Kakao login is exposed in a store
  build; an omitted key keeps the provider hidden
- [x] Korean Play Store and App Store metadata source files are versioned
- [x] Pull request 10 full CI run `30319463102` and both CodeQL runs pass after
  the repository became public; the former private-repository billing gate no
  longer blocks validation
- [ ] Signed Android AAB uploaded directly from an approved protected boundary
  using the upload key and production provider identifiers
- [x] Signed iOS IPA uploaded directly from an approved protected boundary using
  the distribution certificate, provisioning profile, and production provider
  identifiers; workflow run `30507374176` completed archive-signature
  verification, TestFlight upload, and fail-closed cleanup
- [ ] Encrypted off-device recovery copy of the Android upload key retained
- [x] The mobile provider lifecycle gateway uses Google disconnect, Kakao
  forced login and unlink, and Apple authorization-code forwarding; repository
  tests cover call ordering, failure-time session preservation, and
  non-destructive logout
- [ ] Real Apple login, reauthentication, and disposable-account deletion E2E
- [x] Android neither offers nor invokes Apple sign-in while the required Apple
  Service ID web flow is absent; iOS also hides Apple sign-in until both
  protected artifact variables are true, while the production API independently
  defaults its Apple exchange gate to false until revocation configuration and
  deletion E2E are complete
- [ ] Real Kakao login, reauthentication, and disposable-account deletion E2E
- [ ] Google Play developer-account verification and internal-test release
- [x] App Store Connect sign-in and TestFlight build upload
- [x] TestFlight build 5 export compliance, Korean test instructions, beta
  description, support/privacy URLs, and internal-group assignment
- [x] App Store subtitle, Medical/Lifestyle categories, `16+` age questionnaire,
  and privacy-policy URL saved
- [ ] App Store version metadata and build 5 selection saved. The fields are
  prepared, but App Store Connect requires a valid App Review phone number.
- [ ] Free starting price and intended App Store countries or regions selected
- [ ] Current iPhone and iPad App Store screenshots captured from the release
  build. Build 5 supports both device families.
- [ ] App Store privacy questionnaire published after authentication-SDK and
  Railway processor-log review
- [ ] App Store content-rights, regulated-medical-device, export-classification,
  and EU DSA declarations completed by the account owner after legal review
- [ ] Disposable App Review account and valid review contact phone supplied
- [x] Public support email configured in product and store metadata

The internal TestFlight beta can continue while deferred catalog-refresh and
backup work remains last in the product sequence. Public promotion and paid
distribution remain blocked by the unchecked legal, provider, store-account,
metadata, and recovery gates.
