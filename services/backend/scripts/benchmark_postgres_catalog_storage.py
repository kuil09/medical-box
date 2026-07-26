"""Measure PostgreSQL storage for the complete raw SQLite catalog."""

import argparse
import json
import sqlite3
from pathlib import Path
from time import monotonic

import psycopg

TABLE_NAME = "catalog_source_records_benchmark"


def _sqlite_connection(path: Path) -> sqlite3.Connection:
    return sqlite3.connect(f"file:{path}?mode=ro", uri=True)


def _prepare_postgres(
    connection: psycopg.Connection[tuple[object, ...]],
    compression: str,
) -> None:
    with connection.cursor() as cursor:
        cursor.execute(f"DROP TABLE IF EXISTS {TABLE_NAME}")
        cursor.execute(
            f"""
            CREATE UNLOGGED TABLE {TABLE_NAME} (
                id BIGINT PRIMARY KEY,
                source_code VARCHAR(80) NOT NULL,
                record_key VARCHAR(255) NOT NULL,
                content_hash VARCHAR(64) NOT NULL,
                payload JSONB NOT NULL,
                active BOOLEAN NOT NULL,
                last_seen_run_id UUID NOT NULL,
                first_seen_at TIMESTAMPTZ NOT NULL,
                last_seen_at TIMESTAMPTZ NOT NULL
            )
            """
        )
        cursor.execute(
            f"ALTER TABLE {TABLE_NAME} ALTER COLUMN payload "
            f"SET COMPRESSION {compression}"
        )
    connection.commit()


def _copy_source_records(
    sqlite_connection: sqlite3.Connection,
    postgres_connection: psycopg.Connection[tuple[object, ...]],
) -> int:
    rows = sqlite_connection.execute(
        """
        SELECT
            id,
            source_code,
            record_key,
            content_hash,
            payload,
            active,
            last_seen_run_id,
            first_seen_at,
            last_seen_at
        FROM source_records
        ORDER BY id
        """
    )
    started_at = monotonic()
    count = 0
    with postgres_connection.cursor() as cursor, cursor.copy(
        f"""
        COPY {TABLE_NAME} (
            id,
            source_code,
            record_key,
            content_hash,
            payload,
            active,
            last_seen_run_id,
            first_seen_at,
            last_seen_at
        ) FROM STDIN
        """
    ) as copy:
        for row in rows:
            copy.write_row(row)
            count += 1
            if count % 50_000 == 0:
                elapsed = monotonic() - started_at
                print(f"Copied {count:,} rows in {elapsed:.1f}s", flush=True)
    postgres_connection.commit()
    return count


def _create_indexes(
    connection: psycopg.Connection[tuple[object, ...]],
) -> None:
    with connection.cursor() as cursor:
        cursor.execute(
            f"""
            CREATE UNIQUE INDEX benchmark_source_identity
            ON {TABLE_NAME} (source_code, record_key)
            """
        )
        cursor.execute(
            f"""
            CREATE INDEX benchmark_source_active
            ON {TABLE_NAME} (source_code, active)
            """
        )
        cursor.execute(
            f"""
            CREATE INDEX benchmark_source_last_seen_run
            ON {TABLE_NAME} (last_seen_run_id)
            """
        )
        cursor.execute(f"ANALYZE {TABLE_NAME}")
    connection.commit()


def _measure(
    connection: psycopg.Connection[tuple[object, ...]],
) -> dict[str, int]:
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT
                pg_relation_size(%s),
                pg_indexes_size(%s),
                pg_total_relation_size(%s),
                pg_total_relation_size(reltoastrelid)
            FROM pg_class
            WHERE oid = %s::regclass
            """,
            (TABLE_NAME, TABLE_NAME, TABLE_NAME, TABLE_NAME),
        )
        row = cursor.fetchone()
    if row is None:
        raise RuntimeError("Could not measure the benchmark table.")
    return {
        "heapBytes": int(row[0]),
        "indexBytes": int(row[1]),
        "totalBytes": int(row[2]),
        "toastBytes": int(row[3]),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite", type=Path, required=True)
    parser.add_argument("--database-url", required=True)
    parser.add_argument(
        "--compression",
        choices=("pglz", "lz4"),
        default="lz4",
    )
    arguments = parser.parse_args()

    with (
        _sqlite_connection(arguments.sqlite) as sqlite_connection,
        psycopg.connect(arguments.database_url) as postgres_connection,
    ):
        _prepare_postgres(postgres_connection, arguments.compression)
        row_count = _copy_source_records(sqlite_connection, postgres_connection)
        _create_indexes(postgres_connection)
        result = {
            "compression": arguments.compression,
            "rowCount": row_count,
            **_measure(postgres_connection),
        }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
