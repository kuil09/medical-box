# Korean medicine catalog runbook

## In-scope official sources

The registry covers:

1. MFDS product authorization and detail data
2. MFDS consumer-friendly medicine information
3. MFDS pill identification data
4. DUR safety rules
5. Recall and sales-suspension events
6. Production, import, and supply interruption events
7. HIRA price criteria
8. HIRA medicine standard-code files

Patent, clinical-trial, industry-statistics, and production-value analysis data
are intentionally excluded.

## Synchronization invariants

- `itemSeq` is the primary product integration key.
- Every raw payload and canonical SHA-256 content hash is retained.
- All pages are fetched before old records are marked inactive.
- Count collapse, page failure, or schema failure rolls back normalized changes
  for that source and leaves the last successful catalog active.
- PostgreSQL advisory locks prevent overlapping runs for the same source.
- Unchanged record hashes skip normalization writes.
- DUR API queries only expose records whose owning sync run has succeeded.
  Initial DUR bootstraps may commit bounded inactive batches without exposing a
  partial snapshot.
- Recurring DUR runs prefetch raw records once per page and do not rewrite
  unchanged records. This prevents a large unchanged source from generating a
  full-table WAL burst.
- Recurring non-DUR runs also leave unchanged `source_records` untouched.
  Returning and stale records are updated in bounded batches, avoiding a
  full-source `last_seen_run_id` rewrite on every refresh.
- Production synchronization measures PostgreSQL database plus WAL bytes before
  acquisition and after every page. It aborts before the configured
  `CATALOG_MIN_FREE_BYTES` reserve is crossed.
- HIRA standard-code downloads accept CSV, XLSX, or ZIP containers, detect
  Korean header rows, stream CSV rows in 500-record pages, and are capped at
  250 MiB per file.
- A standard-code file whose SHA-256 matches its checkpoint is recorded as
  skipped and does not update source rows or normalized codes.
- The first standard-code load commits bounded run-gated batches. A failed run
  cannot become a successful source snapshot, its checkpoint hash is not
  published, and a retry can reuse quarantined rows without exposing partial
  products through search.
- Code, price, status, and DUR records never create placeholder products.
  Product search is populated only by product, ingredient, consumer, and
  identification sources.
- Product ingredients are normalized from structured ingredient fields when
  available and conservatively split from known flat MFDS ingredient fields.
- DUR product and ingredient operations are synchronized as 16 independent
  source streams. Variant identity includes the canonical payload hash because
  upstream natural identifiers are not unique across all rule variants.
- Byte-identical duplicate DUR rows count toward the official response total
  but are stored once. Semantically different variants remain separate.
- Stale DUR rules are derived from the complete set of keys observed in the
  successful run and deleted in bounded primary-key batches, so cleanup is not
  bounded by a database parameter limit.
- Pill image URLs may be referenced, but binaries must not be copied to owned
  storage until redistribution rights are confirmed.
- HIRA attribution and applicable Korea Open Government License text must stay
  attached to displayed source metadata.

## Required pre-production evidence

- Confirm every official endpoint and service identifier in the public-data
  portal on the deployment date.
- Record source-specific redistribution and attribution terms.
- Run full pagination and compare total, duplicate, missing-field, and hash
  counts.
- Exercise retry, page omission, duplicate, schema-change, partial-failure, and
  count-collapse fixtures.
- Verify that a failed run does not change the public catalog response.

## Local acquisition snapshot

The following measurements were recorded on 2026-07-26 after the MFDS
pharmaceutical product authorization and e약은요 development applications became
active:

| Dataset | Active raw records |
| --- | ---: |
| Product authorization list | 42,957 |
| Product authorization detail | 42,957 |
| Product ingredient detail | 126,622 |
| e약은요 consumer information | 4,757 |
| Total | 217,293 |

Normalization produced 42,957 current products, 89,758 structured ingredient
rows, 4,740 consumer-information rows, and 21,769 current products with an
official image URL. Of the consumer rows, 4,731 include efficacy information,
4,735 include a use method, 1,124 include a warning, 4,729 include precautions,
3,292 include interactions, 4,508 include side effects, and 4,728 include
storage guidance. The ingredient source also referenced 31,571 historical
product codes that were not present in the current authorization list; these
are retained as placeholder products instead of being silently dropped.

The e약은요 source returned 4,740 unique `itemSeq` values. Fourteen products had
multiple records, producing 17 additional variants. A full-payload comparison
showed that the variants differed only by `itemImage`, so raw identity uses
`itemSeq` plus `itemImage` while normalized consumer information remains one row
per `itemSeq`.

