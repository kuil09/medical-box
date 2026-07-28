# Production backup and restore evidence

Evidence date: 2026-07-27

## Railway backup capability

The production PostgreSQL service Backups page reported:

- no existing volume backups;
- Railway Backups and point-in-time recovery are available only on the Pro
  plan; and
- the current workspace is not entitled to configure those features.

Changing the workspace plan is a billable account decision and was not performed
automatically.

## Logical backup

A PostgreSQL 18.4 custom-format dump was created from the production public
database endpoint with owner and privilege statements excluded. The database
connection string was injected directly from Railway and was never printed.

| Artifact | Value |
| --- | --- |
| Plain dump size | 725.5 MiB |
| Plain dump SHA-256 | `345e4c94a98ba7285bcc777a58c1e4c753475be9aadbb5025e26888fbedbc29c` |
| Encrypted local artifact | `.backups/medical-box-production-2026-07-27.dump.gpg` |
| Encrypted artifact size | 720.8 MiB |
| Encrypted artifact SHA-256 | `0f6c53da5a81e23486aa8a5ee6fd3090ab3f166302a58edd791703efdd275720` |
| GPG recipient fingerprint | `2E278F2C548AE53D9D19719D361D7F7D153CF746` |

The `.backups` directory is ignored by Git. The plain dump was deleted after
restore verification. The encrypted artifact is a local recovery copy, not an
off-device backup.

## Disposable restore

The plain dump was restored with `pg_restore --exit-on-error --jobs=4` into a
new PostgreSQL 18 container that had no network or storage relationship with the
production service. The restored database returned:

| Verification | Result |
| --- | ---: |
| Alembic version | `20260726_0004` |
| Products | 78,090 |
| Ingredients | 89,697 |
| Consumer information | 4,739 |
| Identification representatives | 25,346 |
| Identification variants | 25,363 |
| DUR rules | 860,199 |
| Source records | 1,102,783 |
| Users | 1 |
| Auth identities | 1 |
| Invalid indexes | 0 |
| Unvalidated constraints | 0 |

The counts match the production promotion baseline. The disposable container and
plain dump were deleted after verification.

## Remaining infrastructure gate

The restore test and a recoverable encrypted snapshot exist, but scheduled
Daily, Weekly, Monthly, and PITR protection remain unavailable until either:

1. the Railway workspace is explicitly upgraded to Pro and the schedules are
   enabled in the database service; or
2. an approved encrypted off-device backup destination and retention policy are
   configured.

The closed beta must not treat the local encrypted artifact as equivalent to
scheduled off-device backups.

## Cost boundary

Evidence date: 2026-07-28

Railway currently prices service network egress at USD 0.05/GB and bucket
storage at USD 0.015/GB-month. Bucket egress and S3 API operations are free,
while backup-worker compute remains usage-billed by the minute:

- https://docs.railway.com/pricing
- https://docs.railway.com/storage-buckets/billing

Using the measured 720.8 MiB encrypted snapshot as a conservative steady-size
estimate, one daily upload is about 0.756 GB. Thirty uploads are therefore
about USD 1.13/month in service egress. The 7 daily, 4 weekly, and 12 monthly
union has an upper bound of 23 distinct objects, or about 17.4 GB; after
Railway's GB-month rounding, its upper-bound storage charge is about
USD 0.27/month. The combined steady network-and-storage estimate is therefore
about USD 1.40/month plus worker compute. Actual retained points overlap and
the first year ramps up, so actual storage should be lower. Existing workspace
usage may still cause the total bill to exceed the Hobby plan's included usage.

The fail-closed first apply creates an empty bucket and a no-op worker. It does
not begin those recurring charges. The first manual backup incurs roughly
USD 0.04 of upload egress at the measured size. The remote read-after-write
verification uses free bucket egress; only its short-lived worker compute is
additional.

## Prepared off-device backup implementation

Evidence date: 2026-07-28

The repository now contains a production backup worker and a separate restore
verification workflow. The implementation has been locally validated but is
not yet active in Railway because creating the bucket is a billable
infrastructure change.

- `.railway/railway.ts` declares a Singapore `production-backups` bucket and a
  fail-closed `production-backup` worker. Its start command is a no-op and it
  has no cron until the first backup and disposable restore both succeed.
- `services/backend/Dockerfile.backup` pins PostgreSQL client 18 and GnuPG in a
  runtime separate from the public API image.
- `medical-box-backup create` holds a PostgreSQL advisory lock across snapshot,
  encryption, upload, signed-manifest publication, and retention pruning.
- Catalog mutation commands and the backup worker share a second advisory lock,
  so a backup refuses to start while a catalog refresh is active and a refresh
  refuses to start while a backup is active.
