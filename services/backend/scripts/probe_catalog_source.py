from __future__ import annotations

import argparse
import json
from typing import Any
from urllib.parse import quote, quote_plus

import httpx

from medical_box_api.catalog.sources import official_sources
from medical_box_api.config import get_settings


def unwrap_item_container(value: Any) -> Any:
    while isinstance(value, dict) and len(value) == 1 and "item" in value:
        value = value["item"]
    return value


def extract_summary(payload: dict[str, Any]) -> dict[str, Any]:
    response = payload.get("response") if isinstance(payload.get("response"), dict) else payload
    header = response.get("header") if isinstance(response, dict) else None
    body = response.get("body") if isinstance(response, dict) else None
    raw_items = unwrap_item_container(
        body.get("items") if isinstance(body, dict) else None
    )
    first_item = (
        unwrap_item_container(raw_items[0])
        if isinstance(raw_items, list) and raw_items
        else unwrap_item_container(raw_items)
    )
    return {
        "result_code": header.get("resultCode") if isinstance(header, dict) else None,
        "result_message": header.get("resultMsg") if isinstance(header, dict) else None,
        "total_count": body.get("totalCount") if isinstance(body, dict) else None,
        "has_items": bool(body.get("items")) if isinstance(body, dict) else False,
        "first_item_keys": (
            sorted(str(key) for key in first_item)
            if isinstance(first_item, dict)
            else []
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_code")
    parser.add_argument(
        "--key-mode",
        choices=("decoded", "encoded"),
        default="decoded",
    )
    parser.add_argument(
        "--response-type",
        choices=("json", "xml"),
        default="json",
    )
    args = parser.parse_args()

    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise SystemExit("DATA_GO_KR_SERVICE_KEY is not configured.")

    sources = {source.code: source for source in official_sources(settings)}
    source = sources.get(args.source_code)
    if source is None or source.api_url is None:
        raise SystemExit(f"Source is unavailable: {args.source_code}")

    if args.key_mode == "encoded":
        if not settings.data_go_kr_service_key_encoded:
            raise SystemExit("DATA_GO_KR_SERVICE_KEY_ENCODED is not configured.")
        request_url = (
            f"{source.api_url}?serviceKey={settings.data_go_kr_service_key_encoded}"
            f"&pageNo=1&numOfRows=1&type={args.response_type}"
        )
        response = httpx.get(request_url, timeout=30)
    else:
        response = httpx.get(
            source.api_url,
            params={
                "serviceKey": settings.data_go_kr_service_key,
                "pageNo": 1,
                "numOfRows": 1,
                "type": args.response_type,
            },
            timeout=30,
        )

    result: dict[str, Any] = {
        "source": source.code,
        "key_mode": args.key_mode,
        "response_type": args.response_type,
        "http_status": response.status_code,
        "content_type": response.headers.get("content-type"),
        "server": response.headers.get("server"),
        "via": response.headers.get("via"),
    }
    try:
        payload = response.json()
    except json.JSONDecodeError:
        result["json"] = False
        preview = response.text[:500]
        secret_forms = {
            settings.data_go_kr_service_key,
            quote(settings.data_go_kr_service_key, safe=""),
            quote_plus(settings.data_go_kr_service_key, safe=""),
        }
        if settings.data_go_kr_service_key_encoded:
            secret_forms.add(settings.data_go_kr_service_key_encoded)
        for secret_form in secret_forms:
            preview = preview.replace(secret_form, "[REDACTED]")
        result["response_preview"] = preview
    else:
        result["json"] = isinstance(payload, dict)
        if isinstance(payload, dict):
            result.update(extract_summary(payload))

    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
