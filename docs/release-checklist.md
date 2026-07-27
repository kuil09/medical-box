# Closed beta release checklist

Evidence date: 2026-07-27

## Automated gates

- [x] Product Design runtime integrity and production build
- [x] Flutter analyze, unit/widget/golden tests, Android build, and iOS no-codesign
  build
- [x] Ruff, MyPy, Pytest, Alembic upgrade, and OpenAPI drift check
- [x] Local inventory CRUD and encrypted export/import round trip
- [x] Provider token and refresh-token rotation/reuse tests
- [x] Catalog routes return `401` without a token, `403` without `catalog:read`,
  and `200` only after an explicit entitlement grant
- [x] Catalog pagination, retry, duplicate, schema, partial-failure, and count-drop
  tests

## Infrastructure gates

- [x] Railway production plan reports no drift and no unexpected deletes
- [x] API and PostgreSQL run in Railway Singapore
- [ ] Railway-native or approved off-device daily, weekly, and monthly backups
  enabled. Railway-native backups require a Pro-plan upgrade; no upgrade or
  alternative destination has been authorized.
- [x] Disposable production-backup restore performed and documented within the
  current month
- [x] `pg_trgm` activated once in production
- [x] DNS CNAME, automatic TLS, HSTS, allowed-host filtering, web/legal/API/health,
  and both `/.well-known` paths verified
- [x] Approved-source catalog cron deployed for `18:10 UTC` daily
- [ ] At least one GitHub Actions scheduled production-monitor run passes.
  Manual run `30276771772` passed; the scheduler has not emitted a run yet.

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
- [ ] Real Apple login, reauthentication, and disposable-account deletion E2E
- [ ] Real Kakao login, reauthentication, and disposable-account deletion E2E
- [ ] Google Play developer-account verification and internal-test release
- [ ] App Store Connect sign-in and TestFlight release
- [ ] Public support email configured in product and store metadata

External beta promotion is blocked until every infrastructure, provider,
catalog, backup-restore, privacy, and legal gate has evidence.
