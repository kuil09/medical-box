import hashlib
import json
import re
from collections.abc import Iterable
from datetime import UTC, date, datetime
from decimal import Decimal, InvalidOperation
from typing import Any

import typer
from sqlalchemy import delete, func, select, update
from sqlalchemy.orm import Session

from ..config import get_settings
from ..db import SessionLocal
from ..models import (
    DrugCode,
    DrugConsumerInfo,
    DrugIdentification,
    DrugIdentificationVariant,
    DrugIngredient,
    DrugPrice,
    DrugProduct,
    DrugStatusEvent,
    DurRule,
    SourceRecord,
    SourceRegistry,
    SyncCheckpoint,
    SyncRun,
)
from .fetcher import PublicDataFetcher
from .sources import SourceDefinition, official_sources

app = typer.Typer(no_args_is_help=True)

BOOTSTRAP_DUR_COMMIT_INTERVAL_PAGES = 10


def canonical_hash(payload: dict[str, Any]) -> str:
    encoded = json.dumps(
        payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode()
    return hashlib.sha256(encoded).hexdigest()


def first_value(payload: dict[str, Any], *names: str) -> Any:
    folded = {str(key).casefold(): value for key, value in payload.items()}
    for name in names:
        value = payload.get(name)
        if value not in (None, ""):
            return value
        value = folded.get(name.casefold())
        if value not in (None, ""):
            return value
    return None


def record_key(source: SourceDefinition, payload: dict[str, Any]) -> str:
    key: str
    if source.composite_key_fields:
        values = [
            first_value(payload, field)
            for field in source.composite_key_fields
        ]
        if values and values[0] not in (None, ""):
            if any(value in (None, "") for value in values[1:]):
                key = f"{values[0]}|missing"
                if not source.hash_record_key:
                    key = f"{key}|{canonical_hash(payload)[:32]}"
            else:
                key = "|".join(str(value) for value in values)
        else:
            key = canonical_hash(payload)
    else:
        value = first_value(payload, *source.record_key_fields)
        key = str(value) if value not in (None, "") else canonical_hash(payload)
    if source.hash_record_key:
        return f"{key[:220]}|{canonical_hash(payload)[:32]}"
    return key


def has_required_record_key(source: SourceDefinition, payload: dict[str, Any]) -> bool:
    if source.composite_key_fields:
        return bool(source.composite_key_fields) and first_value(
            payload,
            source.composite_key_fields[0],
        ) not in (None, "")
    return first_value(payload, *source.record_key_fields) not in (None, "")


def item_seq(payload: dict[str, Any]) -> str | None:
    value = first_value(
        payload,
        "ITEM_SEQ",
        "itemSeq",
        "prdlst_Stdr_code",
        "품목기준코드",
    )
    return str(value) if value not in (None, "") else None


def ensure_product(
    db: Session,
    payload: dict[str, Any],
    product_cache: dict[str, DrugProduct] | None = None,
) -> DrugProduct | None:
    sequence = item_seq(payload)
    if not sequence:
        return None
    if product_cache is not None:
        product = product_cache.get(sequence)
    else:
        product = next(
            (
                pending
                for pending in db.new
                if isinstance(pending, DrugProduct)
                and pending.item_seq == sequence
            ),
            None,
        )
        if product is None:
            product = db.get(DrugProduct, sequence)
    name = first_value(payload, "ITEM_NAME", "itemName", "item_name", "품목명")
    if product is None:
        product = DrugProduct(item_seq=sequence, item_name=str(name or sequence))
        db.add(product)
        if product_cache is not None:
            product_cache[sequence] = product
    if name:
        product.item_name = str(name)
    manufacturer = first_value(payload, "ENTP_NAME", "entpName", "entp_name", "업체명")
    if manufacturer:
        product.manufacturer = str(manufacturer)
    status = _string(first_value(payload, "CANCEL_NAME", "cancelName", "status"))
    if status is not None:
        product.status = status
    storage_method = _string(
        first_value(payload, "STORAGE_METHOD", "storageMethod", "depositMethodQesitm")
    )
    if storage_method is not None:
        product.storage_method = storage_method
    appearance = _string(first_value(payload, "CHART", "chart", "appearance"))
    if appearance is not None:
        product.appearance = appearance
    professional_category = _string(
        first_value(payload, "ETC_OTC_CODE", "etcOtcCode", "spclty_pblc")
    )
    if professional_category is not None:
        product.professional_category = professional_category
    image_url = _string(
        first_value(payload, "ITEM_IMAGE", "itemImage", "BIG_PRDT_IMG_URL")
    )
    if image_url is not None:
        product.image_url = image_url
    source_updated_at = _string(
        first_value(payload, "UPDATE_DE", "updateDe", "sourceUpdatedAt")
    )
    if source_updated_at is not None:
        product.source_updated_at = source_updated_at
    permit_date = _date(first_value(payload, "ITEM_PERMIT_DATE", "itemPermitDate"))
    if permit_date is not None:
        product.permit_date = permit_date
    return product


def ingredient_rows(payload: dict[str, Any]) -> list[tuple[str, str | None, str | None]]:
    raw = first_value(payload, "ingredients", "ingredient", "materials", "material")
    entries: list[Any]
    if isinstance(raw, dict):
        nested = first_value(raw, "items", "item", "ingredients", "ingredient")
        entries = nested if isinstance(nested, list) else [raw]
    elif isinstance(raw, list):
        entries = raw
    elif raw not in (None, ""):
        entries = [raw]
    else:
        flat = first_value(
            payload,
            "MATERIAL_NAME",
            "materialName",
            "MAIN_ITEM_INGR",
            "mainItemIngr",
            "성분명",
        )
        entries = [flat] if flat not in (None, "") else []

    rows: list[tuple[str, str | None, str | None]] = []
    for entry in entries:
        if isinstance(entry, dict):
            name = _string(
                first_value(
                    entry,
                    "name",
                    "ingredientName",
                    "INGR_NAME",
                    "ingrName",
                    "CPNT_NAME",
                    "성분명",
                )
            )
            if name:
                rows.append(
                    (
                        name,
                        _string(first_value(entry, "amount", "INGR_QTY", "ingrQty", "분량")),
                        _string(first_value(entry, "unit", "INGR_UNIT", "ingrUnit", "단위")),
                    )
                )
            continue
        for value in re.split(r"[|;\r\n]+", str(entry)):
            name = value.strip()
            if name:
                rows.append((name, None, None))

    deduplicated: dict[str, tuple[str, str | None, str | None]] = {}
    for row in rows:
        deduplicated[row[0]] = row
    return list(deduplicated.values())


def normalize_ingredients(db: Session, product: DrugProduct, payload: dict[str, Any]) -> None:
    rows = ingredient_rows(payload)
    if not rows:
        return
    current = {
        ingredient.name: ingredient
        for ingredient in db.scalars(
            select(DrugIngredient).where(DrugIngredient.item_seq == product.item_seq)
        ).all()
    }
    expected = {name for name, _, _ in rows}
    for name, stale_ingredient in current.items():
        if name not in expected:
            db.delete(stale_ingredient)
    for name, amount, unit in rows:
        ingredient = current.get(name)
        if ingredient is None:
            ingredient = DrugIngredient(item_seq=product.item_seq, name=name)
            db.add(ingredient)
        ingredient.amount = amount
        ingredient.unit = unit


def normalize_ingredient_record(
    db: Session,
    product: DrugProduct,
    payload: dict[str, Any],
    ingredient_cache: dict[tuple[str, str], DrugIngredient] | None = None,
) -> None:
    name = _string(first_value(payload, "MTRAL_NM", "materialName", "INGR_NAME"))
    if not name:
        return
    cache_key = (product.item_seq, name)
    if ingredient_cache is not None:
        ingredient = ingredient_cache.get(cache_key)
    else:
        ingredient = next(
            (
                pending
                for pending in db.new
                if isinstance(pending, DrugIngredient)
                and pending.item_seq == product.item_seq
                and pending.name == name
            ),
            None,
        )
        if ingredient is None:
            ingredient = db.scalar(
                select(DrugIngredient).where(
                    DrugIngredient.item_seq == product.item_seq,
                    DrugIngredient.name == name,
                )
            )
    if ingredient is None:
        ingredient = DrugIngredient(item_seq=product.item_seq, name=name)
        db.add(ingredient)
        if ingredient_cache is not None:
            ingredient_cache[cache_key] = ingredient
    ingredient.amount = _string(first_value(payload, "QNT", "INGR_QTY", "ingrQty"))
    ingredient.unit = _string(
        first_value(payload, "INGD_UNIT_CD", "INGR_UNIT", "ingrUnit")
    )


def normalize(
    db: Session,
    source: SourceDefinition,
    source_record: SourceRecord,
    payload: dict[str, Any],
    *,
    dur_rules_are_absent: bool = False,
    identification_variants_are_absent: bool = False,
    product_cache: dict[str, DrugProduct] | None = None,
    ingredient_cache: dict[tuple[str, str], DrugIngredient] | None = None,
) -> None:
    key = source_record.record_key
    product = (
        None
        if source.kind == "dur"
        else ensure_product(db, payload, product_cache)
    )
    sequence = product.item_seq if product else item_seq(payload)
    if source.kind == "product" and product:
        normalize_ingredients(db, product, payload)
    elif source.kind == "product_ingredient" and product:
        normalize_ingredient_record(
            db,
            product,
            payload,
            ingredient_cache,
        )
    elif source.kind == "consumer" and sequence:
        info = next(
            (
                pending
                for pending in db.new
                if isinstance(pending, DrugConsumerInfo)
                and pending.item_seq == sequence
            ),
            None,
        )
        if info is None:
            info = db.get(DrugConsumerInfo, sequence)
        if info is None:
            info = DrugConsumerInfo(item_seq=sequence)
            db.add(info)
        info.efficacy = _string(first_value(payload, "efcyQesitm"))
        info.use_method = _string(first_value(payload, "useMethodQesitm"))
        info.warning = _string(first_value(payload, "atpnWarnQesitm"))
        info.precautions = _string(first_value(payload, "atpnQesitm"))
        info.interactions = _string(first_value(payload, "intrcQesitm"))
        info.side_effects = _string(first_value(payload, "seQesitm"))
        info.storage = _string(first_value(payload, "depositMethodQesitm"))
        info.source_updated_at = _string(first_value(payload, "updateDe"))
    elif source.kind == "identification" and sequence:
        shape = _string(first_value(payload, "DRUG_SHAPE", "drugShape"))
        color = _string(first_value(payload, "COLOR_CLASS1", "colorClass1"))
        imprint_front = _string(first_value(payload, "PRINT_FRONT", "printFront"))
        imprint_back = _string(first_value(payload, "PRINT_BACK", "printBack"))
        image_url = _string(first_value(payload, "ITEM_IMAGE", "itemImage"))

        variant = None
        if not identification_variants_are_absent:
            variant = db.scalar(
                select(DrugIdentificationVariant).where(
                    DrugIdentificationVariant.source_code == source.code,
                    DrugIdentificationVariant.variant_key == key,
                )
            )
        if variant is None:
            variant = DrugIdentificationVariant(
                item_seq=sequence,
                source_code=source.code,
                variant_key=key,
                source_record=source_record,
            )
            db.add(variant)
        variant.shape = shape
        variant.color = color
        variant.imprint_front = imprint_front
        variant.imprint_back = imprint_back
        variant.image_url = image_url
        variant.source_record = source_record

        identification = next(
            (
                pending
                for pending in db.new
                if isinstance(pending, DrugIdentification)
                and pending.item_seq == sequence
            ),
            None,
        )
        if identification is None:
            identification = db.get(DrugIdentification, sequence)
        if identification is None:
            identification = DrugIdentification(
                item_seq=sequence,
                source_record=source_record,
            )
            db.add(identification)
        current_payload = (
            identification.source_record.payload
            if identification.source_record is not None
            else None
        )
        if (
            current_payload is None
            or _identification_rank(payload)
            >= _identification_rank(current_payload)
        ):
            identification.shape = shape
            identification.color = color
            identification.imprint_front = imprint_front
            identification.imprint_back = imprint_back
            identification.image_url = image_url
            identification.source_record = source_record
    elif source.kind == "dur":
        rule = None
        if not dur_rules_are_absent:
            rule = db.scalar(
                select(DurRule).where(
                    DurRule.source_code == source.code,
                    DurRule.rule_key == key,
                )
            )
        if rule is None:
            rule = DurRule(
                source_code=source.code,
                rule_key=key,
                source_record=source_record,
            )
            db.add(rule)
        rule.item_seq = sequence
        rule.rule_type = source.rule_type or _string(
            first_value(payload, "TYPE_NAME", "typeName", "DUR_TYPE", "durType")
        )
        rule.source_record = source_record
    elif source.kind.startswith("status_"):
        event = db.scalar(
            select(DrugStatusEvent).where(
                DrugStatusEvent.source_code == source.code,
                DrugStatusEvent.event_key == key,
            )
        )
        if event is None:
            event = DrugStatusEvent(
                source_code=source.code,
                event_key=key,
                event_type=source.kind.removeprefix("status_"),
                source_record=source_record,
            )
            db.add(event)
        event.item_seq = sequence
        event.started_on = _date(first_value(payload, "START_DATE", "startDate", "공고일자"))
        event.ended_on = _date(first_value(payload, "END_DATE", "endDate"))
        event.source_record = source_record
    elif source.kind == "price":
        price = db.scalar(select(DrugPrice).where(DrugPrice.insurance_code == key))
        if price is None:
            price = DrugPrice(
                insurance_code=key,
                source_record=source_record,
            )
            db.add(price)
        price.item_seq = sequence
        price.amount = _decimal(first_value(payload, "payAmt", "upperLimitPrice", "상한금액"))
        price.effective_date = _date(first_value(payload, "applyDt", "effectiveDate", "적용일자"))
        price.source_record = source_record
    elif source.kind == "code":
        code = db.scalar(
            select(DrugCode).where(DrugCode.code_type == "standard", DrugCode.code == key)
        )
        if code is None:
            code = DrugCode(
                code_type="standard",
                code=key,
                source_record=source_record,
            )
            db.add(code)
        code.item_seq = sequence
        code.source_record = source_record


def _advisory_lock_key(source_code: str) -> int:
    digest = hashlib.sha256(f"medical-box:{source_code}".encode()).digest()
    return int.from_bytes(digest[:8], "big") & 0x7FFF_FFFF_FFFF_FFFF


def _try_source_lock(db: Session, source_code: str) -> bool:
    if db.bind is None or db.bind.dialect.name != "postgresql":
        return True
    acquired = db.scalar(select(func.pg_try_advisory_lock(_advisory_lock_key(source_code))))
    return bool(acquired)


def _release_source_lock(db: Session, source_code: str) -> None:
    if db.bind is None or db.bind.dialect.name != "postgresql":
        return
    db.scalar(select(func.pg_advisory_unlock(_advisory_lock_key(source_code))))


def sync_source(db: Session, source: SourceDefinition, fetcher: PublicDataFetcher) -> SyncRun:
    if not _try_source_lock(db, source.code):
        run = SyncRun(
            source_code=source.code,
            status="skipped",
            error="Another synchronization owns the source advisory lock.",
            finished_at=datetime.now(UTC),
        )
        db.add(run)
        db.commit()
        return run
    try:
        return _sync_source_locked(db, source, fetcher)
    finally:
        _release_source_lock(db, source.code)


def _sync_source_locked(
    db: Session, source: SourceDefinition, fetcher: PublicDataFetcher
) -> SyncRun:
    run = SyncRun(source_code=source.code)
    db.add(run)
    db.commit()
    if not source.api_url:
        run.status = "skipped"
        run.error = "Source URL is not configured."
        run.finished_at = datetime.now(UTC)
        db.commit()
        return run

    previous_count = db.scalar(
        select(SyncRun.record_count)
        .where(SyncRun.source_code == source.code, SyncRun.status == "succeeded")
        .order_by(SyncRun.finished_at.desc())
        .limit(1)
    )
    try:
        checkpoint = db.get(SyncCheckpoint, source.code)
        file_content_hash: str | None = None
        file_updated_at: str | None = None
        page_stream: Iterable[tuple[int, list[dict[str, Any]], int]]
        if source.kind == "code":
            file_content_hash, file_updated_at, records = fetcher.tabular_file(source)
            if checkpoint is not None and checkpoint.content_hash == file_content_hash:
                checkpoint.source_updated_at = file_updated_at or checkpoint.source_updated_at
                run.status = "skipped"
                run.record_count = previous_count or 0
                run.page_count = 1
                run.finished_at = datetime.now(UTC)
                db.commit()
                return run
            page_stream = [(1, records, len(records))]
        else:
            page_stream = fetcher.pages(source)

        count = 0
        pages = 0
        seen_keys: set[str] = set()
        seen_digests: dict[str, str] = {}
        source_records_are_absent = (
            db.scalar(
                select(SourceRecord.id)
                .where(SourceRecord.source_code == source.code)
                .limit(1)
            )
            is None
        )
        dur_rules_are_absent = source.kind == "dur" and (
            db.scalar(
                select(DurRule.id)
                .where(DurRule.source_code == source.code)
                .limit(1)
            )
            is None
        )
        batch_dur_bootstrap = source.kind == "dur" and previous_count is None
        identification_variants_are_absent = source.kind == "identification" and (
            db.scalar(
                select(DrugIdentificationVariant.id)
                .where(DrugIdentificationVariant.source_code == source.code)
                .limit(1)
            )
            is None
        )
        if source.kind == "identification":
            db.execute(delete(DrugIdentification))
        for page, records, total in page_stream:
            pages = page
            product_cache: dict[str, DrugProduct] | None = None
            ingredient_cache: (
                dict[tuple[str, str], DrugIngredient] | None
            ) = None
            if source.kind != "dur":
                page_item_sequences = {
                    sequence
                    for payload in records
                    if (sequence := item_seq(payload)) is not None
                }
                product_cache = {
                    product.item_seq: product
                    for product in db.scalars(
                        select(DrugProduct).where(
                            DrugProduct.item_seq.in_(page_item_sequences)
                        )
                    ).all()
                }
                if source.kind == "product_ingredient":
                    ingredient_cache = {
                        (ingredient.item_seq, ingredient.name): ingredient
                        for ingredient in db.scalars(
                            select(DrugIngredient).where(
                                DrugIngredient.item_seq.in_(
                                    page_item_sequences
                                )
                            )
                        ).all()
                    }
            for payload in records:
                if not has_required_record_key(source, payload):
                    raise RuntimeError(
                        f"Required record key is missing for source {source.code}."
                    )
                key = record_key(source, payload)
                digest = canonical_hash(payload)
                if key in seen_keys:
                    if (
                        source.allow_identical_duplicates
                        and seen_digests[key] == digest
                    ):
                        count += 1
                        continue
                    raise RuntimeError(
                        f"Duplicate record key {key!r} in source {source.code}."
                    )
                seen_keys.add(key)
                seen_digests[key] = digest
                existing = None
                if not source_records_are_absent:
                    existing = db.scalar(
                        select(SourceRecord).where(
                            SourceRecord.source_code == source.code,
                            SourceRecord.record_key == key,
                        )
                    )
                is_new = existing is None
                unchanged = False
                if existing is None:
                    existing = SourceRecord(
                        source_code=source.code,
                        record_key=key,
                        content_hash=digest,
                        payload=payload,
                        active=not batch_dur_bootstrap,
                        last_seen_run_id=run.id,
                    )
                    db.add(existing)
                else:
                    unchanged = existing.content_hash == digest
                    existing.content_hash = digest
                    existing.payload = payload
                    existing.active = not batch_dur_bootstrap
                    existing.last_seen_run_id = run.id
                    existing.last_seen_at = datetime.now(UTC)
                if is_new or not unchanged or source.kind == "identification":
                    normalize(
                        db,
                        source,
                        existing,
                        payload,
                        dur_rules_are_absent=dur_rules_are_absent,
                        identification_variants_are_absent=(
                            identification_variants_are_absent
                        ),
                        product_cache=product_cache,
                        ingredient_cache=ingredient_cache,
                    )
                count += 1
            if checkpoint is None:
                checkpoint = SyncCheckpoint(source_code=source.code)
                db.add(checkpoint)
            checkpoint.page = page
            if file_content_hash:
                checkpoint.content_hash = file_content_hash
                checkpoint.source_updated_at = file_updated_at
            db.flush()
            if (
                batch_dur_bootstrap
                and page % BOOTSTRAP_DUR_COMMIT_INTERVAL_PAGES == 0
            ):
                db.commit()
            if page * fetcher.page_size >= total:
                break

        if previous_count and previous_count >= 100 and count < previous_count * 0.5:
            raise RuntimeError(
                f"Record count collapsed from {previous_count} to {count}; keeping prior snapshot."
            )
        if batch_dur_bootstrap:
            db.execute(
                update(SourceRecord)
                .where(
                    SourceRecord.source_code == source.code,
                    SourceRecord.last_seen_run_id == run.id,
                )
                .values(active=True)
            )
        db.execute(
            update(SourceRecord)
            .where(
                SourceRecord.source_code == source.code,
                SourceRecord.last_seen_run_id != run.id,
            )
            .values(active=False)
        )
        if source.kind == "dur" and not dur_rules_are_absent:
            inactive_source_records = select(SourceRecord.id).where(
                SourceRecord.source_code == source.code,
                SourceRecord.active.is_(False),
            )
            db.execute(
                delete(DurRule).where(
                    DurRule.source_code == source.code,
                    DurRule.source_record_id.in_(inactive_source_records),
                )
            )
        if source.kind == "identification":
            active_source_record = (
                select(SourceRecord.id)
                .where(
                    SourceRecord.source_code == source.code,
                    SourceRecord.record_key
                    == DrugIdentificationVariant.variant_key,
                    SourceRecord.active.is_(True),
                )
                .exists()
            )
            db.execute(
                delete(DrugIdentificationVariant).where(
                    DrugIdentificationVariant.source_code == source.code,
                    ~active_source_record,
                )
            )
        run.status = "succeeded"
        run.record_count = count
        run.page_count = pages
        run.finished_at = datetime.now(UTC)
        db.commit()
        return run
    except Exception as exc:
        db.rollback()
        failed = db.get(SyncRun, run.id)
        if failed is None:
            failed = SyncRun(id=run.id, source_code=source.code)
            db.add(failed)
        failed.status = "failed"
        failed.error = str(exc)[:4000]
        failed.finished_at = datetime.now(UTC)
        db.commit()
        raise


def seed_source_registry(db: Session, sources: list[SourceDefinition]) -> None:
    for source in sources:
        row = db.scalar(select(SourceRegistry).where(SourceRegistry.code == source.code))
        if row is None:
            row = SourceRegistry(
                code=source.code,
                name=source.name,
                portal_url=source.portal_url,
            )
            db.add(row)
        row.name = source.name
        row.portal_url = source.portal_url
        row.api_url = source.api_url
        row.license_name = source.license_name
        row.attribution = source.attribution
        row.enabled = bool(source.api_url)
    db.commit()


@app.command()
def all_sources() -> None:
    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise typer.BadParameter("DATA_GO_KR_SERVICE_KEY is required.")
    sources = official_sources(settings)
    fetcher = PublicDataFetcher(settings.data_go_kr_service_key)
    failures = 0
    with SessionLocal() as db:
        seed_source_registry(db, sources)
        for source in sources:
            try:
                run = sync_source(db, source, fetcher)
                typer.echo(f"{source.code}: {run.status} ({run.record_count} records)")
            except Exception as exc:
                failures += 1
                typer.echo(f"{source.code}: failed ({exc})", err=True)
    if failures:
        raise typer.Exit(code=1)


@app.command()
def one(source_code: str) -> None:
    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise typer.BadParameter("DATA_GO_KR_SERVICE_KEY is required.")
    sources = {source.code: source for source in official_sources(settings)}
    source = sources.get(source_code)
    if source is None:
        raise typer.BadParameter(f"Unknown source: {source_code}")
    with SessionLocal() as db:
        seed_source_registry(db, list(sources.values()))
        run = sync_source(db, source, PublicDataFetcher(settings.data_go_kr_service_key))
        typer.echo(f"{source.code}: {run.status} ({run.record_count} records)")


@app.command("kind")
def source_kind(source_kind: str) -> None:
    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise typer.BadParameter("DATA_GO_KR_SERVICE_KEY is required.")
    all_sources = official_sources(settings)
    sources = [source for source in all_sources if source.kind == source_kind]
    if not sources:
        raise typer.BadParameter(f"Unknown source kind: {source_kind}")
    fetcher = PublicDataFetcher(settings.data_go_kr_service_key)
    failures = 0
    with SessionLocal() as db:
        seed_source_registry(db, all_sources)
        for source in sources:
            try:
                run = sync_source(db, source, fetcher)
                typer.echo(f"{source.code}: {run.status} ({run.record_count} records)")
            except Exception as exc:
                failures += 1
                typer.echo(f"{source.code}: failed ({exc})", err=True)
    if failures:
        raise typer.Exit(code=1)


@app.command()
def renormalize(source_code: str) -> None:
    settings = get_settings()
    sources = {source.code: source for source in official_sources(settings)}
    source = sources.get(source_code)
    if source is None:
        raise typer.BadParameter(f"Unknown source: {source_code}")
    count = 0
    with SessionLocal() as db:
        records = db.scalars(
            select(SourceRecord).where(
                SourceRecord.source_code == source.code,
                SourceRecord.active.is_(True),
            )
        ).yield_per(500)
        try:
            for record in records:
                if isinstance(record.payload, dict):
                    normalize(db, source, record, record.payload)
                    count += 1
                if count and count % 500 == 0:
                    db.flush()
            db.commit()
        except Exception:
            db.rollback()
            raise
    typer.echo(f"{source.code}: renormalized ({count} records)")


def _string(value: Any) -> str | None:
    return str(value).strip() if value not in (None, "") else None


def _identification_rank(payload: dict[str, Any]) -> tuple[str, str, str, str]:
    return (
        _string(first_value(payload, "CHANGE_DATE", "changeDate")) or "",
        _string(first_value(payload, "IMG_REGIST_TS", "imgRegistTs")) or "",
        _string(first_value(payload, "ITEM_IMAGE", "itemImage")) or "",
        canonical_hash(payload),
    )


def _date(value: Any) -> date | None:
    if value in (None, ""):
        return None
    digits = "".join(character for character in str(value) if character.isdigit())
    if len(digits) < 8:
        return None
    try:
        return date(int(digits[:4]), int(digits[4:6]), int(digits[6:8]))
    except ValueError:
        return None


def _decimal(value: Any) -> Decimal | None:
    if value in (None, ""):
        return None
    try:
        return Decimal(str(value).replace(",", ""))
    except InvalidOperation:
        return None


if __name__ == "__main__":
    app()
