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
