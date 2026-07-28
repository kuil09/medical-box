from typing import Any

from .sources import SourceDefinition

SOURCE_UPDATED_AT_FIELDS = frozenset(
    {
        "LAST_UPDT_DTM",
        "lastUpdatedAt",
        "UPDT_DT",
        "updateDate",
        "UPDATE_DATE",
        "변경일자",
        "자료갱신일",
    }
)

DUR_PUBLIC_FIELDS = frozenset(
    {
        "TYPE_NAME",
        "typeName",
        "INGR_NAME",
        "INGR_KOR_NAME",
        "MAIN_INGR",
        "MIXTURE_ITEM_SEQ",
        "MIXTURE_ITEM_NAME",
        "MIXTURE_INGR_KOR_NAME",
        "MIXTURE_INGR_NAME",
        "PROHBT_CONTENT",
        "REMARK",
        "NOTIFICATION_DATE",
        "CHANGE_DATE",
    }
)

IDENTIFICATION_RANK_FIELDS = frozenset(
    {
        "CHANGE_DATE",
        "changeDate",
        "IMG_REGIST_TS",
        "imgRegistTs",
        "ITEM_IMAGE",
        "itemImage",
    }
)

STATUS_PUBLIC_FIELDS = frozenset(
    {
        "RTRVL_RESN",
        "recallReason",
        "RECALL_REASON",
        "회수사유",
        "PRDCTN_IMPRT_SUPLY_STOP_RSN",
        "PRDCTN_IMPRT_SUPPLY_STOP_RSN",
        "SUSPEND_REASON",
        "supplyStopReason",
        "공급중단사유",
    }
)

CODE_PUBLIC_FIELDS = frozenset(
    {
        "제품코드(개정후)",
        "제품코드",
        "insuranceCode",
        "INSURANCE_CODE",
        "EDI_CODE",
        "ediCode",
    }
)


def fields_for_source(source: SourceDefinition) -> frozenset[str]:
    if source.kind == "dur":
        return DUR_PUBLIC_FIELDS | SOURCE_UPDATED_AT_FIELDS
    if source.kind == "identification":
        return IDENTIFICATION_RANK_FIELDS
    if source.kind.startswith("status_"):
        return STATUS_PUBLIC_FIELDS | SOURCE_UPDATED_AT_FIELDS
    if source.kind == "price":
        return SOURCE_UPDATED_AT_FIELDS
    if source.kind == "code":
        return CODE_PUBLIC_FIELDS | SOURCE_UPDATED_AT_FIELDS
    return frozenset()


def public_source_data(
    source: SourceDefinition,
    payload: dict[str, Any],
) -> dict[str, object]:
    allowed = {field.casefold() for field in fields_for_source(source)}
    if not allowed:
        return {}
    return {
        str(key): value
        for key, value in payload.items()
        if str(key).casefold() in allowed
    }
