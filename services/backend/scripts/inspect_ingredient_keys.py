from __future__ import annotations

import json
from collections import Counter
from typing import Any

import httpx

from medical_box_api.config import get_settings

FIELDS = (
    "ITEM_SEQ",
    "MTRAL_SN",
    "TAMT_SEQ",
    "MTRAL_CODE",
    "MTRAL_NM",
    "QNT",
    "INGD_UNIT_CD",
)


def extract_items(payload: dict[str, Any]) -> list[dict[str, Any]]:
    response = payload.get("response") if isinstance(payload.get("response"), dict) else payload
    body = response.get("body") if isinstance(response, dict) else None
    raw_items = body.get("items") if isinstance(body, dict) else None
    if isinstance(raw_items, dict):
        raw_items = raw_items.get("item", raw_items)
    if isinstance(raw_items, dict):
        return [raw_items]
    if isinstance(raw_items, list):
        return [item for item in raw_items if isinstance(item, dict)]
    return []


def duplicate_count(
    rows: list[dict[str, Any]],
    fields: tuple[str, ...],
) -> int:
    keys = [
        "|".join(str(row.get(field) or "") for field in fields)
        for row in rows
    ]
    counts = Counter(keys)
    return sum(count - 1 for count in counts.values() if count > 1)


def main() -> None:
    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise SystemExit("DATA_GO_KR_SERVICE_KEY is not configured.")
    response = httpx.get(
        settings.mfds_product_ingredient_url,
        params={
            "serviceKey": settings.data_go_kr_service_key,
            "pageNo": 1,
            "numOfRows": 100,
            "type": "json",
        },
        timeout=30,
    )
    response.raise_for_status()
    payload = response.json()
    rows = extract_items(payload)
    response_payload = (
        payload.get("response")
        if isinstance(payload.get("response"), dict)
        else payload
    )
    body = (
        response_payload.get("body")
        if isinstance(response_payload, dict)
        else None
    )
    result = {
        "rows": len(rows),
        "total_count": body.get("totalCount") if isinstance(body, dict) else None,
        "missing": {
            field: sum(row.get(field) in (None, "") for row in rows)
            for field in FIELDS
        },
        "duplicates": {
            "item_material_serial": duplicate_count(rows, ("ITEM_SEQ", "MTRAL_SN")),
            "item_total_material_serial": duplicate_count(
                rows,
                ("ITEM_SEQ", "TAMT_SEQ", "MTRAL_SN"),
            ),
            "item_material_code": duplicate_count(rows, ("ITEM_SEQ", "MTRAL_CODE")),
            "item_material_name": duplicate_count(rows, ("ITEM_SEQ", "MTRAL_NM")),
            "all_identity_fields": duplicate_count(
                rows,
                ("ITEM_SEQ", "TAMT_SEQ", "MTRAL_SN", "MTRAL_CODE", "MTRAL_NM"),
            ),
        },
    }
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
