from __future__ import annotations

import argparse
import json
from typing import Any

from medical_box_api.catalog.fetcher import PublicDataFetcher
from medical_box_api.catalog.sources import official_sources
from medical_box_api.catalog.sync import canonical_hash, record_key
from medical_box_api.config import get_settings


def summarize(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, (dict, list)):
        encoded = json.dumps(value, ensure_ascii=False, sort_keys=True)
    else:
        encoded = str(value)
    return encoded if len(encoded) <= 160 else f"{encoded[:157]}..."


def differing_fields(
    first: dict[str, Any],
    second: dict[str, Any],
) -> dict[str, list[str]]:
    return {
        field: [summarize(first.get(field)), summarize(second.get(field))]
        for field in sorted(first.keys() | second.keys())
        if first.get(field) != second.get(field)
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_code")
    parser.add_argument("--max-collisions", type=int, default=3)
    args = parser.parse_args()

    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise SystemExit("DATA_GO_KR_SERVICE_KEY is not configured.")
    sources = {source.code: source for source in official_sources(settings)}
    source = sources.get(args.source_code)
    if source is None or source.api_url is None:
        raise SystemExit(f"Source is unavailable: {args.source_code}")

    seen: dict[str, dict[str, Any]] = {}
    collisions = 0
    fetcher = PublicDataFetcher(settings.data_go_kr_service_key)
    for page, records, total in fetcher.pages(source):
        for payload in records:
            key = record_key(source, payload)
            previous = seen.get(key)
            if previous is None:
                seen[key] = payload
                continue
            collisions += 1
            print(
                json.dumps(
                    {
                        "source": source.code,
                        "page": page,
                        "total_count": total,
                        "record_key": key,
                        "same_payload": canonical_hash(previous)
                        == canonical_hash(payload),
                        "differing_fields": differing_fields(previous, payload),
                    },
                    ensure_ascii=False,
                    sort_keys=True,
                ),
                flush=True,
            )
            if collisions >= args.max_collisions:
                return

    print(
        json.dumps(
            {
                "source": source.code,
                "total_count": len(seen),
                "collisions": collisions,
            },
            ensure_ascii=False,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
