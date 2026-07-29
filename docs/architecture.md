# Architecture

## Runtime boundaries

```text
Flutter device
  ├─ Encrypted Drift / SQLite3MultipleCiphers
  │  ├─ Household and member profiles
  │  ├─ Containers and inventory
  │  ├─ Visit and renewal readiness
  │  ├─ Reminders
  │  └─ App settings
  ├─ Keychain / Android Keystore
  │  ├─ 256-bit database key
  │  └─ Required account tokens
  ├─ Local notifications
  ├─ Provider-isolated banner adapter (disabled by default)
  └─ Explicit network calls
     ├─ Account authentication
     └─ Permission-gated medicine catalog lookup

medicalbox.outoftokens.ai
  └─ Railway API service
     ├─ Product and legal web pages
     ├─ Auth and account endpoints
     ├─ `catalog:read` protected catalog endpoints
     ├─ Health endpoints
     └─ App / Universal Link manifests

Railway private network
  ├─ API service
  └─ PostgreSQL
     ├─ Account and authentication tables
     ├─ Raw catalog records and run checkpoints
     └─ Normalized public catalog tables
```

No household or inventory synchronization API exists. This makes accidental
server persistence structurally harder: mobile-local entities are not present
in the backend schema or OpenAPI contract.

The app starts at an authentication gate. Incomplete onboarding routes to the
onboarding flow; completed onboarding without a restored account routes to
sign-in; only an authenticated account can enter organizer routes. Signing out
locks, but does not erase, the encrypted local database.

Advertising is isolated behind an adapter whose public input is only an
allowlisted placement enum. The default adapter performs no network request and
the build-time advertising flag defaults to false. Store receipt verification,
purchase restoration, and Family Plus sync are not implemented.

## Public host routing

Production uses one host:

- `/`, `/privacy`, `/terms`, `/support`, `/account-deletion`
- `/api/v1/...`
- `/api/health/...`
- `/.well-known/...`

The deployed system has no persistent staging environment. Local tests and
GitHub Actions provide pre-production validation without a second database or
public host.
