# Catalog storage analysis

This document records a read-only storage analysis of the complete local
catalog snapshot on 2026-07-26. The measured SQLite database was
`services/backend/korean_drug_catalog.db`.

## Baseline

| Object | Measured size |
| --- | ---: |
| Complete SQLite database | 9.96 GiB |
| `source_records` table | 6,541.3 MiB |
| `dur_rules` table | 3,212.6 MiB |
| `source_records` indexes | 197.7 MiB |
| `dur_rules` indexes | 112.7 MiB |
| `drug_identification` and variant tables | 87.1 MiB |

The database had no free-list pages, so `VACUUM` alone would not materially
reduce the current file.

The largest raw source payloads were:

| Source | Rows | Raw JSON text |
| --- | ---: | ---: |
| Product authorization detail | 42,957 | 3,025.4 MiB |
| Product-level concomitant DUR | 798,400 | 1,654.4 MiB |
| Product ingredient detail | 126,622 | 61.5 MiB |
| Product authorization list | 42,957 | 34.8 MiB |
| Legacy DUR stream | 23,449 | 31.1 MiB |
| Pill identification | 25,349 | 29.8 MiB |
| Consumer information | 4,757 | 20.9 MiB |

Inactive raw records account for only 4.9 MiB. Deleting inactive rows is
therefore not a useful primary optimization.

## Confirmed duplication

The ingestion path stores each DUR payload in both `source_records.payload` and
`dur_rules.payload`. A 10,000-row key-matched sample contained 10,000
byte-identical payload pairs. The same structural duplication exists for
identification variants and their normalized compatibility records.

Normalized catalog tables should reference the owning raw record instead of
copying the complete JSON payload. Removing the DUR payload copy is the
highest-value schema-level optimization.

## Implemented compact snapshot

The normalized payload columns were replaced with non-null foreign keys to
`source_records`. DUR API responses now load their official wording from the
linked raw record. The migration refuses to remove a payload column if any
normalized row cannot be mapped to its source record.

The original database remained read-only. A separate
`korean_drug_catalog_compact.db` copy was migrated, vacuumed, and checked with
`scripts/verify_catalog_compaction.py`.

| Verification | Result |
| --- | ---: |
| Original file | 10,697,076,736 bytes |
| Compact file | 7,338,266,624 bytes |
| Reduction | 31.40% |
| Raw records | 1,109,256 in both files |
| DUR rules | 863,599 in both files |
| Identification representatives | 25,332 in both files |
| Identification variants | 25,349 in both files |
| Raw identity digest | `942310634a0da346a6f17807dc57c44779c393676d1f64c084fdb48d3a12dc87` |
| SQLite integrity check | `ok` |
| Foreign-key failures | 0 |

The compact SQLite file is still 6.83 GiB. This confirms that duplicate
normalized payload removal is necessary but not sufficient for a strict 5 GiB
uncompressed storage boundary. PostgreSQL JSONB TOAST compression or explicit
raw-payload compression must be measured before the production catalog import.

## PostgreSQL 18 storage benchmark

The complete 1,109,256-row `source_records` table was copied into an isolated
local PostgreSQL 18 instance with JSONB LZ4 TOAST compression. The benchmark
included the primary key, source identity unique index, active-source index,
and sync-run index.

| PostgreSQL object | Measured size |
| --- | ---: |
| Main heap | 1,869,086,720 bytes |
| TOAST relation | 985,423,872 bytes |
| Indexes | 163,389,440 bytes |
| Total raw-record relation | 3,018,383,360 bytes (2.81 GiB) |

Adding the entire non-`source_records` portion of the compact SQLite database
without assuming any further PostgreSQL savings produces a conservative
catalog estimate of about 3.26 GiB. The existing Railway production volume
used about 153 MB when inspected, so the expected combined footprint remains
below the current 5 GB volume boundary with roughly 1.6 GiB of margin.

Migration `20260726_0004` explicitly sets LZ4 compression on
`source_records.payload` in PostgreSQL so this result does not depend on the
server's default TOAST compression setting. Any future full replacement must
still be preceded by an isolated disposable import and a live
`pg_total_relation_size` check.

## Historical Railway acquisition validation

The complete authorized staging snapshot was measured on 2026-07-27 after
loading 78,090 products, 266,033 active non-DUR raw records, and 860,199 DUR
rules. The 5 GB Railway volume exposed 4,615 MiB of usable filesystem space and
ended at 3,607 MiB used with 992 MiB available.

An initial full-table DUR activation generated approximately 890 MiB of WAL and
filled the filesystem even though the steady-state catalog fit. The recovery
changed DUR visibility to a single successful-run gate, removed the full-table
activation, and set staging PostgreSQL `max_wal_size` to 256 MiB. Capacity
checks must therefore measure both steady-state relations and transient WAL;
logical database size alone is not a sufficient release criterion.

The validated snapshot was promoted to production on 2026-07-27, after which
the persistent staging environment was retired. Production database plus WAL
measured 3,556,611,775 bytes. Scheduled full refresh remains disabled because
the steady-state fit does not provide enough evidence of safe transient
headroom on the 5 GB volume.

## DUR identity index compaction

A read-only production measurement on 2026-07-28 confirmed that all 860,198
normalized DUR rules map one-to-one to 860,198 raw source records. The
normalized table therefore does not need to repeat `source_code` and
`rule_key`; both values remain available through `source_record_id`.

| Production index | Measured size |
| --- | ---: |
| `dur_rules_source_code_rule_key_key` | 152,313,856 bytes |
| `ix_dur_rules_source_record_id` | 19,341,312 bytes |

