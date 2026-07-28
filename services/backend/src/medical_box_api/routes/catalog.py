import base64
from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy import func, or_, select, tuple_
from sqlalchemy.orm import Session, selectinload
from sqlalchemy.sql.elements import ColumnElement

from ..db import get_db
from ..models import (
    DrugIdentification,
    DrugIdentificationVariant,
    DrugProduct,
    DurRule,
    SourceRecord,
    SourceRegistry,
    SyncRun,
)
from ..schemas import (
    CatalogMeta,
    CatalogSource,
    CursorPage,
    DrugAppearanceInfo,
    DrugDetail,
    DrugSafetyCategory,
    DrugSafetyOverview,
    DrugSafetyRule,
    DrugSourceAttribution,
    DrugSummary,
)
from ..security import require_catalog_read

router = APIRouter(
    prefix="/api/v1",
    tags=["catalog"],
    dependencies=[Depends(require_catalog_read)],
)

SAFETY_RULE_TYPES = (
    "concomitant_contraindication",
    "pregnancy_contraindication",
    "efficacy_group_duplication",
    "dose_caution",
    "age_contraindication",
    "extended_release_split_caution",
    "elderly_caution",
    "duration_caution",
)


def _encode_cursor(name: str, item_seq: str) -> str:
    raw = f"{name}\x1f{item_seq}".encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_cursor(value: str) -> tuple[str, str]:
    try:
        padded = value + "=" * (-len(value) % 4)
        name, item_seq = base64.urlsafe_b64decode(padded).decode().split("\x1f", 1)
        return name, item_seq
    except (ValueError, UnicodeDecodeError) as exc:
        raise HTTPException(status_code=400, detail="Cursor is invalid.") from exc


def _encode_rule_cursor(rule_id: int) -> str:
    return base64.urlsafe_b64encode(f"dur:{rule_id}".encode()).decode().rstrip("=")


def _decode_rule_cursor(value: str) -> int:
    try:
        padded = value + "=" * (-len(value) % 4)
        prefix, raw_id = base64.urlsafe_b64decode(padded).decode().split(":", 1)
        rule_id = int(raw_id)
        if prefix != "dur" or rule_id < 1:
            raise ValueError
        return rule_id
    except (ValueError, UnicodeDecodeError) as exc:
        raise HTTPException(status_code=400, detail="Cursor is invalid.") from exc


def _payload_string(payload: dict[str, object], *keys: str) -> str | None:
    folded = {key.casefold(): value for key, value in payload.items()}
    for key in keys:
        value = payload.get(key)
        if value in (None, ""):
            value = folded.get(key.casefold())
        if value not in (None, ""):
            return str(value).strip()
    return None


def _safety_rule(rule: DurRule) -> DrugSafetyRule:
    payload = rule.source_record.payload
    return DrugSafetyRule(
        rule_type=rule.rule_type or "unknown",
        type_name=_payload_string(payload, "TYPE_NAME", "typeName"),
        ingredient_name=_payload_string(
            payload,
            "INGR_NAME",
            "INGR_KOR_NAME",
            "MAIN_INGR",
        ),
        counterpart_item_seq=_payload_string(payload, "MIXTURE_ITEM_SEQ"),
        counterpart_item_name=_payload_string(payload, "MIXTURE_ITEM_NAME"),
        counterpart_ingredient_name=_payload_string(
            payload,
            "MIXTURE_INGR_KOR_NAME",
            "MIXTURE_INGR_NAME",
        ),
        prohibition_content=_payload_string(payload, "PROHBT_CONTENT"),
        remark=_payload_string(payload, "REMARK"),
        notification_date=_payload_string(
            payload,
            "NOTIFICATION_DATE",
            "CHANGE_DATE",
        ),
        source_code=rule.source_code,
    )


def _summary(product: DrugProduct) -> DrugSummary:
    return DrugSummary(
        item_seq=product.item_seq,
        item_name=product.item_name,
        manufacturer=product.manufacturer,
        status=product.status,
        professional_category=product.professional_category,
    )


def _active_product_exists() -> ColumnElement[bool]:
    return (
        select(SourceRecord.id)
        .where(
            SourceRecord.source_code == "mfds_product",
            SourceRecord.record_key == DrugProduct.item_seq,
            SourceRecord.active.is_(True),
        )
        .exists()
    )


