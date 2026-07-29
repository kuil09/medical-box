from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType, SimpleNamespace

import sqlalchemy as sa

MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "20260730_0009_dur_counterpart_item_seq.py"
)


def load_migration() -> ModuleType:
    spec = spec_from_file_location("dur_counterpart_item_seq", MIGRATION_PATH)
    assert spec is not None
    assert spec.loader is not None
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_postgresql_upgrade_indexes_and_backfills_counterpart(
    monkeypatch,
) -> None:
    migration = load_migration()
    added_columns: list[tuple[str, sa.Column]] = []
    indexes: list[tuple[str, str, list[str], bool]] = []
    statements: list[str] = []

    monkeypatch.setattr(
        migration.op,
        "add_column",
        lambda table, column: added_columns.append((table, column)),
    )
    monkeypatch.setattr(
        migration.op,
        "create_index",
        lambda name, table, columns, unique: indexes.append((name, table, columns, unique)),
    )
    monkeypatch.setattr(
        migration.op,
        "get_bind",
        lambda: SimpleNamespace(dialect=SimpleNamespace(name="postgresql")),
    )
    monkeypatch.setattr(
        migration.sa,
        "inspect",
        lambda _bind: SimpleNamespace(
            get_columns=lambda _table: [],
            get_indexes=lambda _table: [],
        ),
    )
    monkeypatch.setattr(
        migration.op,
        "execute",
        lambda statement: statements.append(str(statement)),
    )

    migration.upgrade()

    assert added_columns[0][0] == "dur_rules"
    assert added_columns[0][1].name == "counterpart_item_seq"
    assert indexes == [
        (
            "ix_dur_rules_counterpart_item_seq",
            "dur_rules",
            ["counterpart_item_seq"],
            False,
        )
    ]
    assert len(statements) == 1
    assert "record.payload" in statements[0]
    assert "record.public_data" not in statements[0]
    assert "MIXTURE_ITEM_SEQ" in statements[0]
    assert "mixtureItemSeq" in statements[0]
    assert "concomitant_contraindication" in statements[0]


def test_upgrade_reuses_column_and_index_created_by_initial_metadata(
    monkeypatch,
) -> None:
    migration = load_migration()
    added_columns: list[tuple[str, sa.Column]] = []
    indexes: list[tuple[str, str, list[str], bool]] = []

    monkeypatch.setattr(
        migration.op,
        "get_bind",
        lambda: SimpleNamespace(dialect=SimpleNamespace(name="sqlite")),
    )
    monkeypatch.setattr(
        migration.sa,
        "inspect",
        lambda _bind: SimpleNamespace(
            get_columns=lambda _table: [{"name": "counterpart_item_seq"}],
            get_indexes=lambda _table: [{"name": "ix_dur_rules_counterpart_item_seq"}],
        ),
    )
    monkeypatch.setattr(
        migration.op,
        "add_column",
        lambda table, column: added_columns.append((table, column)),
    )
    monkeypatch.setattr(
        migration.op,
        "create_index",
        lambda name, table, columns, unique: indexes.append(
            (name, table, columns, unique)
        ),
    )

    migration.upgrade()

    assert added_columns == []
    assert indexes == []
