"""Reference raw catalog records instead of duplicating normalized payloads."""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "20260726_0004"
down_revision = "20260726_0003"
branch_labels = None
depends_on = None

TABLES = (
    "drug_identification",
    "drug_identification_variants",
    "drug_codes",
    "drug_prices",
    "dur_rules",
    "drug_status_events",
)


def _columns(table_name: str) -> set[str]:
    return {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns(table_name)
    }


def _index_name(table_name: str) -> str:
    return f"ix_{table_name}_source_record_id"


def _foreign_key_name(table_name: str) -> str:
    return f"fk_{table_name}_source_record"


def _backfill_source_record_ids() -> None:
    statements = {
        "drug_identification_variants": """
            UPDATE drug_identification_variants
            SET source_record_id = (
                SELECT source_records.id
                FROM source_records
                WHERE source_records.source_code =
                        drug_identification_variants.source_code
                  AND source_records.record_key =
                        drug_identification_variants.variant_key
                LIMIT 1
            )
        """,
        "dur_rules": """
            UPDATE dur_rules
            SET source_record_id = (
                SELECT source_records.id
                FROM source_records
                WHERE source_records.source_code = dur_rules.source_code
                  AND source_records.record_key = dur_rules.rule_key
                LIMIT 1
            )
        """,
        "drug_status_events": """
            UPDATE drug_status_events
            SET source_record_id = (
                SELECT source_records.id
                FROM source_records
                WHERE source_records.source_code =
                        drug_status_events.source_code
                  AND source_records.record_key =
                        drug_status_events.event_key
                LIMIT 1
            )
        """,
        "drug_prices": """
            UPDATE drug_prices
            SET source_record_id = (
                SELECT source_records.id
                FROM source_records
                WHERE source_records.source_code = 'hira_price'
                  AND source_records.record_key = drug_prices.insurance_code
                LIMIT 1
            )
        """,
        "drug_codes": """
            UPDATE drug_codes
            SET source_record_id = (
                SELECT source_records.id
                FROM source_records
                WHERE source_records.source_code = 'hira_standard_code'
                  AND source_records.record_key = drug_codes.code
                LIMIT 1
            )
        """,
        "drug_identification": """
            UPDATE drug_identification
            SET source_record_id = (
                SELECT source_records.id
                FROM drug_identification_variants
                JOIN source_records
                  ON source_records.source_code =
                        drug_identification_variants.source_code
                 AND source_records.record_key =
                        drug_identification_variants.variant_key
                WHERE drug_identification_variants.item_seq =
                        drug_identification.item_seq
                  AND source_records.payload = drug_identification.payload
                LIMIT 1
            )
        """,
    }
    connection = op.get_bind()
    for table_name, statement in statements.items():
        connection.execute(sa.text(statement))
        missing = connection.scalar(
            sa.text(
                f"SELECT COUNT(*) FROM {table_name} "
                "WHERE source_record_id IS NULL"
            )
        )
        if missing:
            raise RuntimeError(
                f"{table_name} has {missing} rows without a matching raw source record."
            )


def upgrade() -> None:
    connection = op.get_bind()
    if connection.dialect.name == "postgresql":
        connection.execute(
            sa.text(
                "ALTER TABLE source_records "
                "ALTER COLUMN payload SET COMPRESSION lz4"
            )
        )
    column_sets = {table_name: _columns(table_name) for table_name in TABLES}
    if all(
        "source_record_id" in columns and "payload" not in columns
        for columns in column_sets.values()
    ):
        return
    if any(
        "source_record_id" in columns or "payload" not in columns
        for columns in column_sets.values()
    ):
        raise RuntimeError("Catalog payload migration is in an unexpected partial state.")

    for table_name in TABLES:
        op.add_column(
            table_name,
            sa.Column("source_record_id", sa.Integer(), nullable=True),
        )
        op.create_index(
            _index_name(table_name),
            table_name,
            ["source_record_id"],
            unique=False,
        )

    _backfill_source_record_ids()

    for table_name in TABLES:
        with op.batch_alter_table(table_name) as batch_op:
            batch_op.create_foreign_key(
                _foreign_key_name(table_name),
                "source_records",
                ["source_record_id"],
                ["id"],
                ondelete="CASCADE",
            )
            batch_op.alter_column(
                "source_record_id",
                existing_type=sa.Integer(),
                nullable=False,
            )
            batch_op.drop_column("payload")


def downgrade() -> None:
    payload_type = sa.JSON().with_variant(postgresql.JSONB(), "postgresql")
    for table_name in TABLES:
        columns = _columns(table_name)
        if "payload" not in columns:
            op.add_column(
                table_name,
                sa.Column("payload", payload_type, nullable=True),
            )
            op.execute(
                sa.text(
                    f"""
                    UPDATE {table_name}
                    SET payload = (
                        SELECT source_records.payload
                        FROM source_records
                        WHERE source_records.id = {table_name}.source_record_id
                    )
                    """
                )
            )
        op.drop_index(_index_name(table_name), table_name=table_name)
        with op.batch_alter_table(table_name) as batch_op:
            batch_op.drop_constraint(
                _foreign_key_name(table_name),
                type_="foreignkey",
            )
            batch_op.drop_column("source_record_id")
            batch_op.alter_column(
                "payload",
                existing_type=payload_type,
                nullable=False,
            )
