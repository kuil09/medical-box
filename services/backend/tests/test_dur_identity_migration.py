from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType

import pytest
import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations

MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "20260728_0006_compact_dur_identity.py"
)


def load_migration() -> ModuleType:
    spec = spec_from_file_location("compact_dur_identity", MIGRATION_PATH)
    assert spec is not None
    assert spec.loader is not None
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def create_legacy_schema(
    connection: sa.Connection,
    *,
    duplicate_source_record: bool = False,
) -> None:
    metadata = sa.MetaData()
    source_records = sa.Table(
        "source_records",
        metadata,
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("source_code", sa.String(length=80), nullable=False),
        sa.Column("record_key", sa.String(length=255), nullable=False),
    )
    dur_rules = sa.Table(
        "dur_rules",
        metadata,
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "source_record_id",
            sa.Integer(),
            sa.ForeignKey("source_records.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("item_seq", sa.String(length=40)),
        sa.Column("source_code", sa.String(length=80), nullable=False),
        sa.Column("rule_key", sa.String(length=255), nullable=False),
        sa.Column("rule_type", sa.String(length=120)),
        sa.UniqueConstraint(
            "source_code",
            "rule_key",
            name="dur_rules_source_code_rule_key_key",
        ),
    )
    sa.Index("ix_dur_rules_source_record_id", dur_rules.c.source_record_id)
    metadata.create_all(connection)
    connection.execute(
        source_records.insert(),
        [
            {
                "id": 1,
                "source_code": "mfds_dur_product_age",
                "record_key": "rule-1",
            },
            {
                "id": 2,
                "source_code": "mfds_dur_product_age",
                "record_key": "rule-2",
            },
        ],
    )
    second_source_record_id = 1 if duplicate_source_record else 2
    connection.execute(
        dur_rules.insert(),
        [
            {
                "id": 1,
                "source_record_id": 1,
                "item_seq": "product-1",
                "source_code": "mfds_dur_product_age",
                "rule_key": "rule-1",
                "rule_type": "age_contraindication",
            },
            {
                "id": 2,
                "source_record_id": second_source_record_id,
                "item_seq": "product-2",
                "source_code": "mfds_dur_product_age",
                "rule_key": "rule-2",
                "rule_type": "age_contraindication",
            },
        ],
    )


def run_migration(connection: sa.Connection, operation: str) -> None:
    migration = load_migration()
    context = MigrationContext.configure(connection)
    with Operations.context(context):
        getattr(migration, operation)()


def test_compaction_replaces_natural_identity_with_unique_source_record(
    tmp_path: Path,
) -> None:
    engine = sa.create_engine(f"sqlite+pysqlite:///{tmp_path / 'compact.db'}")
    with engine.begin() as connection:
        create_legacy_schema(connection)
        run_migration(connection, "upgrade")

        inspector = sa.inspect(connection)
        columns = {
            column["name"] for column in inspector.get_columns("dur_rules")
        }
        indexes = {
            index["name"]: index for index in inspector.get_indexes("dur_rules")
        }
        rows = connection.execute(
            sa.text(
                "SELECT id, source_record_id, item_seq, rule_type "
                "FROM dur_rules ORDER BY id"
            )
        ).mappings()

        assert "source_code" not in columns
        assert "rule_key" not in columns
        assert indexes["ix_dur_rules_source_record_id"]["unique"] == 1
        assert [dict(row) for row in rows] == [
            {
                "id": 1,
                "source_record_id": 1,
                "item_seq": "product-1",
                "rule_type": "age_contraindication",
            },
            {
                "id": 2,
                "source_record_id": 2,
                "item_seq": "product-2",
                "rule_type": "age_contraindication",
            },
        ]


def test_compaction_refuses_duplicate_source_record_mappings(
    tmp_path: Path,
) -> None:
    engine = sa.create_engine(f"sqlite+pysqlite:///{tmp_path / 'duplicate.db'}")
    with engine.begin() as connection:
        create_legacy_schema(connection, duplicate_source_record=True)

        with pytest.raises(
            RuntimeError,
            match="1 duplicate source record mappings",
        ):
            run_migration(connection, "upgrade")

        columns = {
            column["name"]
            for column in sa.inspect(connection).get_columns("dur_rules")
        }
        assert {"source_code", "rule_key"}.issubset(columns)


def test_compaction_downgrade_restores_source_identity(
    tmp_path: Path,
) -> None:
    engine = sa.create_engine(f"sqlite+pysqlite:///{tmp_path / 'downgrade.db'}")
    with engine.begin() as connection:
        create_legacy_schema(connection)
        run_migration(connection, "upgrade")
        run_migration(connection, "downgrade")

        rows = connection.execute(
            sa.text(
                "SELECT source_code, rule_key "
                "FROM dur_rules ORDER BY id"
            )
        ).mappings()
        indexes = {
            index["name"]: index
            for index in sa.inspect(connection).get_indexes("dur_rules")
        }

        assert [dict(row) for row in rows] == [
            {
                "source_code": "mfds_dur_product_age",
                "rule_key": "rule-1",
            },
            {
                "source_code": "mfds_dur_product_age",
                "rule_key": "rule-2",
            },
        ]
        assert indexes["ix_dur_rules_source_record_id"]["unique"] == 0
