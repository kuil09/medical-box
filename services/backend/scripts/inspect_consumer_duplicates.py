from __future__ import annotations

import collections
import hashlib
import json
from typing import Any

from medical_box_api.catalog.fetcher import PublicDataFetcher
from medical_box_api.catalog.sources import official_sources
from medical_box_api.config import get_settings


def canonical_hash(payload: dict[str, Any]) -> str:
    canonical = json.dumps(
        payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(canonical.encode()).hexdigest()


def value_summary(value: Any) -> dict[str, Any]:
    rendered = "" if value is None else str(value)
    return {
        "length": len(rendered),
        "sha256": hashlib.sha256(rendered.encode()).hexdigest()[:12],
        "preview": rendered[:120],
    }


def differing_fields(records: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    result: dict[str, list[dict[str, Any]]] = {}
    for field in sorted({field for record in records for field in record}):
        values = {
            json.dumps(record.get(field), ensure_ascii=False, sort_keys=True)
            for record in records
        }
        if len(values) > 1:
            result[field] = [value_summary(record.get(field)) for record in records]
    return result


def main() -> None:
    settings = get_settings()
    if not settings.data_go_kr_service_key:
        raise SystemExit("DATA_GO_KR_SERVICE_KEY is not configured.")
    source = next(
        source for source in official_sources(settings) if source.code == "mfds_easy"
    )
    fetcher = PublicDataFetcher(settings.data_go_kr_service_key)
    grouped: dict[str, list[dict[str, Any]]] = collections.defaultdict(list)
    total = 0
    for _, records, _ in fetcher.pages(source):
        for payload in records:
            key = str(payload.get("itemSeq") or payload.get("ITEM_SEQ") or "")
            grouped[key].append(payload)
            total += 1

    duplicates = {
        key: records for key, records in grouped.items() if key and len(records) > 1
    }
    summaries = []
    exact_duplicate_groups = 0
    for key, records in sorted(duplicates.items()):
        hashes = {canonical_hash(record) for record in records}
        if len(hashes) == 1:
            exact_duplicate_groups += 1
        summaries.append(
            {
                "item_seq": key,
                "record_count": len(records),
                "distinct_payloads": len(hashes),
                "open_dates": sorted(
                    {
                        str(record.get("openDe") or "")
                        for record in records
                        if record.get("openDe")
                    }
                ),
                "update_dates": sorted(
                    {
                        str(record.get("updateDe") or "")
                        for record in records
                        if record.get("updateDe")
                    }
                ),
                "item_names": sorted(
                    {
                        str(record.get("itemName") or "")
                        for record in records
                        if record.get("itemName")
                    }
                ),
                "differing_fields": differing_fields(records),
            }
        )

    print(
        json.dumps(
            {
                "total_records": total,
                "unique_item_sequences": len(grouped),
                "duplicate_groups": len(duplicates),
                "duplicate_records": sum(len(records) - 1 for records in duplicates.values()),
                "exact_duplicate_groups": exact_duplicate_groups,
                "examples": summaries[:20],
            },
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
