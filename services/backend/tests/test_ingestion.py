from collections.abc import Iterator
from dataclasses import replace
from io import BytesIO

import httpx
import pytest
from openpyxl import Workbook
from sqlalchemy import event, func, select

from medical_box_api.catalog.fetcher import PublicDataFetcher, SourceResponseError
from medical_box_api.catalog.sources import SourceDefinition, official_sources
from medical_box_api.catalog.sync import (
    canonical_hash,
    ingredient_rows,
    item_seq,
    record_key,
    sync_source,
)
from medical_box_api.config import Settings
from medical_box_api.db import Base, SessionLocal, engine
from medical_box_api.models import (
    DrugCode,
    DrugConsumerInfo,
    DrugIdentification,
    DrugIdentificationVariant,
    DrugIngredient,
    DrugProduct,
    DurRule,
    SourceRecord,
    SyncRun,
)


def source() -> SourceDefinition:
    return SourceDefinition(
        code="test",
        name="Test",
        portal_url="https://example.com",
        api_url="https://example.com/api",
        record_key_fields=("itemSeq",),
        kind="product",
        license_name="Test",
        attribution="Test",
    )


def reset_database() -> None:
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)


class RecordFetcher(PublicDataFetcher):
    def __init__(self, records: list[dict[str, object]]) -> None:
        super().__init__("test")
        self.records = records

    def pages(
        self,
        source: SourceDefinition,
    ) -> Iterator[tuple[int, list[dict[str, object]], int]]:
        yield 1, self.records, len(self.records)


def test_record_identity_and_hash_are_stable() -> None:
    payload = {"itemName": "효소제", "itemSeq": "123", "entpName": "테스트"}
    reordered = {"entpName": "테스트", "itemSeq": "123", "itemName": "효소제"}
    assert record_key(source(), payload) == "123"
    assert item_seq(payload) == "123"
    assert canonical_hash(payload) == canonical_hash(reordered)

    composite_source = replace(
        source(),
        composite_key_fields=("ITEM_SEQ", "MTRAL_SN"),
    )
    assert record_key(
        composite_source,
        {"ITEM_SEQ": "123", "MTRAL_SN": "4"},
    ) == "123|4"
    assert record_key(
        composite_source,
        {"ITEM_SEQ": "123"},
    ).startswith("123|missing|")

    hash_source = replace(
        composite_source,
        hash_record_key=True,
    )
    first_variant = {"ITEM_SEQ": "123", "MTRAL_SN": "4", "value": "first"}
    second_variant = {"ITEM_SEQ": "123", "MTRAL_SN": "4", "value": "second"}
    assert record_key(hash_source, first_variant) == record_key(
        hash_source,
        first_variant,
    )
    assert record_key(hash_source, first_variant) != record_key(
        hash_source,
        second_variant,
    )


def test_response_shapes_are_normalized() -> None:
    items, total = PublicDataFetcher._extract_items(
        {
            "response": {
                "header": {"resultCode": "00"},
                "body": {
                    "items": {"item": [{"itemSeq": "1"}, {"itemSeq": "2"}]},
                    "totalCount": 2,
                },
            }
        }
    )
    assert total == 2
    assert [item["itemSeq"] for item in items] == ["1", "2"]

    nested_items, nested_total = PublicDataFetcher._extract_items(
        {
            "response": {
                "body": {
                    "items": {
                        "item": {
                            "item": [
                                {"item": {"DUR_SEQ": "DUR-1"}},
                                {"item": {"DUR_SEQ": "DUR-2"}},
                            ]
                        }
                    },
                    "totalCount": 2,
                }
            }
        }
    )
    assert nested_total == 2
    assert [item["DUR_SEQ"] for item in nested_items] == ["DUR-1", "DUR-2"]

    with pytest.raises(SourceResponseError, match="missing the items field"):
        PublicDataFetcher._extract_items({"response": {"body": {"records": []}}})


