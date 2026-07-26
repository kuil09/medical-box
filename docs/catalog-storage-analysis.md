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

1. Add a raw-record foreign key to normalized payload-bearing tables.
2. Remove duplicate JSON columns from `dur_rules`,
   `drug_identification_variants`, and other normalized source projections.
3. Benchmark PostgreSQL JSONB TOAST compression against application-level
   Zstandard-compressed `bytea` storage using a representative staging import.
4. Keep content hashes and source attribution in PostgreSQL even if raw bodies
   move to compressed archival storage.
5. Re-run the complete acquisition into a new database, validate counts and
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
