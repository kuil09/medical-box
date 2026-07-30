"""Grant catalog access to registered accounts by default."""

import sqlalchemy as sa
from alembic import op

revision = "20260730_0010"
down_revision = "20260730_0009"
branch_labels = None
depends_on = None

TABLE = "users"
COLUMN = "catalog_read_enabled"


def upgrade() -> None:
    bind = op.get_bind()
    columns = {column["name"] for column in sa.inspect(bind).get_columns(TABLE)}
    if COLUMN not in columns:
        return

    op.execute(
        sa.text(
            """
            UPDATE users
            SET catalog_read_enabled = true
            WHERE catalog_read_enabled = false
            """
        )
    )
    if bind.dialect.name == "postgresql":
        op.alter_column(
            TABLE,
            COLUMN,
            existing_type=sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        )


def downgrade() -> None:
    bind = op.get_bind()
    columns = {column["name"] for column in sa.inspect(bind).get_columns(TABLE)}
    if COLUMN not in columns or bind.dialect.name != "postgresql":
        return
    op.alter_column(
        TABLE,
        COLUMN,
        existing_type=sa.Boolean(),
        nullable=False,
        server_default=sa.false(),
    )
