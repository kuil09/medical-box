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
- HIRA standard-code downloads accept CSV, XLSX, or ZIP containers, detect
  Korean header rows, and are capped at 250 MiB per file.
- A standard-code file whose SHA-256 matches its checkpoint is recorded as
  skipped and does not update source rows or normalized codes.
- Product ingredients are normalized from structured ingredient fields when
  available and conservatively split from known flat MFDS ingredient fields.
- DUR product and ingredient operations are synchronized as 16 independent
  source streams. Variant identity includes the canonical payload hash because
  upstream natural identifiers are not unique across all rule variants.
- Byte-identical duplicate DUR rows count toward the official response total
  but are stored once. Semantically different variants remain separate.
- Stale DUR rules are removed with a correlated active-source check rather than
  a key-list `NOT IN` clause, so cleanup is not bounded by a database parameter
  limit.
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
2025-10-31 CSV with 298,183 rows. The portal permits the original file to be
downloaded without login, but its generated OpenAPI still requires a separate
application. The production job should prefer the original file and record its
download hash.

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
retain one transaction per source snapshot, and preserve the same active-snapshot
and rollback invariants.

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