Migration `20260728_0006` replaces the non-unique source-record index with a
unique index, removes the redundant natural-key constraint, and drops the two
duplicated columns. The existing and replacement source-record indexes are
approximately the same size, so the 152,313,856-byte natural-key index is the
expected production net reduction. No raw payload or normalized safety field
is removed.

The migration was replayed against 860,198 synthetic rows in an isolated
PostgreSQL 18 container:

| Canary measurement | Result |
| --- | ---: |
| Rows before and after | 860,198 |
| Distinct source-record mappings | 860,198 |
| Total bytes saved | 161,857,536 |
| WAL generated | 14,925,824 bytes |
| Migration elapsed time | 0.364 seconds |

The benchmark is reproducible with
`scripts/benchmark_dur_identity_compaction.py`. It requires both an explicit
database URL and the exact expected disposable database name and refuses to
run when the names do not match.

## Compression evidence

Representative UTF-8 JSON samples were compressed independently per row with
zlib level 6. Independent compression is a more conservative proxy for
PostgreSQL TOAST or per-record blob compression than whole-file compression.

| Source sample | Compressed/original ratio |
| --- | ---: |
| Product authorization detail, spread sample | 25.1% |
| Product-level concomitant DUR | 36.1% |
| Consumer information | 31.2% |
| Pill identification | 48.1% |

Whole-stream compression was substantially smaller because field names and
repeated categorical values compress across records. Raw source snapshots are
therefore strong candidates for compressed archival storage when SQL-level JSON
queries are not required.

## API-facing public-data compaction

The API does not query complete source documents. Product, ingredient,
consumer, appearance, price, and status values are already normalized into
typed tables. Runtime joins to `source_records` require only:

- official DUR wording and counterpart labels;
- recall or shortage reasons;
- HIRA code mappings;
- source update timestamps; and
- pill-identification timestamps and image URLs used to select a deterministic
  compatibility representative during acquisition.

An isolated projection of the complete local catalog retained 891,963
non-empty public-data rows. The projection contained 258,317,021 bytes of JSON
text and occupied 388,907,008 bytes in SQLite. Product authorization, product
detail, ingredient, and consumer source records retained no JSON fields because
their public values already exist in normalized tables.

Migration `20260729_0008` replaces the PostgreSQL `source_records` relation in
one transaction. It preserves every row ID, source identity, canonical hash,
visibility flag, sync-run link, and timestamp while copying only allowlisted
public fields. All six normalized foreign-key relationships are validated
against the replacement before the original relation is dropped. The physical
column name remains `payload` solely for rolling-deployment compatibility; the
application maps it as `SourceRecord.public_data` and never treats it as a
complete upstream payload.

Future ingestion computes the canonical hash from the complete fetched record,
normalizes that record immediately, and persists only the allowlisted
`public_data`. A normalization mapping change therefore requires an official
source re-fetch; the former database-only renormalization command now refuses
to run.

The replacement was replayed in PostgreSQL 18 against all 1,109,256 local
source records plus 305,522 synthetic HIRA standard-code records. The six
normalized foreign-key tables included 863,599 DUR rules, 25,332
identification representatives, 25,349 identification variants, and 305,522
standard-code mappings.

| Full-scale public-data canary | Result |
| --- | ---: |
| Source records before and after | 1,414,778 |
| Source-record relation before | 2,925,740,032 bytes |
| Source-record relation after | 767,033,344 bytes |
| Relation reduction | 2,158,706,688 bytes |
| Migration elapsed time | 31.743 seconds |
| WAL generated | 792,120,056 bytes |
| Peak retained WAL at 96 MiB `max_wal_size` | 117,440,512 bytes |
| Peak database-plus-WAL growth | 867,745,792 bytes |
| Row-ID fingerprint preserved | yes |
| Child counts preserved | yes |
| Foreign-key failures | 0 |
| Non-public retained fields | 0 |
| Invalid indexes | 0 |

The same canary with PostgreSQL's default 1 GiB `max_wal_size` retained
805,306,368 bytes of WAL and peaked 1,538,842,624 bytes above baseline, which
exceeds the production volume's measured free space. The migration therefore
refuses a relation of at least 1 GB when `max_wal_size` exceeds 128 MiB.
Production must retain its validated 96 MiB setting and be checkpointed before
deployment.

## Product-detail document fields

The largest product-detail fields were `NB_DOC_DATA` (969.1 MiB),
`PN_DOC_DATA` (438.1 MiB), and `UD_DOC_DATA` (91.9 MiB). `PN_DOC_DATA` had
14,607 references to 11,996 distinct documents, but content deduplication would
save only about 60.1 MiB. Compression has higher expected value than document
deduplication for this source.

## Recommended implementation order

1. Replay the public-data replacement in disposable PostgreSQL and confirm
   relation, database, WAL, and peak volume sizes stay below the production
   boundary.
2. Preserve content hashes, source identities, attribution, row IDs, and every
   normalized foreign-key relationship.
3. Keep the pre-migration backup until post-deployment counts, API responses,
   foreign keys, and storage reclamation have been verified.

Do not rewrite or delete the only complete local snapshot in place. Keep the
current database as verification evidence until the compact representation has
passed a full round trip.

## Local workspace caches

The following ignored, reproducible artifacts consume local disk space but are
not part of Git:

| Path | Measured size |
| --- | ---: |
| `apps/mobile/build` | 3.0 GiB |
| `apps/mobile/.dart_tool` | 449 MiB |
| `services/backend/.venv` | 180 MiB |
| `design/prototype/node_modules` | 159 MiB |
| `design/prototype/dist` | 8.9 MiB |

These caches may be removed when local disk space is needed and regenerated
from the committed lock files. They are separate from catalog data-model
optimization.