Before DUR acquisition, the SQLite verification catalog occupied 3,469,942,784
bytes. After the complete DUR snapshot was committed, it occupied
10,541,842,432 bytes. Raw detail payloads account for almost all of that size
because product, consumer, and DUR sources embed large efficacy, dosage,
warning, precaution, and prohibition documents. Product count is moderate, but
raw-payload retention is not storage-neutral. Production capacity planning must
therefore use measured payload size rather than product count.

The latest HIRA standard-code file published at this checkpoint is the
2025-10 CSV. Its original 54,880,067-byte download contains 305,522 data rows
and has SHA-256
`8f177ced6a93fefa439535125aeb4f626e9d386fa5700271094ca26bdcb50ff0`.
The portal permits the original file to be downloaded without login. The
production job uses that file and records its download hash.

At the same checkpoint, e약은요 was approved, its gateway access had propagated,
and the full 4,757-record run succeeded. Supply interruption and HIRA price
criteria still require separate approved applications.

Both MFDS DUR applications were approved and their gateway access propagated on
2026-07-26. The product service exposes nine operations and the ingredient
service exposes seven operations. A complete run produced the following
evidence:

| DUR measurement | Count |
| --- | ---: |
| Registered source streams | 16 |
| Official response rows | 863,771 |
| Active unique raw records | 863,599 |
| Normalized current rules | 863,599 |
| Byte-identical duplicate rows | 172 |
| Normalization gap | 0 |
| Rules with `itemSeq` | 858,749 |
| Ingredient-level rules without `itemSeq` | 4,850 |

The product-level concomitant-contraindication operation is the dominant source
with 798,400 official rows across 1,597 pages. Its successful local SQLite run
took 1 hour 23 minutes 25 seconds. The first attempt fetched all rows but rolled
back safely when cleanup tried to bind the complete key set in one `NOT IN`
clause and exceeded SQLite's parameter limit. The corrected cleanup uses a
correlated active-record existence check; the retry committed successfully.

SQLite is suitable as local verification evidence, but the measured duration
and 10.54 GB file size make row-by-row ORM upserts inappropriate for the Railway
production job. The PostgreSQL implementation must use page-sized bulk upserts,
use a successful-run visibility gate for bounded initial DUR commits, and
preserve the same active-snapshot and rollback invariants.

The pill-identification development application was approved on 2026-07-26.
Its current official endpoint is
`MdcinGrnIdntfcInfoService03/getMdcinGrnIdntfcInfoList03`, as documented in the
2025-11-10 service-change notice. The initial HTTPS probes consistently returned
HTTP 500 with a plain-text `Unexpected errors` response for decoded and encoded
key forms and for both JSON and XML. Rechecking the notice revealed that the
provider explicitly publishes an HTTP base URL. The same approved key and
request returned HTTP 200 and `NORMAL SERVICE` over HTTP.

The corrected HTTP endpoint was acquired successfully:

| Pill-identification measurement | Count |
| --- | ---: |
| Official and active raw rows | 25,349 |
| Normalized identification variants | 25,349 |
| Products with identification data | 25,332 |
| Products with multiple variants | 10 |
| Additional variants beyond one per product | 17 |
| Maximum variants for one product | 7 |
| Variants with an official image URL | 25,349 |
| Variants with shape data | 25,349 |
| Variants with color data | 25,348 |
| Variants with a front imprint | 25,039 |
| Variants with a back imprint | 12,512 |

The raw identity uses `itemSeq`, image URL, and the canonical payload hash.
This prevents distinct colors, strengths, dimensions, imprints, or images under
one authorization product from overwriting each other. The legacy singular
identification row is rebuilt deterministically from the latest source
timestamps as a compatibility representative, while every current variant is
retained separately.

The provider's HTTP-only route means the public-data service key is not protected
by transport encryption. Calls must remain in the backend catalog-sync job,
credentials must never be shipped to Flutter or logged, and the key should be
least-privileged and rotated after suspected exposure. Production release should
track an MFDS/data.go.kr request for a functioning HTTPS route; the HTTP route is
an explicit upstream security exception, not a general allowance for plaintext
API traffic.

## Historical Railway acquisition snapshot

The replacement staging database completed its first compact PostgreSQL import
on 2026-07-27. This snapshot is independent of the earlier local SQLite
measurements above. The staging resources were temporary acquisition
infrastructure and are no longer part of the deployed architecture.

| Staging measurement | Count |
| --- | ---: |
| Products | 78,090 |
| Product ingredients | 89,697 |
| Consumer-information rows | 4,739 |
| Identification variants | 25,346 |
| DUR official response rows | 860,371 |
| DUR unique raw records and normalized rules | 860,199 |
| DUR byte-identical duplicate rows | 172 |

The product-level concomitant source returned exactly 795,000 unique rows over
1,590 pages. Its first activation attempt updated all raw `active` flags in one
statement, generated an approximately 890 MiB WAL burst, filled the 5 GB
volume, and caused PostgreSQL crash recovery. Every page batch remained
preserved and inactive. Recovery verified 795,000 raw records, 795,000 rules,
one owning run, and checkpoint page 1,590 before finalizing the owning run.

