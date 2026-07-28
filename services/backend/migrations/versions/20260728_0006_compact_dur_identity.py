"""Reference DUR source identity through the raw record only."""

import sqlalchemy as sa
from alembic import op

revision = "20260728_0006"
down_revision = "20260728_0005"
branch_labels = None
depends_on = None

TABLE_NAME = "dur_rules"
SOURCE_RECORD_INDEX = "ix_dur_rules_source_record_id"
TEMPORARY_UNIQUE_INDEX = "ux_dur_rules_source_record_id_compaction"
NATURAL_KEY_CONSTRAINT = "dur_rules_source_code_rule_key_key"


def _columns() -> set[str]:
    return {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns(TABLE_NAME)
    }


def _indexes() -> dict[str, dict[str, object]]:
    return {
        index["name"]: index
        for index in sa.inspect(op.get_bind()).get_indexes(TABLE_NAME)
        if index.get("name")
    }


def _duplicate_source_records() -> int:
    return int(
        op.get_bind().scalar(
            sa.text(
                """
                SELECT COUNT(*)
                FROM (
                    SELECT source_record_id
                    FROM dur_rules
                    GROUP BY source_record_id
                    HAVING COUNT(*) > 1
                ) AS duplicate_source_records
                """
            )
        )
        or 0
    )


def _upgrade_postgresql() -> None:
    op.create_index(
        TEMPORARY_UNIQUE_INDEX,
        TABLE_NAME,
        ["source_record_id"],
        unique=True,
    )
    op.drop_constraint(
        NATURAL_KEY_CONSTRAINT,
        TABLE_NAME,
        type_="unique",
    )
    op.drop_index(SOURCE_RECORD_INDEX, table_name=TABLE_NAME)
    op.execute(
        sa.text(
            f'ALTER INDEX "{TEMPORARY_UNIQUE_INDEX}" '
            f'RENAME TO "{SOURCE_RECORD_INDEX}"'
        )
    )
    op.drop_column(TABLE_NAME, "source_code")
    op.drop_column(TABLE_NAME, "rule_key")


def _upgrade_sqlite() -> None:
    with op.batch_alter_table(TABLE_NAME, recreate="always") as batch_op:
        batch_op.drop_constraint(
            NATURAL_KEY_CONSTRAINT,
            type_="unique",
        )
        batch_op.drop_index(SOURCE_RECORD_INDEX)
        batch_op.drop_column("source_code")
        batch_op.drop_column("rule_key")
        batch_op.create_index(
            SOURCE_RECORD_INDEX,
            ["source_record_id"],
            unique=True,
        )


def upgrade() -> None:
    columns = _columns()
    indexes = _indexes()
    identity_columns = {"source_code", "rule_key"}
    source_record_index = indexes.get(SOURCE_RECORD_INDEX)
    already_compact = not (identity_columns & columns) and bool(
        source_record_index and source_record_index.get("unique")
    )
    if already_compact:
        return
    if not identity_columns.issubset(columns):
        raise RuntimeError("DUR identity compaction is in an unexpected partial state.")
    duplicate_count = _duplicate_source_records()
    if duplicate_count:
        raise RuntimeError(
            "DUR identity compaction found "
            f"{duplicate_count} duplicate source record mappings."
        )
    if op.get_bind().dialect.name == "postgresql":
        _upgrade_postgresql()
    else:
        _upgrade_sqlite()


def _downgrade_postgresql() -> None:
    op.add_column(
        TABLE_NAME,
        sa.Column("source_code", sa.String(length=80), nullable=True),
    )
    op.add_column(
        TABLE_NAME,
        sa.Column("rule_key", sa.String(length=255), nullable=True),
    )
    op.execute(
        sa.text(
            """
            UPDATE dur_rules
            SET source_code = source_records.source_code,
                rule_key = source_records.record_key
            FROM source_records
            WHERE source_records.id = dur_rules.source_record_id
            """
        )
    )
    op.alter_column(TABLE_NAME, "source_code", nullable=False)
    op.alter_column(TABLE_NAME, "rule_key", nullable=False)
    op.create_unique_constraint(
        NATURAL_KEY_CONSTRAINT,
        TABLE_NAME,
        ["source_code", "rule_key"],
    )
    op.drop_index(SOURCE_RECORD_INDEX, table_name=TABLE_NAME)
    op.create_index(
        SOURCE_RECORD_INDEX,
        TABLE_NAME,
        ["source_record_id"],
        unique=False,
    )


def _downgrade_sqlite() -> None:
    op.add_column(
        TABLE_NAME,
        sa.Column("source_code", sa.String(length=80), nullable=True),
    )
    op.add_column(
        TABLE_NAME,
        sa.Column("rule_key", sa.String(length=255), nullable=True),
    )
    op.execute(
        sa.text(
            """
            UPDATE dur_rules
            SET source_code = (
                    SELECT source_records.source_code
                    FROM source_records
                    WHERE source_records.id = dur_rules.source_record_id
                ),
                rule_key = (
                    SELECT source_records.record_key
                    FROM source_records
                    WHERE source_records.id = dur_rules.source_record_id
                )
            """
        )
    )
    with op.batch_alter_table(TABLE_NAME, recreate="always") as batch_op:
        batch_op.drop_index(SOURCE_RECORD_INDEX)
        batch_op.alter_column(
            "source_code",
            existing_type=sa.String(length=80),
            nullable=False,
        )
        batch_op.alter_column(
            "rule_key",
            existing_type=sa.String(length=255),
            nullable=False,
        )
        batch_op.create_unique_constraint(
            NATURAL_KEY_CONSTRAINT,
            ["source_code", "rule_key"],
        )
        batch_op.create_index(
            SOURCE_RECORD_INDEX,
            ["source_record_id"],
            unique=False,
        )


def downgrade() -> None:
    columns = _columns()
    if {"source_code", "rule_key"}.issubset(columns):
        return
    if op.get_bind().dialect.name == "postgresql":
        _downgrade_postgresql()
    else:
        _downgrade_sqlite()
