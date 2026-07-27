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

## Prepared off-device backup implementation

Evidence date: 2026-07-28

The repository now contains a production backup worker and a separate restore
verification workflow. The implementation has been locally validated but is
not yet active in Railway because creating the bucket is a billable
infrastructure change.

- `.railway/railway.ts` declares a Singapore `production-backups` bucket and a
  `production-backup` cron function scheduled for `20:30 UTC` (`05:30 KST`).
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
- An encrypted object is deleted if its manifest cannot be published. Retention
  only removes backup pairs whose manifests have a valid HMAC.
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

## Local end-to-end restore evidence

`services/backend/scripts/test_backup_roundtrip.sh` completed successfully on
2026-07-28:

1. migrated an isolated PostgreSQL 18 source through Alembic revision
   `20260726_0004`;
2. inserted a source registry row and a medicine product;
3. proved that an active catalog advisory lock rejects a concurrent backup;
4. generated an ephemeral OpenPGP key;
5. created an encrypted custom-format backup and signed manifest;
6. verified both ciphertext and plaintext SHA-256 values and archive structure;
7. restored into a different empty PostgreSQL 18 instance; and
8. confirmed the medicine row and all manifest table counts.

The run returned `archive_listed=true`, `restored=true`, and
`restored_product_count=1`. Its containers, network, plaintext archive, and
ephemeral keys were removed by the test cleanup trap.

Activation remains gated on explicit approval for the Railway bucket and the
dedicated Singapore restore runner. After approval, the required evidence is:

1. applied bucket and worker configuration with secret values never printed;
2. one successful production backup with object size, ciphertext SHA-256, and
   signed manifest key recorded;
3. one successful protected monthly restore workflow; and
4. a bucket object-count and retention audit after the next scheduled run.

The read-only Railway configuration plan on 2026-07-28 targeted project
`medical-box`, environment `production`, and reported exactly three safe
creates: group `Operations`, service `production-backup`, and bucket
`production-backups`. It reported no updates and no deletion operations. The
plan was not applied.
