# Railway project configuration

This directory defines the persistent Railway production graph for
`medical-box`.

## Deployment boundary

- `medical-box` serves product and legal pages, account authentication,
  permission-gated catalog APIs, health checks, and app-link manifests.
- `Postgres` stores account/authentication data and the promoted public
  medicine catalog.
- Both resources run in Railway's Singapore region and communicate over
  Railway private networking.
- The public host is `medicalbox.outoftokens.ai`; there is no separate API or
  staging host.
- `.railway/railway.ts` is the sole Railway configuration model. Do not add a
  service-level `railway.json` that can override this graph.
- Railway's TypeScript IaC cannot register custom domains, so the production
  domain remains an explicitly verified dashboard and DNS-provider resource.
- Automated full-catalog refresh is disabled. The current catalog fits the
  5 GB production volume, but a full refresh can create unsafe transient WAL
  and bloat. Increase storage or implement bounded replacement transactions
  before reintroducing a scheduled ingestion service.

The former staging environment, staging databases, `catalog-sync` service,
staging custom domain, and staging access-key boundary were retired after the
validated catalog was promoted to production on 2026-07-27. Local tests and
GitHub Actions are the pre-production validation boundary.

## Required externally managed variables

The IaC definition uses `preserve()` for credentials, provider identifiers,
access-control inputs, and source URLs so an apply cannot replace an existing
value with an unresolved shared-variable reference.

| Variable | Requirement |
| --- | --- |
| `JWT_SECRET` | Production random secret of at least 32 characters |
| `CATALOG_ACCESS_EMAIL_ALLOWLIST` | Comma-separated verified beta emails that receive `catalog:read` at sign-in; empty means deny by default |
| `DATA_GO_KR_SERVICE_KEY` | Encoded public-data portal service key |
| `GOOGLE_CLIENT_ID` | Google OIDC client ID |
| `KAKAO_APP_ID` | Kakao REST/OpenID Connect app ID |
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `ANDROID_CERT_SHA256` | Production signing-certificate fingerprint |
| `MFDS_RECALL_URL` | Confirmed official recall/suspension API endpoint |
| `MFDS_SHORTAGE_URL` | Confirmed official supply-interruption API endpoint |
| `HIRA_PRICE_URL` | Confirmed official HIRA price endpoint |
| `HIRA_STANDARD_CODE_URL` | Confirmed official HIRA standard-code file endpoint |

Unresolved source URLs must not be guessed. Confirm the official resource and
redistribution terms before configuring or loading a source.

## Production change workflow

1. Run the complete local and CI validation suites.
2. Run `railway config plan --environment production`.
3. Review the plan for changes to `medical-box` and `Postgres` only.
4. Apply only after explicit approval of the exact plan.
5. Verify `/api/health/ready`, authentication boundaries, catalog metadata,
   search, detail, and DUR responses.
6. Verify automatic TLS, HSTS, host filtering, and app-link manifests.
7. Maintain recoverable database backups and exercise a disposable restore.

Grant or revoke an existing account by exact user ID from an API service shell:

```bash
medical-box-access grant 00000000-0000-0000-0000-000000000000
medical-box-access revoke 00000000-0000-0000-0000-000000000000
```

If an email remains in `CATALOG_ACCESS_EMAIL_ALLOWLIST`, a later provider
sign-in grants access again. Remove the email from the allowlist before
revoking that account.
