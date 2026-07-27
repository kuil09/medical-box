# Railway project configuration

This directory describes the complete `medical-box` Railway project. The same
graph is rendered separately for the `staging` and `production` environments.

## Deployment boundary

- `medical-box` is the production API service and serves product pages, legal
  pages, account authentication, the
  permission-gated catalog API, health checks, and both app-link manifests.
- `catalog-sync` runs at `18:10 UTC` every day and exits when all configured
  official-source synchronizations finish.
- The code services deploy from the `kuil09/medical-box` GitHub source with
  `services/backend` as their root directory.
- `.railway/railway.ts` is the sole Railway configuration model; a service-level
  `railway.json` must not be reintroduced because it would override cron
  settings during local uploads.
- Production uses `Postgres`; staging uses `Postgres-staging-v2`. The stopped
  `Postgres-staging` service retains the failed first-import volume for
  recovery evidence and must not be reattached to the API.
- PostgreSQL stores only account/authentication data and the public catalog.
- All compute and PostgreSQL resources are placed in Railway's Singapore region.
- The custom domain belongs to `medical-box`. No separate API subdomain is
  declared.
- Railway's beta TypeScript IaC cannot register custom domains, so domain
  attachment remains an approval-gated dashboard operation.

## Required externally managed variables

Create distinct service-variable values in each Railway environment before
applying the plan. The IaC definition uses `preserve()` for credentials,
provider identifiers, access-control inputs, and source URLs so an apply cannot
replace an existing value with an unresolved shared-variable reference.

| Variable | Requirement |
| --- | --- |
| `JWT_SECRET` | Random secret of at least 32 characters; never reuse across environments |
| `CATALOG_ACCESS_EMAIL_ALLOWLIST` | Comma-separated verified beta emails that receive `catalog:read` at sign-in; empty means deny by default |
| `DATA_GO_KR_SERVICE_KEY` | Encoded public-data portal service key |
| `GOOGLE_CLIENT_ID` | Google OIDC client ID |
| `KAKAO_APP_ID` | Kakao REST/OpenID Connect app ID |
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `ANDROID_CERT_SHA256` | Production or internal signing certificate fingerprint |
| `MFDS_RECALL_URL` | Confirmed official recall/suspension API endpoint |
| `MFDS_SHORTAGE_URL` | Confirmed official supply-interruption API endpoint |
| `HIRA_PRICE_URL` | Confirmed official HIRA price endpoint |
| `HIRA_STANDARD_CODE_URL` | Confirmed official HIRA standard-code file endpoint |
| `STAGING_ACCESS_KEY` | Staging only; random key injected into CI/internal builds |

The unresolved source URLs are intentionally not guessed. Confirm the current
official public-data resource and redistribution terms before setting them.

## Approval-gated rollout

1. Create the `medical-box` Railway project with `staging` and `production`.
2. Link this repository and select one environment.
3. Run `npm ci` at the repository root to install the pinned Railway IaC SDK.
4. Add the required environment-specific service variables.
5. Run `railway config plan` and review the exact resource changes.
6. Apply only after explicit approval of that plan.
7. Have the Railway account owner install `pg_trgm` once in each database with
   the approved extension-management workflow.
8. Configure Railway daily/weekly/monthly backups and perform a staging restore.
9. Add the Railway-provided CNAME targets at the DNS provider for
   `medicalbox.outoftokens.ai` and `staging.medicalbox.outoftokens.ai`.
10. Verify automatic TLS, health checks, HSTS, host filtering, and both app-link
   manifests before distributing an internal build.

Grant or revoke an existing account by exact user ID from an API service shell:

```bash
medical-box-access grant 00000000-0000-0000-0000-000000000000
medical-box-access revoke 00000000-0000-0000-0000-000000000000
```

If an email remains in `CATALOG_ACCESS_EMAIL_ALLOWLIST`, a later provider
sign-in grants access again. Remove the email from the allowlist before
revoking that account.

The staging IaC graph was applied after explicit approval on 2026-07-27,
including migration of `Postgres-staging-v2` to Singapore. Production apply and
all DNS-provider changes remain outside automated setup.
