"""Verify that a compact SQLite catalog preserves source-record identity."""

import argparse
import hashlib
import json
import sqlite3
from pathlib import Path

CATALOG_TABLES = (
    "source_records",
    "dur_rules",
    "drug_identification",
    "drug_identification_variants",
    "drug_codes",
    "drug_prices",
    "drug_status_events",
)
NORMALIZED_SOURCE_TABLES = CATALOG_TABLES[1:]


def _connect(path: Path) -> sqlite3.Connection:
    return sqlite3.connect(f"file:{path}?mode=ro", uri=True)


def _table_count(connection: sqlite3.Connection, table_name: str) -> int:
    row = connection.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()
    if row is None:
        raise RuntimeError(f"Could not count {table_name}.")
    return int(row[0])


def _source_digest(connection: sqlite3.Connection) -> str:
    digest = hashlib.sha256()
    rows = connection.execute(
        """
        SELECT id, source_code, record_key, content_hash, active, last_seen_run_id
        FROM source_records
        ORDER BY id
        """
    )
    for row in rows:
        encoded = json.dumps(
            row,
            ensure_ascii=False,
            separators=(",", ":"),
        ).encode()
        digest.update(len(encoded).to_bytes(8, "big"))
        digest.update(encoded)
    return digest.hexdigest()


def _columns(connection: sqlite3.Connection, table_name: str) -> set[str]:
    return {
        str(row[1])
        for row in connection.execute(f"PRAGMA table_info({table_name})")
    }


def verify(original_path: Path, compact_path: Path) -> dict[str, object]:
    with _connect(original_path) as original, _connect(compact_path) as compact:
        original_counts = {
            table_name: _table_count(original, table_name)
            for table_name in CATALOG_TABLES
        }
        compact_counts = {
            table_name: _table_count(compact, table_name)
            for table_name in CATALOG_TABLES
        }
        if original_counts != compact_counts:
            raise RuntimeError("Catalog table counts changed during compaction.")

        original_digest = _source_digest(original)
        compact_digest = _source_digest(compact)
        if original_digest != compact_digest:
            raise RuntimeError("Source-record identity changed during compaction.")

        integrity = compact.execute("PRAGMA integrity_check").fetchone()
        if integrity != ("ok",):
            raise RuntimeError(f"Compact database integrity failed: {integrity!r}")
        foreign_key_failures = compact.execute("PRAGMA foreign_key_check").fetchall()
        if foreign_key_failures:
            raise RuntimeError(
                f"Compact database has foreign key failures: {foreign_key_failures[:5]!r}"
            )

        for table_name in NORMALIZED_SOURCE_TABLES:
            columns = _columns(compact, table_name)
            if "payload" in columns or "source_record_id" not in columns:
                raise RuntimeError(
                    f"{table_name} does not use the compact source-record schema."
                )
            missing = compact.execute(
                f"SELECT COUNT(*) FROM {table_name} "
                "WHERE source_record_id IS NULL"
            ).fetchone()
            if missing is None or missing[0]:
                raise RuntimeError(
                    f"{table_name} contains rows without a source-record reference."
                )

    original_size = original_path.stat().st_size
    compact_size = compact_path.stat().st_size
    return {
        "originalBytes": original_size,
        "compactBytes": compact_size,
        "reductionPercent": round(
            (original_size - compact_size) / original_size * 100,
            2,
        ),
        "sourceRecordDigest": original_digest,
        "tableCounts": original_counts,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--original", type=Path, required=True)
    parser.add_argument("--compact", type=Path, required=True)
    arguments = parser.parse_args()
    result = verify(arguments.original, arguments.compact)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