def test_pagination_rejects_missing_pages_and_changing_totals() -> None:
    class MissingPageFetcher(PublicDataFetcher):
        def _get_json(self, url: str, page: int) -> dict[str, object]:
            if page == 1:
                return {"body": {"items": [{"itemSeq": "1"}], "totalCount": 3}}
            return {"body": {"items": [], "totalCount": 3}}

    with pytest.raises(SourceResponseError, match="ended at page"):
        list(MissingPageFetcher("test", page_size=1).pages(source()))

    class ChangingTotalFetcher(PublicDataFetcher):
        def _get_json(self, url: str, page: int) -> dict[str, object]:
            total = 3 if page == 1 else 4
            return {
                "body": {
                    "items": [{"itemSeq": str(page)}],
                    "totalCount": total,
                }
            }

    with pytest.raises(SourceResponseError, match="total changed"):
        list(ChangingTotalFetcher("test", page_size=1).pages(source()))


def test_transient_http_failures_are_retried(monkeypatch: pytest.MonkeyPatch) -> None:
    calls = 0

    def fake_get(
        url: str,
        *,
        params: dict[str, object],
        timeout: int,
    ) -> httpx.Response:
        nonlocal calls
        calls += 1
        request = httpx.Request("GET", url, params=params)
        if calls < 3:
            raise httpx.ConnectError("temporary", request=request)
        return httpx.Response(
            200,
            request=request,
            json={"body": {"items": [], "totalCount": 0}},
        )

    monkeypatch.setattr(httpx, "get", fake_get)
    PublicDataFetcher("test")._get_json("https://example.com/api", 1)
    assert calls == 3


def test_unconfigured_source_is_distinct_from_empty_response() -> None:
    disabled = replace(source(), api_url=None)
    assert disabled.api_url is None


def test_all_dur_rule_streams_are_registered() -> None:
    sources = [
        candidate
        for candidate in official_sources(Settings(_env_file=None))
        if candidate.kind == "dur"
    ]
    assert len(sources) == 16
    assert len({candidate.code for candidate in sources}) == 16
    assert all(candidate.api_url and candidate.rule_type for candidate in sources)
    assert {
        candidate.rule_type
        for candidate in sources
        if candidate.code.startswith("mfds_dur_product")
        or candidate.code == "mfds_dur"
    } == {
        "product",
        "concomitant_contraindication",
        "elderly_caution",
        "age_contraindication",
        "dose_caution",
        "duration_caution",
        "efficacy_group_duplication",
        "extended_release_split_caution",
        "pregnancy_contraindication",
    }


def test_dur_stream_assigns_explicit_rule_type() -> None:
    reset_database()
    dur_source = replace(
        source(),
        code="dur-pregnancy",
        kind="dur",
        record_key_fields=("DUR_SEQ",),
        rule_type="pregnancy_contraindication",
    )
    with SessionLocal() as database:
        sync_source(
            database,
            dur_source,
            RecordFetcher(
                [
                    {
                        "DUR_SEQ": "DUR-1",
                        "ITEM_SEQ": "123",
                        "ITEM_NAME": "Test medicine",
                        "TYPE_NAME": "Upstream label",
                    }
                ]
            ),
        )
        rule = database.scalar(select(DurRule))
        assert rule is not None
        assert rule.rule_type == "pregnancy_contraindication"


def test_dur_hash_identity_deduplicates_and_replaces_current_rules() -> None:
    reset_database()
    dur_source = replace(
        source(),
        code="dur-variant",
        kind="dur",
        record_key_fields=("DUR_SEQ",),
        rule_type="pregnancy_contraindication",
        hash_record_key=True,
        allow_identical_duplicates=True,
    )
    first_payload = {
        "DUR_SEQ": "DUR-1",
        "TYPE_NAME": "Pregnancy",
        "PROHBT_CONTENT": "First wording",
    }
    second_payload = {
        "DUR_SEQ": "DUR-1",
        "TYPE_NAME": "Pregnancy",
        "PROHBT_CONTENT": "Updated wording",
    }
    with SessionLocal() as database:
        first_run = sync_source(
            database,
            dur_source,
            RecordFetcher([first_payload, first_payload]),
        )
        assert first_run.record_count == 2
        assert (
            database.scalar(select(func.count()).select_from(SourceRecord)) == 1
        )
        assert database.scalar(select(func.count()).select_from(DurRule)) == 1

        sync_source(database, dur_source, RecordFetcher([second_payload]))
        assert (
            database.scalar(select(func.count()).select_from(SourceRecord)) == 2
        )
        assert (
            database.scalar(
                select(func.count())
                .select_from(SourceRecord)
                .where(SourceRecord.active.is_(True))
            )
            == 1
        )
        rules = database.scalars(select(DurRule)).all()
        assert len(rules) == 1
        assert (
            rules[0].source_record.payload["PROHBT_CONTENT"]
            == "Updated wording"
        )
        assert rules[0].source_record_id is not None


