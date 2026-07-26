from __future__ import annotations

import argparse
import json
import time
from typing import Any

import httpx

from medical_box_api.catalog.sources import official_sources
from medical_box_api.config import get_settings


def summarize_payload(payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict):
        return {"json": False}
    response = payload.get("response") if isinstance(payload.get("response"), dict) else payload
    header = response.get("header") if isinstance(response, dict) else None
    body = response.get("body") if isinstance(response, dict) else None
    return {
        "json": True,
        "result_code": header.get("resultCode") if isinstance(header, dict) else None,
        "result_message": header.get("resultMsg") if isinstance(header, dict) else None,
        "total_count": body.get("totalCount") if isinstance(body, dict) else None,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_codes", nargs="+")
    parser.add_argument("--interval-seconds", type=int, default=30)
    parser.add_argument("--max-attempts", type=int, default=40)
    args = parser.parse_args()

    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise SystemExit("DATA_GO_KR_SERVICE_KEY is not configured.")
    sources = {source.code: source for source in official_sources(settings)}
    pending = {}
    for source_code in args.source_codes:
        source = sources.get(source_code)
        if source is None or source.api_url is None:
            raise SystemExit(f"Source is unavailable: {source_code}")
        pending[source_code] = source

    for attempt in range(1, args.max_attempts + 1):
        for source_code, source in list(pending.items()):
            response = httpx.get(
                source.api_url,
                params={
                    "serviceKey": settings.data_go_kr_service_key,
                    "pageNo": 1,
                    "numOfRows": 1,
                    "type": "json",
                },
                timeout=30,
            )
            try:
                payload = response.json()
            except json.JSONDecodeError:
                payload = None
            result = {
                "attempt": attempt,
                "source": source_code,
                "http_status": response.status_code,
                **summarize_payload(payload),
            }
            print(json.dumps(result, ensure_ascii=False, sort_keys=True), flush=True)
            if response.status_code == 200:
                pending.pop(source_code)
        if not pending:
            raise SystemExit(0)
        if attempt < args.max_attempts:
            time.sleep(args.interval_seconds)

    raise SystemExit(1)


if __name__ == "__main__":
    main()
