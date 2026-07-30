# Railway project configuration

This directory defines the persistent Railway production graph for
`medical-box`.

## Deployment boundary

- `medical-box` serves product and legal pages, account authentication,
  permission-gated catalog APIs, health checks, and app-link manifests.
- `Postgres` stores account/authentication data and the promoted public
  medicine catalog.
- `catalog-sync` remains a fail-closed production stub. Its declared start
  command is a no-op and it has no cron until the capacity reserve and isolated
  recurring-run canary both pass. Its only source watch is the intentionally
  absent `.railway/catalog-sync-activation` sentinel, so ordinary backend and
  IaC merges do not build the dormant function.
- Backup worker, encryption, retention, and restore code are retained as a
  future blueprint. The active Railway graph intentionally contains no backup
  service, bucket, or `Operations` group because those resources can incur cost.
- The API, PostgreSQL, and catalog stub are placed in Railway's Singapore
  region. Application services reach PostgreSQL over private networking.
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

The former staging environment, staging databases, staging `catalog-sync`
service, staging custom domain, and staging access-key boundary were retired
after the validated catalog was promoted to production on 2026-07-27. Local
tests and GitHub Actions are the pre-production validation boundary.

## Required externally managed variables

The active IaC definition uses `preserve()` for credentials, provider identifiers,
and access-control inputs so an apply cannot replace an existing value with an
unresolved shared-variable reference. Confirmed public-source endpoints remain
explicit literals.

| Variable | Requirement |
| --- | --- |
| `JWT_SECRET` | Production random secret of at least 32 characters |
| `SUPPORT_EMAIL` | Existing monitored address shown on support and external account-deletion pages; empty blocks external beta readiness |
| `TERMS_VERSION` | Version shown by the app and accepted by the API; release both sides together when terms change |
| `DATA_GO_KR_SERVICE_KEY` | Encoded public-data portal service key |
| `GOOGLE_CLIENT_ID` | Google OIDC client ID |
| `KAKAO_APP_ID` | Kakao REST/OpenID Connect app ID |
| `APPLE_SIGN_IN_ENABLED` | Server-side Apple exchange gate; keep unset or `false` until revocation configuration and deletion E2E are complete |
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `APPLE_SIGN_IN_KEY_ID` | Sign in with Apple private-key identifier used only for account revocation |
| `APPLE_SIGN_IN_PRIVATE_KEY_BASE64` | Base64-encoded Sign in with Apple `.p8` private key; store only as a secret |
| `ANDROID_CERT_SHA256` | Production signing-certificate fingerprint |
| `MFDS_RECALL_URL` | Confirmed official recall/suspension API endpoint |
| `MFDS_SHORTAGE_URL` | Confirmed official supply-interruption API endpoint |
| `HIRA_PRICE_URL` | Confirmed official HIRA price endpoint |
| `HIRA_STANDARD_CODE_URL` | Confirmed official HIRA standard-code file endpoint |
| `AWS_ENDPOINT_URL` | Future backup blueprint only: bucket endpoint |
| `AWS_ACCESS_KEY_ID` | Railway credentials for the production backup bucket |
| `AWS_SECRET_ACCESS_KEY` | Secret paired with the bucket access key |
| `AWS_S3_BUCKET_NAME` | Railway identifier for `production-backups` |
| `AWS_DEFAULT_REGION` | Exact region returned by Railway bucket credentials |
| `AWS_S3_ADDRESSING_STYLE` | Exact `urlStyle` returned by Railway (`auto`, `path`, or `virtual`) |
| `BACKUP_GPG_PUBLIC_KEY_BASE64` | Public encryption key only; never the private key |
| `BACKUP_GPG_RECIPIENT` | Full fingerprint of the approved backup recipient |
| `BACKUP_MANIFEST_HMAC_KEY_BASE64` | Random 256-bit manifest authentication key |

Unresolved source URLs must not be guessed. Confirm the official resource and
redistribution terms before configuring or loading a source.

## Production change workflow

1. Run the complete local and CI validation suites.
2. Verify the CLI link resolves to production and run `railway config plan`,
   then run the fail-closed no-cost plan guard. The guard verifies the exact
   catalog reserve and terms values as well as the service changes.
3. Reject any backup resource creation, catalog scheduling, deletion, database
   replacement, or unrelated update.
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

Registered accounts receive `catalog:read` by default. An explicit revoke
persists across later provider sign-ins until an operator grants access again.