def test_pill_variants_are_preserved_and_representative_is_latest() -> None:
    reset_database()
    pill_source = replace(
        source(),
        code="mfds_pill",
        kind="identification",
        composite_key_fields=("ITEM_SEQ", "ITEM_IMAGE"),
        hash_record_key=True,
        allow_identical_duplicates=True,
    )
    first_payload = {
        "ITEM_SEQ": "123",
        "ITEM_IMAGE": "http://example.test/first.jpg",
        "DRUG_SHAPE": "Round",
        "COLOR_CLASS1": "White",
        "PRINT_FRONT": "A",
        "CHANGE_DATE": "20260101",
    }
    latest_payload = {
        "ITEM_SEQ": "123",
        "ITEM_IMAGE": "http://example.test/latest.jpg",
        "DRUG_SHAPE": "Oval",
        "COLOR_CLASS1": "Blue",
        "PRINT_FRONT": "B",
        "CHANGE_DATE": "20260201",
    }
    with SessionLocal() as database:
        run = sync_source(
            database,
            pill_source,
            RecordFetcher([first_payload, latest_payload, latest_payload]),
        )
        assert run.record_count == 3
        assert (
            database.scalar(
                select(func.count()).select_from(DrugIdentificationVariant)
            )
            == 2
        )
        representative = database.get(DrugIdentification, "123")
        assert representative is not None
        assert representative.color == "Blue"
        assert representative.image_url == "http://example.test/latest.jpg"
        assert representative.source_record_id is not None

        sync_source(database, pill_source, RecordFetcher([first_payload]))
        assert (
            database.scalar(
                select(func.count()).select_from(DrugIdentificationVariant)
            )
            == 1
        )
        representative = database.get(DrugIdentification, "123")
        assert representative is not None
        assert representative.color == "White"


def test_structured_and_flat_ingredients_are_normalized() -> None:
    structured = ingredient_rows(
        {
            "ingredients": [
                {"ingredientName": "Acetaminophen", "amount": "500", "unit": "mg"},
                {"ingredientName": "Caffeine", "amount": "30", "unit": "mg"},
            ]
        }
    )
    assert structured == [
        ("Acetaminophen", "500", "mg"),
        ("Caffeine", "30", "mg"),
    ]

    flat = ingredient_rows({"MATERIAL_NAME": "Acetaminophen|Caffeine\nStarch"})
    assert flat == [
        ("Acetaminophen", None, None),
        ("Caffeine", None, None),
        ("Starch", None, None),
    ]


def test_product_ingredient_records_are_upserted_independently() -> None:
    reset_database()
    ingredient_source = replace(
        source(),
        code="ingredient",
        kind="product_ingredient",
        composite_key_fields=("ITEM_SEQ", "MTRAL_SN"),
    )
    with SessionLocal() as database:
        sync_source(
            database,
            source(),
            RecordFetcher([{"itemSeq": "123", "itemName": "Test medicine"}]),
        )
        sync_source(
            database,
            ingredient_source,
            RecordFetcher(
                [
                    {
                        "ITEM_SEQ": "123",
                        "MTRAL_SN": "1",
                        "MTRAL_NM": "Acetaminophen",
                        "QNT": "500",
                        "INGD_UNIT_CD": "mg",
                    },
                    {
                        "ITEM_SEQ": "123",
                        "MTRAL_SN": "2",
                        "MTRAL_NM": "Caffeine",
                        "QNT": "30",
                        "INGD_UNIT_CD": "mg",
                    },
                    {
                        "ITEM_SEQ": "123",
                        "MTRAL_SN": "3",
                        "MTRAL_NM": "Acetaminophen",
                        "QNT": "650",
                        "INGD_UNIT_CD": "mg",
                    },
                    {
                        "ITEM_SEQ": "999",
                        "MTRAL_SN": "1",
                        "MTRAL_NM": "First historical ingredient",
                    },
                    {
                        "ITEM_SEQ": "999",
                        "MTRAL_SN": "2",
                        "MTRAL_NM": "Second historical ingredient",
                    },
                ]
            ),
        )
        assert database.scalar(select(func.count()).select_from(DrugProduct)) == 2
        ingredients = database.scalars(
            select(DrugIngredient).order_by(DrugIngredient.name)
        ).all()
        assert [(row.name, row.amount, row.unit) for row in ingredients] == [
            ("Acetaminophen", "650", "mg"),
            ("Caffeine", "30", "mg"),
            ("First historical ingredient", None, None),
            ("Second historical ingredient", None, None),
        ]


