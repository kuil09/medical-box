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
  │  └─ Optional account tokens
  ├─ Local notifications
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
  ├─ Catalog synchronization cron
  └─ PostgreSQL
     ├─ Account and authentication tables
     ├─ Raw catalog records and run checkpoints
     └─ Normalized public catalog tables
```

No household or inventory synchronization API exists. This makes accidental
server persistence structurally harder: mobile-local entities are not present
in the backend schema or OpenAPI contract.

## Public host routing

Production uses one host:

- `/`, `/privacy`, `/terms`, `/support`, `/account-deletion`
- `/api/v1/...`
- `/api/health/...`
- `/.well-known/...`

Staging uses `staging.medicalbox.outoftokens.ai` and requires an additional
header for non-health API routes. Issuer, audience, signing key, PostgreSQL
environment, and domain are different from production.
