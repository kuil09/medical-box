"""Benchmark public-data compaction in a disposable PostgreSQL database."""

import argparse
import importlib.util
import json
import sqlite3
import threading
import time
from pathlib import Path
from types import ModuleType
from typing import Any

import psycopg
import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations

MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "20260729_0008_compact_catalog_public_data.py"
)
SOURCE_RECORD_CHILDREN = (
    ("drug_identification", "fk_drug_identification_source_record"),
    (
        "drug_identification_variants",
        "fk_drug_identification_variants_source_record",
    ),
    ("drug_codes", "fk_drug_codes_source_record"),
    ("drug_prices", "fk_drug_prices_source_record"),
    ("dur_rules", "fk_dur_rules_source_record"),
    ("drug_status_events", "fk_drug_status_events_source_record"),
)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite", type=Path, required=True)
    parser.add_argument("--database-url", required=True)
    parser.add_argument("--expected-database", required=True)
    parser.add_argument("--synthetic-standard-code-rows", type=int, default=305_522)
    return parser.parse_args()


def load_migration() -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        "compact_catalog_public_data_benchmark",
        MIGRATION_PATH,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load the catalog public-data migration.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def psycopg_url(database_url: str) -> str:
    return database_url.replace("postgresql+psycopg://", "postgresql://", 1)


def verify_database(connection: sa.Connection, expected_database: str) -> None:
    database_name = connection.scalar(sa.text("SELECT current_database()"))
    if database_name != expected_database:
        raise RuntimeError(
            f"Refusing benchmark on database {database_name!r}; "
            f"expected {expected_database!r}."
        )


def reset_schema(connection: sa.Connection) -> None:
    for table_name, _ in reversed(SOURCE_RECORD_CHILDREN):
        connection.execute(sa.text(f"DROP TABLE IF EXISTS {table_name}"))
    connection.execute(sa.text("DROP TABLE IF EXISTS source_records"))
    connection.execute(
        sa.text("DROP FUNCTION IF EXISTS catalog_identity_hash(text, text)")
    )
    connection.execute(
        sa.text(
            """
            CREATE FUNCTION catalog_identity_hash(text, text)
            RETURNS bigint
            LANGUAGE SQL
            IMMUTABLE
            STRICT
            PARALLEL SAFE
            AS $function$
                SELECT (
                    (
                        'x' ||
                        substr(
                            md5(length($1)::text || ':' || $1 || $2),
                            1,
                            16
                        )
                    )::bit(64)
                )::bigint
            $function$
            """
        )
    )
    connection.execute(
        sa.text(
            """
            CREATE UNLOGGED TABLE source_records (
                id integer PRIMARY KEY,
                source_code varchar(80) NOT NULL,
                record_key varchar(255) NOT NULL,
                content_hash varchar(64) NOT NULL,
                payload jsonb NOT NULL,
                active boolean NOT NULL,
                last_seen_run_id uuid NOT NULL,
                first_seen_at timestamp with time zone NOT NULL,
                last_seen_at timestamp with time zone NOT NULL
            )
            """
        )
    )
    connection.execute(
        sa.text(
            """
            ALTER TABLE source_records
            ALTER COLUMN payload SET COMPRESSION lz4
            """
        )
    )
    connection.execute(
        sa.text(
            """
            CREATE UNIQUE INDEX ux_source_records_identity_hash
            ON source_records (
                catalog_identity_hash(source_code, record_key)
            )
            """
        )
    )
    connection.execute(
        sa.text(
            """
            CREATE INDEX ix_source_records_source_code_brin
            ON source_records
            USING brin (source_code)
            WITH (pages_per_range = 32)
            """
        )
    )
    for table_name, constraint_name in SOURCE_RECORD_CHILDREN:
        connection.execute(
            sa.text(
                f"""
                CREATE UNLOGGED TABLE {table_name} (
                    id integer PRIMARY KEY,
                    source_record_id integer NOT NULL,
                    CONSTRAINT {constraint_name}
                        FOREIGN KEY (source_record_id)
                        REFERENCES source_records (id)
                        ON DELETE CASCADE
                )
                """
            )
        )