def test_consumer_image_variants_preserve_raw_records_and_product_metadata() -> None:
    reset_database()
    consumer_source = replace(
        source(),
        code="consumer",
        kind="consumer",
        composite_key_fields=("itemSeq", "itemImage"),
    )
    with SessionLocal() as database:
        sync_source(
            database,
            source(),
            RecordFetcher(
                [
                    {
                        "itemSeq": "123",
                        "itemName": "Test medicine",
                        "status": "Active",
                        "appearance": "Round tablet",
                        "itemImage": "https://example.com/product.jpg",
                    }
                ]
            ),
        )
        sync_source(
            database,
            consumer_source,
            RecordFetcher(
                [
                    {
                        "itemSeq": "123",
                        "itemName": "Test medicine",
                        "itemImage": "https://example.com/consumer.jpg",
                        "efcyQesitm": "Consumer efficacy",
                    },
                    {
                        "itemSeq": "123",
                        "itemName": "Test medicine",
                        "itemImage": None,
                        "efcyQesitm": "Consumer efficacy",
                    },
                ]
            ),
        )

        product = database.get(DrugProduct, "123")
        consumer_info = database.get(DrugConsumerInfo, "123")
        assert product is not None
        assert product.status == "Active"
        assert product.appearance == "Round tablet"
        assert product.image_url == "https://example.com/consumer.jpg"
        assert consumer_info is not None
        assert consumer_info.efficacy == "Consumer efficacy"
        assert (
            database.scalar(
                select(func.count())
                .select_from(SourceRecord)
                .where(SourceRecord.source_code == "consumer")
            )
            == 2
        )


def test_korean_csv_header_and_rows_are_detected() -> None:
    content = (
        "Medicine standard code export\n"
        "표준코드,품목기준코드,품목명\n"
        "8801234567890,123456789,테스트정\n"
    ).encode()
    records = PublicDataFetcher._extract_tabular_records(
        content,
        filename="standard-codes.csv",
        content_type="text/csv",
    )
    assert records == [
        {
            "표준코드": "8801234567890",
            "품목기준코드": "123456789",
            "품목명": "테스트정",
        }
    ]


