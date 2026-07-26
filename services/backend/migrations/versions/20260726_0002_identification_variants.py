"""Preserve multiple pill-identification variants per product."""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "20260726_0002"
down_revision = "20260725_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    if sa.inspect(op.get_bind()).has_table("drug_identification_variants"):
        return
    payload_type = sa.JSON().with_variant(postgresql.JSONB(), "postgresql")
    op.create_table(
        "drug_identification_variants",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("item_seq", sa.String(length=40), nullable=False),
        sa.Column("source_code", sa.String(length=80), nullable=False),
        sa.Column("variant_key", sa.String(length=255), nullable=False),
        sa.Column("shape", sa.String(length=120), nullable=True),
        sa.Column("color", sa.String(length=120), nullable=True),
        sa.Column("imprint_front", sa.String(length=180), nullable=True),
        sa.Column("imprint_back", sa.String(length=180), nullable=True),
        sa.Column("image_url", sa.String(length=1000), nullable=True),
        sa.Column("payload", payload_type, nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("source_code", "variant_key"),
    )
    op.create_index(
        "ix_drug_identification_variants_item_seq",
        "drug_identification_variants",
        ["item_seq"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_drug_identification_variants_item_seq",
        table_name="drug_identification_variants",
    )
    op.drop_table("drug_identification_variants")