@router.get("/catalog/meta", response_model=CatalogMeta)
def catalog_meta(db: Session = Depends(get_db)) -> CatalogMeta:
    product_count = (
        db.scalar(
            select(func.count())
            .select_from(DrugProduct)
            .where(_active_product_exists())
        )
        or 0
    )
    last_sync = db.scalar(
        select(func.max(SyncRun.finished_at)).where(SyncRun.status == "succeeded")
    )
    sources = db.scalars(
        select(SourceRegistry).where(SourceRegistry.enabled.is_(True)).order_by(SourceRegistry.code)
    ).all()
    successful_syncs: dict[str, datetime | None] = {
        source_code: finished_at
        for source_code, finished_at in db.execute(
            select(
                SyncRun.source_code,
                func.max(SyncRun.finished_at),
            )
            .where(SyncRun.status == "succeeded")
            .group_by(SyncRun.source_code)
        )
    }
    latest_attempt_times = (
        select(
            SyncRun.source_code,
            func.max(SyncRun.started_at).label("started_at"),
        )
        .group_by(SyncRun.source_code)
        .subquery()
    )
    latest_attempts = {
        source_code: (status, started_at)
        for source_code, status, started_at in db.execute(
            select(
                SyncRun.source_code,
                SyncRun.status,
                SyncRun.started_at,
            ).join(
                latest_attempt_times,
                (SyncRun.source_code == latest_attempt_times.c.source_code)
                & (SyncRun.started_at == latest_attempt_times.c.started_at),
            )
        )
    }
    enabled_source_codes = {source.code for source in sources}
    failed_sources = sorted(
        source_code
        for source_code, (status, _started_at) in latest_attempts.items()
        if source_code in enabled_source_codes and status == "failed"
    )
    return CatalogMeta(
        product_count=product_count,
        last_successful_sync=last_sync,
        failed_sources=failed_sources,
        sources=[
            CatalogSource(
                code=source.code,
                name=source.name,
                portal_url=source.portal_url,
                license_name=source.license_name,
                attribution=source.attribution,
                last_successful_sync=successful_syncs.get(source.code),
                last_attempt_status=(
                    latest_attempts[source.code][0]
                    if source.code in latest_attempts
                    else None
                ),
                last_attempt_at=(
                    latest_attempts[source.code][1]
                    if source.code in latest_attempts
                    else None
                ),
            )
            for source in sources
        ],
    )


@router.get("/drugs/search", response_model=CursorPage[DrugSummary])
def search_drugs(
    q: str = Query(min_length=2, max_length=120),
    cursor: str | None = None,
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
) -> CursorPage[DrugSummary]:
    pattern = f"%{q.strip()}%"
    statement = (
        select(DrugProduct)
        .where(
            _active_product_exists(),
            or_(
                DrugProduct.item_name.ilike(pattern),
                DrugProduct.manufacturer.ilike(pattern),
                DrugProduct.item_seq == q.strip(),
            )
        )
        .order_by(DrugProduct.item_name, DrugProduct.item_seq)
    )
    if cursor:
        name, item_seq = _decode_cursor(cursor)
        statement = statement.where(
            tuple_(DrugProduct.item_name, DrugProduct.item_seq) > (name, item_seq)
        )
    products = list(db.scalars(statement.limit(limit + 1)).all())
    has_more = len(products) > limit
    page_products = products[:limit]
    next_cursor = (
        _encode_cursor(page_products[-1].item_name, page_products[-1].item_seq)
        if has_more and page_products
        else None
    )
    return CursorPage(
        items=[_summary(product) for product in page_products], next_cursor=next_cursor
    )


@router.get(
    "/drugs/{itemSeq}/dur-rules",
    response_model=CursorPage[DrugSafetyRule],
)
def get_drug_safety_rules(
    item_seq: str = Path(alias="itemSeq"),
    rule_type: str | None = Query(default=None, alias="ruleType"),
    cursor: str | None = None,
    limit: int = Query(default=20, ge=1, le=50),
    db: Session = Depends(get_db),
) -> CursorPage[DrugSafetyRule]:
    if (
        db.scalar(
            select(DrugProduct.item_seq).where(
                DrugProduct.item_seq == item_seq,
                _active_product_exists(),
            )
        )
        is None
    ):
        raise HTTPException(status_code=404, detail="Drug product was not found.")
    if rule_type is not None and rule_type not in SAFETY_RULE_TYPES:
        raise HTTPException(status_code=400, detail="DUR rule type is invalid.")

    statement = (
        select(DurRule)
        .join(SourceRecord, SourceRecord.id == DurRule.source_record_id)
        .join(SyncRun, SyncRun.id == SourceRecord.last_seen_run_id)
        .options(selectinload(DurRule.source_record))
        .where(
            DurRule.item_seq == item_seq,
            DurRule.rule_type.in_(SAFETY_RULE_TYPES),
            SyncRun.status == "succeeded",
        )
        .order_by(DurRule.id)
    )
    if rule_type is not None:
        statement = statement.where(DurRule.rule_type == rule_type)
    if cursor is not None:
        statement = statement.where(DurRule.id > _decode_rule_cursor(cursor))

    rules = list(db.scalars(statement.limit(limit + 1)).all())
    has_more = len(rules) > limit
    page_rules = rules[:limit]
    next_cursor = (
        _encode_rule_cursor(page_rules[-1].id)
        if has_more and page_rules
        else None
    )
    return CursorPage(
        items=[_safety_rule(rule) for rule in page_rules],
        next_cursor=next_cursor,
    )