def test_xlsx_header_and_rows_are_detected() -> None:
    workbook = Workbook()
    sheet = workbook.active
    sheet.append(["Medicine standard code export"])
    sheet.append(["표준코드", "품목기준코드", "품목명"])
    sheet.append(["8801234567890", "123456789", "테스트정"])
    buffer = BytesIO()
    workbook.save(buffer)
    workbook.close()

    records = PublicDataFetcher._extract_tabular_records(
        buffer.getvalue(),
        filename="standard-codes.xlsx",
        content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
    assert records == [
        {
            "표준코드": "8801234567890",
            "품목기준코드": "123456789",
            "품목명": "테스트정",
        }
    ]


def test_unchanged_standard_code_file_is_not_reloaded() -> None:
    class FileFetcher(PublicDataFetcher):
        def tabular_file(
            self,
            source: SourceDefinition,
        ) -> tuple[str, str | None, list[dict[str, object]]]:
            return (
                "a" * 64,
                "Fri, 25 Jul 2026 00:00:00 GMT",
                [
                    {
                        "표준코드": "8801234567890",
                        "품목기준코드": "123456789",
                        "품목명": "테스트정",
                    }
                ],
            )

    reset_database()
    standard_code_source = replace(
        source(),
        kind="code",
        record_key_fields=("표준코드",),
    )
    with SessionLocal() as database:
        first = sync_source(database, standard_code_source, FileFetcher("test"))
        first_seen_run = database.scalar(select(SourceRecord.last_seen_run_id))
        second = sync_source(database, standard_code_source, FileFetcher("test"))

        assert first.status == "succeeded"
        assert second.status == "skipped"
        assert database.scalar(select(func.count()).select_from(DrugCode)) == 1
        assert database.scalar(select(SourceRecord.last_seen_run_id)) == first_seen_run


def test_duplicate_and_missing_record_keys_fail_without_publishing() -> None:
    reset_database()
    with SessionLocal() as database:
        with pytest.raises(RuntimeError, match="Duplicate record key"):
            sync_source(
                database,
                source(),
                RecordFetcher(
                    [
                        {"itemSeq": "1", "itemName": "First"},
                        {"itemSeq": "1", "itemName": "Duplicate"},
                    ]
                ),
            )
        assert database.scalar(select(func.count()).select_from(SourceRecord)) == 0
        latest_status = database.scalar(
            select(SyncRun.status).order_by(SyncRun.started_at.desc())
        )
        assert latest_status == "failed"

        with pytest.raises(RuntimeError, match="Required record key"):
            sync_source(
                database,
                source(),
                RecordFetcher([{"itemName": "Schema changed"}]),
            )
        assert database.scalar(select(func.count()).select_from(DrugProduct)) == 0


def test_partial_failure_and_count_collapse_preserve_last_catalog() -> None:
    class PartialFailureFetcher(RecordFetcher):
        def __init__(self, records: list[dict[str, object]]) -> None:
            super().__init__(records)
            self.page_size = 1

        def pages(
            self,
            source: SourceDefinition,
        ) -> Iterator[tuple[int, list[dict[str, object]], int]]:
            yield 1, self.records, 2
            raise SourceResponseError("second page failed")

    reset_database()
    initial_records = [
        {"itemSeq": str(index), "itemName": f"Medicine {index}"}
        for index in range(100)
    ]
    with SessionLocal() as database:
        sync_source(database, source(), RecordFetcher(initial_records))
        initial_hash = database.scalar(
            select(SourceRecord.content_hash).where(SourceRecord.record_key == "0")
        )

        with pytest.raises(SourceResponseError, match="second page failed"):
            sync_source(
                database,
                source(),
                PartialFailureFetcher(
                    [{"itemSeq": "0", "itemName": "Uncommitted change"}]
                ),
            )
        assert database.get(DrugProduct, "0").item_name == "Medicine 0"
        assert (
            database.scalar(
                select(SourceRecord.content_hash).where(SourceRecord.record_key == "0")
            )
            == initial_hash
        )

        with pytest.raises(RuntimeError, match="Record count collapsed"):
            sync_source(database, source(), RecordFetcher(initial_records[:40]))
        assert database.scalar(select(func.count()).select_from(DrugProduct)) == 100
        assert (
            database.scalar(
                select(func.count())
                .select_from(SourceRecord)
                .where(SourceRecord.active.is_(True))
            )
            == 100
        )


def test_initial_dur_bootstrap_commits_run_gated_batches_and_resumes() -> None:
    class DurBootstrapFetcher(PublicDataFetcher):
        def __init__(self, *, fail_after_page: int | None = None) -> None:
            super().__init__("test", page_size=1)
            self.fail_after_page = fail_after_page

        def pages(
            self,
            source: SourceDefinition,
        ) -> Iterator[tuple[int, list[dict[str, object]], int]]:
            for page in range(1, 12):
                if self.fail_after_page == page:
                    raise SourceResponseError(f"page {page} failed")
                yield (
                    page,
                    [{"DUR_SEQ": f"DUR-{page}", "ITEM_SEQ": str(page)}],
                    11,
                )

    reset_database()
    dur_source = replace(
        source(),
        code="dur-bootstrap",
        kind="dur",
        record_key_fields=("DUR_SEQ",),
        rule_type="concomitant_contraindication",
    )
    with SessionLocal() as database:
        with pytest.raises(SourceResponseError, match="page 11 failed"):
            sync_source(
                database,
                dur_source,
                DurBootstrapFetcher(fail_after_page=11),
            )

        assert (
            database.scalar(select(func.count()).select_from(SourceRecord)) == 10
        )
        assert (
            database.scalar(
                select(func.count())
                .select_from(SourceRecord)
                .where(SourceRecord.active.is_(True))
            )
            == 0
        )

        run = sync_source(database, dur_source, DurBootstrapFetcher())

        assert run.status == "succeeded"
        assert run.record_count == 11
        assert (
            database.scalar(select(func.count()).select_from(SourceRecord)) == 11
        )
        assert (
            database.scalar(
                select(func.count())
                .select_from(SourceRecord)
                .where(SourceRecord.active.is_(True))
            )
            == 0
        )
        assert database.scalar(select(func.count()).select_from(DurRule)) == 11


def test_product_sync_prefetches_each_page_in_one_query() -> None:
    reset_database()
    product_selects = 0

    def count_product_selects(
        connection: object,
        cursor: object,
        statement: str,
        parameters: object,
        context: object,
        executemany: bool,
    ) -> None:
        del connection, cursor, parameters, context, executemany
        nonlocal product_selects
        if "FROM drug_products" in statement:
            product_selects += 1

    event.listen(engine, "before_cursor_execute", count_product_selects)
    try:
        with SessionLocal() as database:
            sync_source(
                database,
                source(),
                RecordFetcher(
                    [
                        {
                            "itemSeq": str(index),
                            "itemName": f"Medicine {index}",
                        }
                        for index in range(50)
                    ]
                ),
            )
    finally:
        event.remove(engine, "before_cursor_execute", count_product_selects)

    assert product_selects == 1


def test_ingredient_sync_prefetches_each_page_in_one_query() -> None:
    reset_database()
    ingredient_source = replace(
        source(),
        code="ingredient-prefetch",
        kind="product_ingredient",
        composite_key_fields=("ITEM_SEQ", "MTRAL_SN"),
    )
    ingredients = [
        {
            "ITEM_SEQ": str(index),
            "MTRAL_SN": "1",
            "MTRAL_NM": f"Ingredient {index}",
        }
        for index in range(50)
    ]

    with SessionLocal() as database:
        sync_source(
            database,
            source(),
            RecordFetcher(
                [
                    {
                        "itemSeq": str(index),
                        "itemName": f"Medicine {index}",
                    }
                    for index in range(50)
                ]
            ),
        )

    ingredient_selects = 0

    def count_ingredient_selects(
        connection: object,
        cursor: object,
        statement: str,
        parameters: object,
        context: object,
        executemany: bool,
    ) -> None:
        del connection, cursor, parameters, context, executemany
        nonlocal ingredient_selects
        if "FROM drug_ingredients" in statement:
            ingredient_selects += 1

    event.listen(engine, "before_cursor_execute", count_ingredient_selects)
    try:
        with SessionLocal() as database:
            sync_source(
                database,
                ingredient_source,
                RecordFetcher(ingredients),
            )
    finally:
        event.remove(engine, "before_cursor_execute", count_ingredient_selects)

    assert ingredient_selects == 1


def test_consumer_and_identification_sync_prefetch_each_page() -> None:
    reset_database()
    products = [
        {
            "itemSeq": str(index),
            "itemName": f"Medicine {index}",
        }
        for index in range(50)
    ]
    with SessionLocal() as database:
        sync_source(database, source(), RecordFetcher(products))

    consumer_selects = 0
    identification_selects = 0

    def count_normalized_selects(
        connection: object,
        cursor: object,
        statement: str,
        parameters: object,
        context: object,
        executemany: bool,
    ) -> None:
        del connection, cursor, parameters, context, executemany
        nonlocal consumer_selects, identification_selects
        if "FROM drug_consumer_info" in statement:
            consumer_selects += 1
        if "FROM drug_identification " in statement:
            identification_selects += 1

    event.listen(engine, "before_cursor_execute", count_normalized_selects)
    try:
        consumer_source = replace(
            source(),
            code="consumer-prefetch",
            kind="consumer",
        )
        identification_source = replace(
            source(),
            code="identification-prefetch",
            kind="identification",
            composite_key_fields=("itemSeq", "itemImage"),
            hash_record_key=True,
        )
        with SessionLocal() as database:
            sync_source(
                database,
                consumer_source,
                RecordFetcher(
                    [
                        {
                            "itemSeq": str(index),
                            "efcyQesitm": f"Efficacy {index}",
                        }
                        for index in range(50)
                    ]
                ),
            )
            sync_source(
                database,
                identification_source,
                RecordFetcher(
                    [
                        {
                            "itemSeq": str(index),
                            "itemImage": f"https://example.test/{index}.jpg",
                            "DRUG_SHAPE": "Round",
                        }
                        for index in range(50)
                    ]
                ),
            )
    finally:
        event.remove(engine, "before_cursor_execute", count_normalized_selects)

    assert consumer_selects == 1
    assert identification_selects == 1
