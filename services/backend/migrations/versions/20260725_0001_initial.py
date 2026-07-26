"""Create the initial account and medicine catalog schema."""

from alembic import op

from medical_box_api import models  # noqa: F401
from medical_box_api.db import Base

revision = "20260725_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    Base.metadata.create_all(bind=op.get_bind())


def downgrade() -> None:
    Base.metadata.drop_all(bind=op.get_bind())
