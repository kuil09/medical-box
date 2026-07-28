# Closed beta release checklist

Evidence date: 2026-07-28

## Automated gates

- [x] Product Design runtime integrity and production build
- [x] Flutter analyze, unit/widget/golden tests, Android build, and iOS no-codesign
  build
- [x] Ruff, MyPy, Pytest, Alembic upgrade, and OpenAPI drift check
- [x] Local inventory CRUD and encrypted export/import round trip
- [x] Provider token and refresh-token rotation/reuse tests
- [x] Account deletion fail-closed tests cover grant-provider linkage, Google
  and Kakao client revocation boundaries, and Apple authorization-code
  exchange, subject matching, and server-side token revocation
- [x] Catalog routes return `401` without a token, `403` without `catalog:read`,
  and `200` only after an explicit entitlement grant
- [x] Catalog pagination, retry, duplicate, schema, partial-failure, and count-drop
  tests

## Infrastructure gates

- [x] Railway production plan reports no unexpected deletes. The pending
  backup-resource creates remain unapplied until cost and legal approval.
- [x] API and PostgreSQL run in Railway Singapore
- [ ] Railway-native or approved off-device daily, weekly, and monthly backups
  enabled. The encrypted bucket worker, signed manifests, retention logic, and
  monthly disposable-restore workflow pass local validation; the Railway
  bucket and dedicated Singapore restore runner still require owner approval.
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
  fingerprint. The monitor now fails closed on `UNCONFIGURED` and empty lists.
- [ ] Approved-source recurring catalog mutation enabled. The `18:10 UTC`
  trigger currently executes a deliberate no-op until the capacity reserve and
  isolated recurring-run canary pass.
- [x] GitHub Actions manual production-monitor run `30276771772` and scheduled
  run `30281631480` passed the previous HTTP and header probes
- [ ] A production-monitor run passes the strengthened well-known metadata
  verifier after the provider identifiers are configured

## Product and privacy gates

- [x] Anonymous operation completes every device-local organizer workflow; official
  catalog lookup requires an approved authenticated account
- [x] Account deletion offers an explicit account-only or account-and-device-data
  choice after provider reauthentication
- [x] Local deletion leaves the optional account unless the user separately deletes
  it
- [x] Lock-screen notifications hide medicine names by default
- [x] Android local medicine and family/pouch CRUD completes while the matching
  production HTTP-log interval remains empty
- [ ] Full approved official catalog load and source attribution pass review.
  HIRA standard codes are loaded; recall, supply-interruption, and HIRA-price
  APIs still return HTTP 403 and remain disabled.
- [ ] Legal review approves medicine wording and Singapore cross-border processing
  disclosure

## Provider and distribution gates

- [x] Real Google production login, restored session, entitlement, official
  detail, appearance, and DUR flow
- [x] Android release signing is fail-closed; compile-only unsigned AAB and iOS
  release no-codesign builds pass locally with Flutter 3.44.7
- [x] Protected manual mobile-release workflow validates secrets, signs and
  verifies store artifacts, retains them for seven days, and cleans ephemeral
  signing material
- [x] GitHub `closed-beta` environment exists, permits only `main`, and rejects
  administrator bypass. Store promotion remains a separate account-authenticated
  action.
- [x] Android upload key is stored outside the repository with credentials in
  macOS Keychain, and its signing secrets plus both Google client IDs are
  installed in the protected environment
- [ ] The protected environment contains the expected Android upload-certificate
  SHA-256, Kakao native key, and all Apple distribution-signing inputs
- [x] Korean Play Store and App Store metadata source files are versioned
- [x] Pull request 10 full CI run `30319463102` and both CodeQL runs pass after
  the repository became public; the former private-repository billing gate no
  longer blocks validation
- [ ] Signed Android AAB produced by the protected release environment using the
  upload key and production provider identifiers
- [ ] Signed iOS IPA produced by the protected release environment using the
  distribution certificate, provisioning profile, and production provider
  identifiers
- [ ] Encrypted off-device recovery copy of the Android upload key retained
- [x] The mobile provider lifecycle gateway uses Google disconnect, Kakao
  forced login and unlink, and Apple authorization-code forwarding; repository
  tests cover call ordering, failure-time session preservation, and
  non-destructive logout
- [ ] Real Apple login, reauthentication, and disposable-account deletion E2E
- [x] Android neither offers nor invokes Apple sign-in while the required Apple
  Service ID web flow is absent; native iOS behavior remains enabled
- [ ] Real Kakao login, reauthentication, and disposable-account deletion E2E
- [ ] Google Play developer-account verification and internal-test release
- [ ] App Store Connect sign-in and TestFlight release
- [ ] Public support email configured in product and store metadata

External beta promotion is blocked until every infrastructure, provider,
catalog, backup-restore, privacy, and legal gate has evidence.
