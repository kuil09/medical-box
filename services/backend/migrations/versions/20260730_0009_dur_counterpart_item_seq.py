"""Index the counterpart product in concomitant DUR rules."""

import sqlalchemy as sa
from alembic import op

revision = "20260730_0009"
down_revision = "20260729_0008"
branch_labels = None
depends_on = None

TABLE = "dur_rules"
INDEX = "ix_dur_rules_counterpart_item_seq"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    column_names = {column["name"] for column in inspector.get_columns(TABLE)}
    if "counterpart_item_seq" not in column_names:
        op.add_column(
            TABLE,
            sa.Column("counterpart_item_seq", sa.String(length=40), nullable=True),
        )

    index_names = {index["name"] for index in inspector.get_indexes(TABLE)}
    if INDEX not in index_names:
        op.create_index(INDEX, TABLE, ["counterpart_item_seq"], unique=False)

    if bind.dialect.name == "postgresql":
        op.execute(
            sa.text(
                """
                UPDATE dur_rules AS rule
                SET counterpart_item_seq = NULLIF(
                    btrim(
                        COALESCE(
                            record.payload ->> 'MIXTURE_ITEM_SEQ',
                            record.payload ->> 'mixtureItemSeq'
                        )
                    ),
                    ''
                )
                FROM source_records AS record
                WHERE record.id = rule.source_record_id
                  AND rule.rule_type = 'concomitant_contraindication'
                """
            )
        )


def downgrade() -> None:
    inspector = sa.inspect(op.get_bind())
    index_names = {index["name"] for index in inspector.get_indexes(TABLE)}
    if INDEX in index_names:
        op.drop_index(INDEX, table_name=TABLE)

    column_names = {column["name"] for column in inspector.get_columns(TABLE)}
    if "counterpart_item_seq" in column_names:
        op.drop_column(TABLE, "counterpart_item_seq")
