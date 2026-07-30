from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType, SimpleNamespace

import sqlalchemy as sa

MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "20260730_0010_catalog_access_by_default.py"
)


def load_migration() -> ModuleType:
    spec = spec_from_file_location("catalog_access_by_default", MIGRATION_PATH)
    assert spec is not None
    assert spec.loader is not None
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_postgresql_upgrade_grants_existing_accounts_and_changes_default(
    monkeypatch,
) -> None:
    migration = load_migration()
    statements: list[str] = []
    alterations: list[tuple[str, str, object]] = []

    monkeypatch.setattr(
        migration.op,
        "get_bind",
        lambda: SimpleNamespace(dialect=SimpleNamespace(name="postgresql")),
    )
    monkeypatch.setattr(
        migration.sa,
        "inspect",
        lambda _bind: SimpleNamespace(
            get_columns=lambda _table: [{"name": "catalog_read_enabled"}]
        ),
    )
    monkeypatch.setattr(
        migration.op,
        "execute",
        lambda statement: statements.append(str(statement)),
    )
    monkeypatch.setattr(
        migration.op,
        "alter_column",
        lambda table, column, **kwargs: alterations.append(
            (table, column, kwargs["server_default"])
        ),
    )

    migration.upgrade()

    assert len(statements) == 1
    assert "SET catalog_read_enabled = true" in statements[0]
    assert alterations[0][:2] == ("users", "catalog_read_enabled")
    assert isinstance(alterations[0][2], sa.sql.elements.True_)


def test_sqlite_upgrade_backfills_without_unsupported_default_alteration(
    monkeypatch,
) -> None:
    migration = load_migration()
    statements: list[str] = []
    alterations: list[tuple[object, ...]] = []

    monkeypatch.setattr(
        migration.op,
        "get_bind",
        lambda: SimpleNamespace(dialect=SimpleNamespace(name="sqlite")),
    )
    monkeypatch.setattr(
        migration.sa,
        "inspect",
        lambda _bind: SimpleNamespace(
            get_columns=lambda _table: [{"name": "catalog_read_enabled"}]
        ),
    )
    monkeypatch.setattr(
        migration.op,
        "execute",
        lambda statement: statements.append(str(statement)),
    )
    monkeypatch.setattr(
        migration.op,
        "alter_column",
        lambda *args, **kwargs: alterations.append((*args, kwargs)),
    )

    migration.upgrade()

    assert len(statements) == 1
    assert alterations == []
