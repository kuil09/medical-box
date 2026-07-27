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

## Product-detail document fields

The largest product-detail fields were `NB_DOC_DATA` (969.1 MiB),
`PN_DOC_DATA` (438.1 MiB), and `UD_DOC_DATA` (91.9 MiB). `PN_DOC_DATA` had
14,607 references to 11,996 distinct documents, but content deduplication would
save only about 60.1 MiB. Compression has higher expected value than document
deduplication for this source.

## Recommended implementation order

1. Run every future compact import in disposable isolated infrastructure and
   confirm relation, database, WAL, and volume sizes stay below the target
   boundary.
2. Keep content hashes and source attribution in PostgreSQL even if raw bodies
   move to compressed archival storage.
3. Re-run the complete acquisition into a new database, validate counts and
   hashes, and switch only after the new snapshot passes every invariant.

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