def copy_source_records(
    sqlite_path: Path,
    database_url: str,
) -> tuple[int, int]:
    with (
        sqlite3.connect(f"file:{sqlite_path}?mode=ro", uri=True) as source,
        psycopg.connect(psycopg_url(database_url)) as target,
        target.cursor() as cursor,
    ):
        maximum_id = 0
        row_count = 0
        rows = source.execute(
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
        started_at = time.monotonic()
        with cursor.copy(
            """
            COPY source_records (
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
                maximum_id = max(maximum_id, int(row[0]))
                row_count += 1
                if row_count % 100_000 == 0:
                    elapsed = time.monotonic() - started_at
                    print(
                        f"Copied {row_count:,} source records in {elapsed:.1f}s",
                        flush=True,
                    )
        target.commit()
    return row_count, maximum_id


def copy_child_mappings(sqlite_path: Path, database_url: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    with (
        sqlite3.connect(f"file:{sqlite_path}?mode=ro", uri=True) as source,
        psycopg.connect(psycopg_url(database_url)) as target,
        target.cursor() as cursor,
    ):
        for table_name, _ in SOURCE_RECORD_CHILDREN:
            rows = source.execute(
                f"SELECT source_record_id FROM {table_name}"
            )
            count = 0
            with cursor.copy(
                f"COPY {table_name} (id, source_record_id) FROM STDIN"
            ) as copy:
                for row in rows:
                    count += 1
                    copy.write_row((count, row[0]))
            counts[table_name] = count
        target.commit()
    return counts


def add_synthetic_standard_codes(
    connection: sa.Connection,
    *,
    first_id: int,
    row_count: int,
) -> None:
    if row_count < 0:
        raise ValueError("Synthetic row count cannot be negative.")
    if row_count == 0:
        return
    connection.execute(
        sa.text(
            """
            INSERT INTO source_records (
                id,
                source_code,
                record_key,
                content_hash,
                payload,
                active,
                last_seen_run_id,
                first_seen_at,
                last_seen_at
            )
            SELECT
                :first_id + sequence - 1,
                'hira_standard_code',
                lpad(sequence::text, 13, '0'),
                md5(sequence::text) || md5('code-' || sequence::text),
                jsonb_build_object(
                    '표준코드',
                    lpad(sequence::text, 13, '0'),
                    '제품코드(개정후)',
                    lpad((sequence % 1000000000)::text, 9, '0'),
                    '품목명',
                    'Synthetic standard-code medicine ' || sequence::text,
                    '업체명',
                    'Synthetic manufacturer'
                ),
                true,
                '00000000-0000-0000-0000-000000000001'::uuid,
                '2026-07-29 00:00:00+00'::timestamptz,
                '2026-07-29 00:00:00+00'::timestamptz
            FROM generate_series(1, :row_count) AS sequence
            """
        ),
        {"first_id": first_id, "row_count": row_count},
    )
    connection.execute(
        sa.text(
            """
            INSERT INTO drug_codes (id, source_record_id)
            SELECT id, id
            FROM source_records
            WHERE source_code = 'hira_standard_code'
            """
        )
    )


def relation_measurements(connection: sa.Connection) -> dict[str, int]:
    row = connection.execute(
        sa.text(
            """
            SELECT
                COUNT(*) AS rows,
                pg_table_size('source_records') AS table_bytes,
                pg_indexes_size('source_records') AS index_bytes,
                pg_total_relation_size('source_records') AS total_bytes,
                COALESCE(
                    SUM(pg_column_size(payload)),
                    0
                ) AS inline_payload_bytes,
                COALESCE(
                    SUM(octet_length(payload::text)),
                    0
                ) AS json_text_bytes
            FROM source_records
            """
        )
    ).mappings().one()
    return {key: int(value) for key, value in row.items()}


def source_fingerprint(connection: sa.Connection) -> dict[str, int]:
    row = connection.execute(
        sa.text(
            """
            SELECT
                COUNT(*) AS rows,
                MIN(id) AS minimum_id,
                MAX(id) AS maximum_id,
                COALESCE(SUM(id), 0) AS id_sum,
                COUNT(*) FILTER (WHERE active) AS active_rows
            FROM source_records
            """
        )
    ).mappings().one()
    return {key: int(value or 0) for key, value in row.items()}


def child_counts(connection: sa.Connection) -> dict[str, int]:
    return {
        table_name: int(
            connection.scalar(sa.text(f"SELECT COUNT(*) FROM {table_name}"))
            or 0
        )
        for table_name, _ in SOURCE_RECORD_CHILDREN
    }


def public_field_violations(connection: sa.Connection) -> int:
    migration = load_migration()
    predicate = migration._allowed_field_predicate(
        "source_records.source_code",
        "entry.key",
    )
    return int(
        connection.scalar(
            sa.text(
                f"""
                SELECT COUNT(*)
                FROM source_records
                CROSS JOIN LATERAL jsonb_each(source_records.payload) AS entry
                WHERE NOT ({predicate})
                """
            )
        )
        or 0
    )


def run_migration(connection: sa.Connection) -> None:
    context = MigrationContext.configure(connection)
    with Operations.context(context):
        load_migration().upgrade()


def storage_sample(database_url: str) -> tuple[int, int]:
    with (
        psycopg.connect(psycopg_url(database_url)) as connection,
        connection.cursor() as cursor,
    ):
        cursor.execute(
            """
            SELECT
                pg_database_size(current_database()),
                COALESCE(
                    (SELECT SUM(size) FROM pg_ls_waldir()),
                    0
                )
            """
        )
        row = cursor.fetchone()
    if row is None:
        raise RuntimeError("Could not sample PostgreSQL storage.")
    return int(row[0]), int(row[1])


def monitor_storage(
    database_url: str,
    stop: threading.Event,
    samples: list[tuple[int, int]],
) -> None:
    while not stop.is_set():
        samples.append(storage_sample(database_url))
        stop.wait(0.2)
    samples.append(storage_sample(database_url))


def main() -> None:
    arguments = parse_arguments()
    if not arguments.sqlite.is_file():
        raise FileNotFoundError(arguments.sqlite)
    engine = sa.create_engine(arguments.database_url)
    try:
        with engine.begin() as connection:
            verify_database(connection, arguments.expected_database)
            reset_schema(connection)

        copied_rows, maximum_id = copy_source_records(
            arguments.sqlite,
            arguments.database_url,
        )
        copied_children = copy_child_mappings(
            arguments.sqlite,
            arguments.database_url,
        )
        with engine.begin() as connection:
            verify_database(connection, arguments.expected_database)
            add_synthetic_standard_codes(
                connection,
                first_id=maximum_id + 1,
                row_count=arguments.synthetic_standard_code_rows,
            )
            connection.execute(sa.text("ANALYZE source_records"))
            before = relation_measurements(connection)
            fingerprint_before = source_fingerprint(connection)
            children_before = child_counts(connection)

        baseline_database_bytes, baseline_wal_bytes = storage_sample(
            arguments.database_url
        )
        samples: list[tuple[int, int]] = [
            (baseline_database_bytes, baseline_wal_bytes)
        ]
        stop = threading.Event()
        monitor = threading.Thread(
            target=monitor_storage,
            args=(arguments.database_url, stop, samples),
            daemon=True,
        )
        monitor.start()
        started_at = time.perf_counter()
        try:
            with engine.begin() as connection:
                wal_before = connection.scalar(
                    sa.text("SELECT pg_current_wal_insert_lsn()")
                )
                run_migration(connection)
                wal_after = connection.scalar(
                    sa.text("SELECT pg_current_wal_insert_lsn()")
                )
                wal_bytes = int(
                    connection.scalar(
                        sa.text("SELECT pg_wal_lsn_diff(:after, :before)"),
                        {"after": wal_after, "before": wal_before},
                    )
                    or 0
                )
        finally:
            stop.set()
            monitor.join(timeout=10)
        elapsed_seconds = time.perf_counter() - started_at

        with engine.begin() as connection:
            after = relation_measurements(connection)
            fingerprint_after = source_fingerprint(connection)
            children_after = child_counts(connection)
            foreign_key_failures = int(
                connection.scalar(
                    sa.text(
                        """
                        SELECT COUNT(*)
                        FROM (
                            SELECT source_record_id FROM drug_identification
                            UNION ALL
                            SELECT source_record_id
                            FROM drug_identification_variants
                            UNION ALL
                            SELECT source_record_id FROM drug_codes
                            UNION ALL
                            SELECT source_record_id FROM drug_prices
                            UNION ALL
                            SELECT source_record_id FROM dur_rules
                            UNION ALL
                            SELECT source_record_id FROM drug_status_events
                        ) AS child
                        LEFT JOIN source_records
                            ON source_records.id = child.source_record_id
                        WHERE source_records.id IS NULL
                        """
                    )
                )
                or 0
            )
            violations = public_field_violations(connection)
            integrity = connection.scalar(
                sa.text(
                    """
                    SELECT COUNT(*)
                    FROM pg_index
                    WHERE NOT indisvalid
                    """
                )
            )

        peak_database_bytes = max(sample[0] for sample in samples)
        peak_wal_bytes = max(sample[1] for sample in samples)
        result: dict[str, Any] = {
            "copied_source_rows": copied_rows,
            "copied_child_rows": copied_children,
            "child_rows_before": children_before,
            "child_rows_after": children_after,
            "synthetic_standard_code_rows": (
                arguments.synthetic_standard_code_rows
            ),
            "elapsed_seconds": round(elapsed_seconds, 3),
            "wal_generated_bytes": wal_bytes,
            "baseline_database_bytes": baseline_database_bytes,
            "baseline_wal_bytes": baseline_wal_bytes,
            "peak_database_bytes": peak_database_bytes,
            "peak_wal_bytes": peak_wal_bytes,
            "peak_database_plus_wal_growth": (
                peak_database_bytes
                + peak_wal_bytes
                - baseline_database_bytes
                - baseline_wal_bytes
            ),
            "before": before,
            "after": after,
            "relation_bytes_saved": before["total_bytes"] - after["total_bytes"],
            "fingerprint_preserved": fingerprint_before == fingerprint_after,
            "child_counts_preserved": children_before == children_after,
            "foreign_key_failures": foreign_key_failures,
            "public_field_violations": violations,
            "invalid_indexes": int(integrity or 0),
        }
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))

        if not result["fingerprint_preserved"]:
            raise RuntimeError("Source-record fingerprint changed.")
        if not result["child_counts_preserved"]:
            raise RuntimeError("Normalized child counts changed.")
        if foreign_key_failures or violations or integrity:
            raise RuntimeError("PostgreSQL compaction integrity check failed.")
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
