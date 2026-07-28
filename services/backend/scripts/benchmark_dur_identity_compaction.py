"""Benchmark the DUR identity compaction in an isolated PostgreSQL database."""

import argparse
import importlib.util
import json
import time
from pathlib import Path
from types import ModuleType
from typing import Any

import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations

MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "20260728_0006_compact_dur_identity.py"
)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--database-url", required=True)
    parser.add_argument("--expected-database", required=True)
    parser.add_argument("--rows", type=int, default=860_198)
    return parser.parse_args()


def load_migration() -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        "compact_dur_identity_benchmark",
        MIGRATION_PATH,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("Could not load the DUR identity migration.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def create_legacy_schema(connection: sa.Connection) -> None:
    connection.execute(sa.text("DROP TABLE IF EXISTS dur_rules"))
    connection.execute(sa.text("DROP TABLE IF EXISTS source_records"))
    connection.execute(
        sa.text(
            """
            CREATE TABLE source_records (
                id BIGINT PRIMARY KEY,
                source_code VARCHAR(80) NOT NULL,
                record_key VARCHAR(255) NOT NULL
            )
            """
        )
    )
    connection.execute(
        sa.text(
            """
            CREATE TABLE dur_rules (
                id BIGINT PRIMARY KEY,
                source_record_id BIGINT NOT NULL
                    REFERENCES source_records(id) ON DELETE CASCADE,
                item_seq VARCHAR(40),
                source_code VARCHAR(80) NOT NULL,
                rule_key VARCHAR(255) NOT NULL,
                rule_type VARCHAR(120),
                CONSTRAINT dur_rules_source_code_rule_key_key
                    UNIQUE (source_code, rule_key)
            )
            """
        )
    )
    connection.execute(
        sa.text(
            """
            CREATE INDEX ix_dur_rules_source_record_id
            ON dur_rules (source_record_id)
            """
        )
    )
    connection.execute(
        sa.text(
            """
            CREATE INDEX ix_dur_rules_item_seq
            ON dur_rules (item_seq)
            """
        )
    )


def seed_rows(connection: sa.Connection, row_count: int) -> None:
    if row_count < 1:
        raise ValueError("Row count must be positive.")
    connection.execute(
        sa.text(
            """
            INSERT INTO source_records (id, source_code, record_key)
            SELECT
                sequence,
                CASE sequence % 8
                    WHEN 0 THEN 'mfds_dur_product_concomitant'
                    WHEN 1 THEN 'mfds_dur_product_pregnancy'
                    WHEN 2 THEN 'mfds_dur_product_elderly'
                    WHEN 3 THEN 'mfds_dur_product_age'
                    WHEN 4 THEN 'mfds_dur_product_dose'
                    WHEN 5 THEN 'mfds_dur_ingredient_concomitant'
                    WHEN 6 THEN 'mfds_dur_ingredient_pregnancy'
                    ELSE 'mfds_dur_ingredient_duplicate'
                END,
                'dur-rule-' || lpad(sequence::text, 10, '0')
                    || '-' || md5(sequence::text)
            FROM generate_series(1, :row_count) AS sequence
            """
        ),
        {"row_count": row_count},
    )
    connection.execute(
        sa.text(
            """
            INSERT INTO dur_rules (
                id,
                source_record_id,
                item_seq,
                source_code,
                rule_key,
                rule_type
            )
            SELECT
                id,
                id,
                CASE WHEN id % 5 = 0 THEN NULL
                    ELSE lpad((id % 78090)::text, 9, '0')
                END,
                source_code,
                record_key,
                CASE id % 4
                    WHEN 0 THEN 'concomitant_contraindication'
                    WHEN 1 THEN 'pregnancy_contraindication'
                    WHEN 2 THEN 'elderly_caution'
                    ELSE 'age_contraindication'
                END
            FROM source_records
            """
        )
    )


def relation_measurements(connection: sa.Connection) -> dict[str, Any]:
    indexes = [
        dict(row)
        for row in connection.execute(
            sa.text(
                """
                SELECT
                    indexrelname AS name,
                    pg_relation_size(
                        pg_stat_user_indexes.indexrelid
                    ) AS bytes,
                    pg_index.indisunique AS unique
                FROM pg_stat_user_indexes
                JOIN pg_index ON pg_index.indexrelid =
                    pg_stat_user_indexes.indexrelid
                WHERE relname = 'dur_rules'
                ORDER BY indexrelname
                """
            )
        ).mappings()
    ]
    table = dict(
        connection.execute(
            sa.text(
                """
                SELECT
                    COUNT(*) AS rows,
                    COUNT(DISTINCT source_record_id) AS distinct_source_records,
                    pg_table_size('dur_rules') AS table_bytes,
                    pg_indexes_size('dur_rules') AS index_bytes,
                    pg_total_relation_size('dur_rules') AS total_bytes
                FROM dur_rules
                """
            )
        ).mappings().one()
    )
    return {"table": table, "indexes": indexes}


def run_migration(connection: sa.Connection) -> None:
    context = MigrationContext.configure(connection)
    with Operations.context(context):
        load_migration().upgrade()


def main() -> None:
    arguments = parse_arguments()
    engine = sa.create_engine(arguments.database_url)
    try:
        with engine.begin() as connection:
            database_name = connection.scalar(sa.text("SELECT current_database()"))
            if database_name != arguments.expected_database:
                raise RuntimeError(
                    f"Refusing benchmark on database {database_name!r}; "
                    f"expected {arguments.expected_database!r}."
                )
            create_legacy_schema(connection)
            seed_rows(connection, arguments.rows)
            before = relation_measurements(connection)
            wal_before = connection.scalar(sa.text("SELECT pg_current_wal_lsn()"))
            started_at = time.perf_counter()
            run_migration(connection)
            elapsed_seconds = time.perf_counter() - started_at
            wal_after = connection.scalar(sa.text("SELECT pg_current_wal_lsn()"))
            wal_bytes = int(
                connection.scalar(
                    sa.text("SELECT pg_wal_lsn_diff(:after, :before)"),
                    {"after": wal_after, "before": wal_before},
                )
                or 0
            )
            after = relation_measurements(connection)
            columns = {
                column["name"]
                for column in sa.inspect(connection).get_columns("dur_rules")
            }
            result = {
                "rows": arguments.rows,
                "elapsed_seconds": round(elapsed_seconds, 3),
                "wal_bytes": wal_bytes,
                "before": before,
                "after": after,
                "index_bytes_saved": (
                    before["table"]["index_bytes"]
                    - after["table"]["index_bytes"]
                ),
                "total_bytes_saved": (
                    before["table"]["total_bytes"]
                    - after["table"]["total_bytes"]
                ),
                "source_identity_columns_removed": (
                    "source_code" not in columns and "rule_key" not in columns
                ),
                "one_to_one_preserved": (
                    after["table"]["rows"]
                    == after["table"]["distinct_source_records"]
                    == arguments.rows
                ),
            }
            print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    finally:
        with engine.begin() as connection:
            database_name = connection.scalar(sa.text("SELECT current_database()"))
            if database_name == arguments.expected_database:
                connection.execute(sa.text("DROP TABLE IF EXISTS dur_rules"))
                connection.execute(sa.text("DROP TABLE IF EXISTS source_records"))
        engine.dispose()


if __name__ == "__main__":
    main()
