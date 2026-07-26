"""Add explicit catalog read entitlement to accounts."""

import sqlalchemy as sa
from alembic import op

revision = "20260726_0003"
down_revision = "20260726_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    user_columns = {
        column["name"] for column in sa.inspect(op.get_bind()).get_columns("users")
    }
    if "catalog_read_enabled" in user_columns:
        return
    op.add_column(
        "users",
        sa.Column(
            "catalog_read_enabled",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "catalog_read_enabled")