The catalog now uses successful `sync_runs` as the atomic DUR visibility gate,
so finalization updates one run row instead of every raw record. PostgreSQL
`max_wal_size` is set to 256 MiB for this constrained staging volume. A normal
`VACUUM (ANALYZE)` reclaimed the rolled-back row versions; the final filesystem
measurement was 3,607 MiB used and 992 MiB available on the 4,615 MiB usable
filesystem.

The temporary API and catalog-sync services used the replacement database.
Their database password, JWT secret, and staging access key were rotated after
deployment verification. The public-data service key must be reissued in the
data.go.kr portal after its terminal exposure.

The replacement database and its 3.88 GB Railway volume were migrated from the
temporary US West placement to `asia-southeast1-eqsg3a` on 2026-07-27. The
post-migration deployment returned `SUCCESS`, the volume returned `READY`, and
the API container reported HTTP 200 for `/api/health/ready`. Read-only
validation reproduced 78,090 products, 860,199 DUR rules, the 256 MiB
`max_wal_size`, and no running sync jobs. Anonymous catalog probes returned 404
without the former staging key and 401 without user authentication.

The current recall endpoint is
`MdcinRtrvlSleStpgeInfoService04/getMdcinRtrvlSleStpgelList03`, but it returned
HTTP 403 for the production public-data key. Supply interruption and HIRA price
access also remain unauthorized. These three sources are excluded from the
scheduled allowlist and are not reported as loaded. Railway native daily,
weekly, and monthly backup schedules remain unavailable on the current Hobby
plan; see `docs/production-backup-restore.md`.

## Production promotion and retirement evidence

The validated catalog was copied into production from a repeatable-read source
snapshot on 2026-07-27. The operation replaced only the 13 catalog tables and
left the four account/authentication tables intact.

| Production measurement | Count |
| --- | ---: |
| Products | 78,090 |
| Product ingredients | 89,697 |
| Consumer-information rows | 4,739 |
| Identification representatives | 25,346 |
| Identification variants | 25,363 |
| DUR rules | 860,199 |
| Raw source records | 1,102,783 |

Row counts and canonical JSONB fingerprints matched the source for all 13
catalog tables. Authentication row fingerprints also matched a disposable
restore of the pre-promotion logical backup. Production API checks passed for
readiness, entitlement enforcement, metadata, search, detail, and DUR routes.

The production database measured 3,472,725,695 bytes after promotion. Database
plus WAL measured 3,556,611,775 bytes on the 5 GB volume. This is sufficient
for serving the current snapshot but not evidence that a full refresh can run
within the same volume: the historical refresh generated large transient WAL.
Automated full refresh therefore remains disabled until storage or the
replacement transaction strategy is expanded.

The replacement synchronization strategy avoids writes for unchanged non-DUR
records, updates stale rows in 500-row batches, and enforces a 750,000,000-byte
database-plus-WAL reserve against the configured 5,000,000,000-byte capacity.
Its unit and ingestion regression tests pass.

## Standard-code production canary

A fresh production dump was restored into an isolated PostgreSQL 18 container
on 2026-07-27. The official 305,522-row HIRA file was then ingested with the
same source code and schema intended for production.

| Measurement | Result |
| --- | ---: |
| Run status | succeeded |
| Elapsed time | 43.08 seconds |
| Peak resident memory | 407,977,984 bytes |
| Database growth | 358,203,392 bytes |
| WAL generated over the run | 2,047,342,600 bytes |
| WAL retained with `max_wal_size=96MB` | 100,663,296 bytes |
| Active standard-code raw records | 305,522 |
| Normalized standard codes | 305,522 |
| Product count before and after | 78,090 |
| Invalid indexes | 0 |

The first single-transaction implementation generated approximately 1.86 GB of
WAL and was rejected for production. The final implementation commits bounded
bootstrap pages behind the owning `sync_runs.status == "succeeded"` visibility
gate and does not create incomplete products. Applying the measured database
growth and 96 MiB retained WAL to the production baseline predicts
3,931,592,383 bytes in use, leaving 1,068,407,617 bytes on the configured 5 GB
capacity. This preserves the 750 MB synchronization reserve with approximately
318 MB additional margin.

The production PostgreSQL `max_wal_size` must be changed from 1 GB to 96 MB
before the first standard-code run and verified after it. The approved-source
cron runs at `18:10 UTC` and excludes recall, supply interruption, and price
until their production API applications return authorized responses.

After these checks, the staging domain, services, databases, volumes, and
Railway environment were authorized for deletion. The production database is
the sole persistent catalog source.
