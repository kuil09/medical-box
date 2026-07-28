"""Compact catalog identity indexes on PostgreSQL."""

import sqlalchemy as sa
from alembic import op

revision = "20260729_0007"
down_revision = "20260728_0006"
branch_labels = None
depends_on = None

SOURCE_RECORDS_TABLE = "source_records"
DRUG_CODES_TABLE = "drug_codes"
HASH_FUNCTION = "catalog_identity_hash"
SOURCE_RECORDS_HASH_INDEX = "ux_source_records_identity_hash"
SOURCE_RECORDS_NATURAL_KEY = "source_records_source_code_record_key_key"
SOURCE_RECORDS_ACTIVE_INDEX = "ix_source_records_active"
SOURCE_RECORDS_BRIN_INDEX = "ix_source_records_source_code_brin"
SOURCE_RECORDS_LAST_SEEN_INDEX = "ix_source_records_last_seen_run_id"
DRUG_CODES_HASH_INDEX = "ux_drug_codes_identity_hash"
DRUG_CODES_NATURAL_KEY = "drug_codes_code_type_code_key"


def _upgrade_postgresql() -> None:
    # A distinct 64-bit collision intentionally fails index creation or a later
    # insert. Callers also retain exact string predicates, so a digest is never
    # treated as the catalog identity by itself.
    op.execute(
        sa.text(
            f"""
            CREATE FUNCTION {HASH_FUNCTION}(text, text)
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
    op.execute(
        sa.text(
            f"""
            CREATE UNIQUE INDEX {SOURCE_RECORDS_HASH_INDEX}
            ON {SOURCE_RECORDS_TABLE} (
                {HASH_FUNCTION}(source_code, record_key)
            )
            """
        )
    )
    op.execute(
        sa.text(
            f"""
            CREATE UNIQUE INDEX {DRUG_CODES_HASH_INDEX}
            ON {DRUG_CODES_TABLE} (
                {HASH_FUNCTION}(code_type, code)
            )
            """
        )
    )
    op.create_index(
        SOURCE_RECORDS_BRIN_INDEX,
        SOURCE_RECORDS_TABLE,
        ["source_code"],
        unique=False,
        postgresql_using="brin",
        postgresql_with={"pages_per_range": "32"},
    )
    op.drop_constraint(
        SOURCE_RECORDS_NATURAL_KEY,
        SOURCE_RECORDS_TABLE,
        type_="unique",
    )
    op.drop_constraint(
        DRUG_CODES_NATURAL_KEY,
        DRUG_CODES_TABLE,
        type_="unique",
    )
    op.drop_index(
        SOURCE_RECORDS_ACTIVE_INDEX,
        table_name=SOURCE_RECORDS_TABLE,
    )
    op.drop_index(
        SOURCE_RECORDS_LAST_SEEN_INDEX,
        table_name=SOURCE_RECORDS_TABLE,
    )


def upgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        _upgrade_postgresql()


def _downgrade_postgresql() -> None:
    op.create_unique_constraint(
        SOURCE_RECORDS_NATURAL_KEY,
        SOURCE_RECORDS_TABLE,
        ["source_code", "record_key"],
    )
    op.create_unique_constraint(
        DRUG_CODES_NATURAL_KEY,
        DRUG_CODES_TABLE,
        ["code_type", "code"],
    )
    op.create_index(
        SOURCE_RECORDS_ACTIVE_INDEX,
        SOURCE_RECORDS_TABLE,
        ["source_code", "active"],
        unique=False,
    )
    op.create_index(
        SOURCE_RECORDS_LAST_SEEN_INDEX,
        SOURCE_RECORDS_TABLE,
        ["last_seen_run_id"],
        unique=False,
    )
    op.drop_index(
        SOURCE_RECORDS_BRIN_INDEX,
        table_name=SOURCE_RECORDS_TABLE,
    )
    op.drop_index(
        SOURCE_RECORDS_HASH_INDEX,
        table_name=SOURCE_RECORDS_TABLE,
    )
    op.drop_index(
        DRUG_CODES_HASH_INDEX,
        table_name=DRUG_CODES_TABLE,
    )
    op.execute(sa.text(f"DROP FUNCTION {HASH_FUNCTION}(text, text)"))


def downgrade() -> None:
    if op.get_bind().dialect.name == "postgresql":
        _downgrade_postgresql()
