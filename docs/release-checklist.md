# Closed beta release checklist

## Automated gates

- Product Design runtime integrity and production build
- Flutter analyze, unit/widget/golden tests, Android build, and iOS no-codesign
  build
- Ruff, MyPy, Pytest, Alembic upgrade, and OpenAPI drift check
- Local inventory CRUD and encrypted export/import round trip
- Provider token and refresh-token rotation/reuse tests
- Catalog routes return `401` without a token, `403` without `catalog:read`,
  and `200` only after an explicit entitlement grant
- Catalog pagination, retry, duplicate, schema, partial-failure, and count-drop
  tests

## Infrastructure gates

- Railway plan reviewed for staging and production with no unexpected deletes
- API, catalog cron, and PostgreSQL isolated by environment in Singapore
- Distinct issuer, audience, signing key, staging access key, and database
- Daily, weekly, and monthly backups enabled
- Staging restore performed and documented within the current month
- `pg_trgm` activated once per database
- DNS CNAME, automatic TLS, HSTS, allowed-host filtering, web/legal/API/health,
  and both `/.well-known` paths verified

## Product and privacy gates

- Anonymous operation completes every device-local organizer workflow; official
  catalog lookup requires an approved authenticated account
- Account deletion offers an explicit account-only or account-and-device-data
  choice after provider reauthentication
- Local deletion leaves the optional account unless the user separately deletes
  it
- Lock-screen notifications hide medicine names by default
- Proxy capture proves that family names, inventory, notes, visit dates, and
  reminder text are not transmitted
- Full official catalog load and source attribution pass review
- Legal review approves medicine wording and Singapore cross-border processing
  disclosure

External beta promotion is blocked until every infrastructure, provider,
catalog, backup-restore, privacy, and legal gate has evidence.