- Each dump uses an exported repeatable-read snapshot, custom archive format,
  zstd compression, OpenPGP public-key encryption, and an HMAC-SHA256 signed
  manifest containing both plaintext and encrypted hashes plus all table
  counts.
- Backup creation fails closed if the production public-table inventory differs
  from the declared schema, preventing a future migration from silently
  omitting a table from restore verification.
- Before publishing a manifest, the worker downloads the uploaded ciphertext
  and verifies its size and SHA-256. The object is deleted if that check or
  manifest publication fails. Retention accepts a pair only when its HMAC,
  object size, and recorded ciphertext SHA-256 match, and removes expired
  unpaired ciphertext after a six-hour safety window.
- Retention is the union of the newest 7 daily, 4 weekly, and 12 monthly
  restore points.
- `.github/workflows/production-backup-restore.yml` is prepared to decrypt the
  newest object into a disposable PostgreSQL 18 service every month and verify
  the Alembic revision and every backed-up table count.

The private decryption key is intentionally excluded from Railway. The backup
worker receives only the public key. The private key and bucket read
credentials are reserved for the protected GitHub `backup-restore`
environment. The workflow requires a dedicated ephemeral self-hosted runner
with the labels `medical-box-backup` and `singapore`; it does not permit
production plaintext on a GitHub-hosted runner. Runner provisioning is a
separate billable and legal-review gate.

The `backup-restore` environment must be protected before any restore secret is
added:

- require an independent reviewer for every deployment and disable self-review;
- restrict deployment branches and tags to the protected `main` branch only;
- keep the seven restore values as environment secrets, never repository or
  organization secrets, and keep the two non-secret bucket routing values as
  environment variables; and
- allow the monthly schedule or a manual dispatch only from the workflow
  revision present on `main`.

The self-hosted Singapore runner must be registered ephemerally for one restore
job, have no other repository or workload assigned, and be destroyed and
deregistered after the job. Its disposable disk must be encrypted, and its
network policy must be limited to the services needed to obtain the workflow,
container dependencies, and backup object. A persistent shared runner does not
satisfy this boundary.

## Local end-to-end restore evidence

`services/backend/scripts/test_backup_roundtrip.sh` completed successfully on
2026-07-28:

1. migrated an isolated PostgreSQL 18 source through Alembic revision
   `20260728_0005`;
2. inserted a source registry row and a medicine product;
3. proved that an active catalog advisory lock rejects a concurrent backup;
4. generated an ephemeral OpenPGP key;
5. created an encrypted custom-format backup and signed manifest;
6. verified both ciphertext and plaintext SHA-256 values and archive structure;
7. restored into a different empty PostgreSQL 18 instance; and
8. confirmed the medicine row and all manifest table counts.

The run returned `archive_listed=true`, `restored=true`, and
`restored_product_count=1`. Its containers, network, plaintext archive, and
ephemeral keys were removed and their absence was verified. The final output
included `cleanup_verified=true`.

Activation remains gated on explicit approval for the Railway bucket and the
dedicated Singapore restore runner. After approval, the required evidence is:

1. applied the bucket and fail-closed worker configuration with secret values
   never printed;
2. one successful production backup with object size, ciphertext SHA-256, and
   signed manifest key recorded;
3. one successful protected monthly restore workflow;
4. a separately approved cron-only activation; and
5. a bucket object-count and retention audit after the next scheduled run.

The read-only Railway configuration plan on 2026-07-28 targeted project
`medical-box`, environment `production`, and reported exactly five safe
changes: the 1.2 GB catalog reserve variable for the API and dormant catalog
worker, plus creation of group `Operations`, service `production-backup`, and
bucket `production-backups`. It reported no deletion operation. Both catalog
and backup desired start commands were verified as no-ops, and the backup
worker had no cron. The plan was not applied.

## Activation runbook

Do not execute this section until PR #11 is merged, hosted CI is green, the
Railway cost is approved, and the legal reviewer accepts the backup processing
boundary.

Create a dedicated key outside the repository:

```bash
services/backend/scripts/prepare_backup_key_material.sh \
  /Users/operator/.private_keys/medical-box/production-backup-v1
```

The command creates a five-year Ed25519 certification key with a CV25519
encryption subkey, a random passphrase, and a 256-bit manifest HMAC key. It
refuses an existing directory and any path inside the Git repository. Copy the
result to an approved offline recovery location before continuing. Maintain a
second, independently stored offline copy of the complete directory, verify
that both copies contain the same recipient fingerprint, and document their
custodians. Do not wire restore secrets while the local directory is the only
recoverable private-key copy.