@router.get("/drugs/{itemSeq}", response_model=DrugDetail)
def get_drug(
    item_seq: str = Path(alias="itemSeq"),
    db: Session = Depends(get_db),
) -> DrugDetail:
    product = db.scalar(
        select(DrugProduct)
        .options(selectinload(DrugProduct.ingredients), selectinload(DrugProduct.consumer_info))
        .where(
            DrugProduct.item_seq == item_seq,
            _active_product_exists(),
        )
    )
    if product is None:
        raise HTTPException(status_code=404, detail="Drug product was not found.")
    consumer = product.consumer_info
    identification = db.get(DrugIdentification, item_seq)
    identification_variants = db.scalars(
        select(DrugIdentificationVariant)
        .where(DrugIdentificationVariant.item_seq == item_seq)
        .order_by(DrugIdentificationVariant.variant_key)
    ).all()
    safety_counts = db.execute(
        select(DurRule.rule_type, func.count(DurRule.id))
        .join(SourceRecord, SourceRecord.id == DurRule.source_record_id)
        .join(SyncRun, SyncRun.id == SourceRecord.last_seen_run_id)
        .where(
            DurRule.item_seq == item_seq,
            DurRule.rule_type.in_(SAFETY_RULE_TYPES),
            SyncRun.status == "succeeded",
        )
        .group_by(DurRule.rule_type)
        .order_by(DurRule.rule_type)
    ).all()
    contributing_source_codes = {"mfds_product"}
    if any(
        (
            product.permit_date,
            product.storage_method,
            product.appearance,
            product.professional_category,
            product.image_url,
        )
    ):
        contributing_source_codes.add("mfds_product_detail")
    if product.ingredients:
        contributing_source_codes.add("mfds_product_ingredient")
    if consumer is not None:
        contributing_source_codes.add("mfds_easy")
    if identification is not None or identification_variants:
        contributing_source_codes.add("mfds_pill")
    contributing_source_codes.update(
        db.scalars(
            select(DurRule.source_code)
            .join(SourceRecord, SourceRecord.id == DurRule.source_record_id)
            .join(SyncRun, SyncRun.id == SourceRecord.last_seen_run_id)
            .where(
                DurRule.item_seq == item_seq,
                DurRule.rule_type.in_(SAFETY_RULE_TYPES),
                SyncRun.status == "succeeded",
            )
            .distinct()
        ).all()
    )
    sources = db.scalars(
        select(SourceRegistry)
        .where(
            SourceRegistry.enabled.is_(True),
            SourceRegistry.code.in_(contributing_source_codes),
        )
        .order_by(SourceRegistry.code)
    ).all()
    return DrugDetail(
        **_summary(product).model_dump(),
        permit_date=_date_string(product.permit_date),
        storage_method=product.storage_method,
        appearance=product.appearance,
        image_url=(
            identification.image_url or product.image_url
            if identification
            else product.image_url
        ),
        identification=(
            DrugAppearanceInfo(
                variant_key=None,
                shape=identification.shape,
                color=identification.color,
                imprint_front=identification.imprint_front,
                imprint_back=identification.imprint_back,
                image_url=identification.image_url,
            )
            if identification
            else None
        ),
        identification_variants=[
            DrugAppearanceInfo(
                variant_key=variant.variant_key,
                shape=variant.shape,
                color=variant.color,
                imprint_front=variant.imprint_front,
                imprint_back=variant.imprint_back,
                image_url=variant.image_url,
            )
            for variant in identification_variants
        ],
        safety_overview=DrugSafetyOverview(
            total_count=sum(count for _, count in safety_counts),
            categories=[
                DrugSafetyCategory(rule_type=rule_type, count=count)
                for rule_type, count in safety_counts
                if rule_type is not None
            ],
        ),
        ingredients=[ingredient.name for ingredient in product.ingredients],
        efficacy=consumer.efficacy if consumer else None,
        use_method=consumer.use_method if consumer else None,
        warning=consumer.warning if consumer else None,
        precautions=consumer.precautions if consumer else None,
        interactions=consumer.interactions if consumer else None,
        side_effects=consumer.side_effects if consumer else None,
        source_updated_at=product.source_updated_at,
        sources=[
            DrugSourceAttribution(
                source=source.name,
                source_url=source.portal_url,
                license_name=source.license_name,
                attribution=source.attribution,
            )
            for source in sources
        ],
    )


def _date_string(value: date | None) -> str | None:
    return value.isoformat() if value else None
