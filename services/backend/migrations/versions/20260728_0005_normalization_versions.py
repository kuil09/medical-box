"""Version catalog normalization checkpoints."""

import sqlalchemy as sa
from alembic import op

revision = "20260728_0005"
down_revision = "20260726_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    columns = {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns("sync_checkpoints")
    }
    if "normalization_version" not in columns:
        op.add_column(
            "sync_checkpoints",
            sa.Column(
                "normalization_version",
                sa.Integer(),
                nullable=False,
                server_default="1",
            ),
        )


def downgrade() -> None:
    columns = {
        column["name"]
        for column in sa.inspect(op.get_bind()).get_columns("sync_checkpoints")
    }
    if "normalization_version" in columns:
        op.drop_column("sync_checkpoints", "normalization_version")