The production key material was generated locally on 2026-07-28 at
`$HOME/.private_keys/medical-box/production-backup-v1`. Its public
recipient fingerprint is
`9B2FDA74DC458A383A26E1C5F0DB735FD546BE97`. All five files are mode `0600`;
the manifest key is exactly 32 bytes, and the private key and passphrase are
non-empty. The directory has not yet been copied to an approved offline
recovery location and must not be treated as the sole recovery copy.

Configure the GitHub `backup-restore` environment and provision the
single-job ephemeral Singapore runner, but do not add any secret yet. The
environment must require an independent reviewer with self-review disabled and
must permit exactly the custom `main` deployment branch. The runner remains
unassigned until a protected restore is deliberately dispatched.

Run the read-only Railway guard from a CLI link that resolves to the production
environment:

```bash
services/backend/scripts/check_backup_railway_plan.sh
```

The guard never applies configuration or requests decrypted values. It rejects
diagnostics, deletions, destructive changes, and every change except exactly
these five: the two `CATALOG_MIN_FREE_BYTES` variable updates, `Operations`,
`production-backup`, and `production-backups`. It also requires the catalog to
remain at its exact no-op command and the backup worker to remain at its exact
no-op command with no cron.

Record an explicit approval of that exact plan before continuing. A different
plan, a rerun with an altered plan, or a request to activate either scheduled
command requires a new review and approval. After the approved guard output is
saved, apply interactively; do not use unattended confirmation flags:

```bash
railway config apply
```

After Railway creates the bucket and the paused worker, wire the worker's
public-key-only credentials through standard input. This never sends the
private decryption key to Railway:

```bash
services/backend/scripts/wire_backup_secrets.sh \
  /Users/operator/.private_keys/medical-box/production-backup-v1
```

Only after the GitHub environment protections are in place, set exactly seven
restore environment secrets and two non-secret environment variables from the
Railway bucket credentials and local private recovery material:

```bash
services/backend/scripts/wire_backup_restore_secrets.sh \
  /Users/operator/.private_keys/medical-box/production-backup-v1
```

Before its first secret mutation, the script verifies all local and Railway
inputs, resolves the repository as exactly `kuil09/medical-box`, and checks the
GitHub environment for a required reviewer, `prevent_self_review`, and the
exact custom `main` deployment-branch policy. Every mutation names that
repository explicitly. Secret values are passed to
`gh secret set --env backup-restore --repo kuil09/medical-box` through standard
input, are not printed, and are not written into the repository. It configures
the seven secrets `AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `AWS_S3_BUCKET_NAME`,
`BACKUP_GPG_PRIVATE_KEY_BASE64`, `BACKUP_GPG_PASSPHRASE`, and
`BACKUP_MANIFEST_HMAC_KEY_BASE64`, plus the two non-secret environment
variables `AWS_DEFAULT_REGION` and `AWS_S3_ADDRESSING_STYLE`. The variables
are passed through standard input to
`gh variable set --env backup-restore --repo kuil09/medical-box`; they carry
only the Railway bucket's region and URL addressing style. The backup worker
public key is intentionally excluded.

After the backup runtime has built successfully, run the first backup from the
same pinned container locally while Railway injects the production service
variables without printing them:

```bash
railway run \
  --service production-backup \
  --environment production \
  -- \
  services/backend/scripts/run_production_backup_container.sh
```

Verify the newest signed object by restoring it into a disposable PostgreSQL 18
container. This command substitutes a non-secret placeholder for the production
database URL because restore verification does not connect to the source:

```bash
railway run \
  --service production-backup \
  --environment production \
  -- \
  services/backend/scripts/verify_production_backup_restore.sh \
  /Users/operator/.private_keys/medical-box/production-backup-v1
```

Record only the backup ID, manifest key, encrypted size, encrypted SHA-256,
restored Alembic revision, and table counts. Do not record credentials, key
material, database URLs, or decrypted contents. If any step fails, preserve the
existing local encrypted recovery snapshot and bucket objects, do not prune or
delete resources, and fix the failing boundary before enabling the cron.

After the manual backup and disposable restore both succeed, make a separate
cron-activation pull request. Its Railway plan must be reviewed and explicitly
approved before it is applied. That pull request may make only these two backup
worker changes:

```ts
start: "uv run --no-sync medical-box-backup create",
deploy: {
  cronSchedule: "30 20 * * *",
  restartPolicyType: "NEVER",
},
```

Do not combine this cron activation with bucket creation, worker credential
wiring, restore-secret changes, catalog activation, or unrelated infrastructure
updates.
