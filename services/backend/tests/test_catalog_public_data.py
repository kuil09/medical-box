import json
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from types import ModuleType

import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations

from medical_box_api.catalog.public_data import (
    fields_for_source,
    public_source_data,
)
from medical_box_api.catalog.sources import SourceDefinition
from medical_box_api.models import SourceRecord

MIGRATION_PATH = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "20260729_0008_compact_catalog_public_data.py"
)


def source(code: str, kind: str) -> SourceDefinition:
    return SourceDefinition(
        code=code,
        name=code,
        portal_url="https://example.com",
        api_url="https://example.com/api",
        record_key_fields=("id",),
        kind=kind,
        license_name="Test license",
        attribution="Test source",
    )


def load_migration() -> ModuleType:
    spec = spec_from_file_location("compact_catalog_public_data", MIGRATION_PATH)
    assert spec is not None
    assert spec.loader is not None
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_migration(connection: sa.Connection, operation: str) -> None:
    migration = load_migration()
    context = MigrationContext.configure(connection)
    with Operations.context(context):
        getattr(migration, operation)()


def test_public_source_data_keeps_only_runtime_fields() -> None:
    dur = source("mfds_dur_product_age", "dur")
    payload = {
        "TYPE_NAME": "Age contraindication",
        "PROHBT_CONTENT": "Public explanation",
        "UPDATE_DATE": "20260729",
        "ITEM_NAME": "Already normalized",
        "SECRET_INTERNAL_FIELD": "discard",
    }

    assert public_source_data(dur, payload) == {
        "TYPE_NAME": "Age contraindication",
        "PROHBT_CONTENT": "Public explanation",
        "UPDATE_DATE": "20260729",
    }


def test_public_source_data_matches_keys_case_insensitively() -> None:
    code = source("hira_standard_code", "code")

    assert public_source_data(
        code,
        {
            "insurancecode": "A123",
            "update_date": "20260729",
            "itemSeq": "discarded-normalized-identity",
        },
    ) == {
        "insurancecode": "A123",
        "update_date": "20260729",
    }


def test_product_payload_is_not_retained_after_normalization() -> None:
    product = source("mfds_product", "product_catalog")

    assert fields_for_source(product) == frozenset()
    assert public_source_data(
        product,
        {"ITEM_SEQ": "1", "ITEM_NAME": "Example medicine"},
    ) == {}


def test_migration_allowlist_matches_runtime_allowlist() -> None:
    migration = load_migration()
    source_kinds = (
        (
            source("mfds_dur_product_age", "dur"),
            migration.DUR_PUBLIC_FIELDS,
        ),
        (
            source("mfds_pill", "identification"),
            migration.IDENTIFICATION_PUBLIC_FIELDS,
        ),
        (
            source("mfds_recall", "status_recall"),
            migration.STATUS_PUBLIC_FIELDS,
        ),
        (
            source("hira_price", "price"),
            migration.PRICE_PUBLIC_FIELDS,
        ),
        (
            source("hira_standard_code", "code"),
            migration.CODE_PUBLIC_FIELDS,
        ),
    )

    for source_definition, migration_fields in source_kinds:
        assert {
            field.casefold()
            for field in fields_for_source(source_definition)
        } == {field.casefold() for field in migration_fields}


def test_source_record_uses_compatible_physical_payload_column() -> None:
    assert hasattr(SourceRecord, "public_data")
    assert not hasattr(SourceRecord, "payload")
    assert SourceRecord.__table__.c.payload.key == "payload"
    assert SourceRecord.__table__.c.payload.name == "payload"


def test_sqlite_migration_discards_non_public_fields(tmp_path: Path) -> None:
    engine = sa.create_engine(f"sqlite+pysqlite:///{tmp_path / 'public-data.db'}")
    metadata = sa.MetaData()
    source_records = sa.Table(
        "source_records",
        metadata,
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("source_code", sa.String(length=80), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
    )
    rows = [
        {
            "id": 1,
            "source_code": "mfds_product",
            "payload": {"ITEM_SEQ": "1", "ITEM_NAME": "Discarded"},
        },
        {
            "id": 2,
            "source_code": "mfds_dur_product_age",
            "payload": {
                "TYPE_NAME": "Age contraindication",
                "PROHBT_CONTENT": "Retained",
                "ITEM_NAME": "Discarded",
            },
        },
        {
            "id": 3,
            "source_code": "mfds_pill",
            "payload": {
                "ITEM_IMAGE": "https://example.com/pill.png",
                "ITEM_NAME": "Discarded",
            },
        },
        {
            "id": 4,
            "source_code": "mfds_recall",
            "payload": {
                "RTRVL_RESN": "Retained recall reason",
                "ITEM_NAME": "Discarded",
            },
        },
        {
            "id": 5,
            "source_code": "hira_standard_code",
            "payload": {
                "제품코드(개정후)": "A123",
                "품목명": "Discarded",
            },
        },
    ]

    with engine.begin() as connection:
        metadata.create_all(connection)
        connection.execute(source_records.insert(), rows)
        run_migration(connection, "upgrade")

        compact_rows = connection.execute(
            sa.text(
                "SELECT id, payload FROM source_records ORDER BY id"
            )
        ).all()
        assert [
            (row.id, json.loads(row.payload)) for row in compact_rows
        ] == [
            (1, {}),
            (
                2,
                {
                    "TYPE_NAME": "Age contraindication",
                    "PROHBT_CONTENT": "Retained",
                },
            ),
            (3, {"ITEM_IMAGE": "https://example.com/pill.png"}),
            (4, {"RTRVL_RESN": "Retained recall reason"}),
            (5, {"제품코드(개정후)": "A123"}),
        ]

        run_migration(connection, "downgrade")
        assert connection.scalar(
            sa.text("SELECT payload FROM source_records WHERE id = 1")
        ) == "{}"
