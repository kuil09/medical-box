#!/usr/bin/env python3

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

APPLE_BUNDLE_ID = "com.medicalbox.app"
ANDROID_PACKAGE_NAME = "com.medicalbox.app"
ANDROID_HANDLE_ALL_URLS = "delegate_permission/common.handle_all_urls"
APPLE_APP_LINK_PATHS = (
    "/app",
    "/app/inventory",
    "/app/reminders",
    "/app/settings",
    "/app/login",
)
APPLE_APP_ID_PATTERN = re.compile(r"^[A-Z0-9]{10}\.com\.medicalbox\.app$")
ANDROID_SHA256_PATTERN = re.compile(r"^(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$")


class MetadataValidationError(ValueError):
    pass


def _mapping(value: object, location: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise MetadataValidationError(f"{location} must be a JSON object.")
    return value


def _list(value: object, location: str) -> list[Any]:
    if not isinstance(value, list):
        raise MetadataValidationError(f"{location} must be a JSON array.")
    return value


def validate_apple_app_site_association(payload: object) -> str:
    root = _mapping(payload, "Apple metadata")
    applinks = _mapping(root.get("applinks"), "Apple applinks")
    details = _list(applinks.get("details"), "Apple applinks.details")
    if not details:
        raise MetadataValidationError("Apple applinks.details must not be empty.")

    app_ids: list[str] = []
    matching_app_ids: list[str] = []
    for index, detail_value in enumerate(details):
        detail = _mapping(detail_value, f"Apple applinks.details[{index}]")
        app_id = detail.get("appID")
        if isinstance(app_id, str):
            app_ids.append(app_id)
            if APPLE_APP_ID_PATTERN.fullmatch(app_id):
                paths = _list(
                    detail.get("paths"),
                    f"Apple applinks.details[{index}].paths",
                )
                if paths != list(APPLE_APP_LINK_PATHS):
                    raise MetadataValidationError(
                        "Apple app-link paths must be the exact supported /app routes."
                    )
                matching_app_ids.append(app_id)

    if any(app_id.startswith("UNCONFIGURED.") for app_id in app_ids):
        raise MetadataValidationError("Apple appID is still UNCONFIGURED.")

    if not matching_app_ids:
        raise MetadataValidationError(
            f"Apple metadata has no configured appID for {APPLE_BUNDLE_ID}."
        )
    return matching_app_ids[0]


def validate_android_asset_links(payload: object) -> list[str]:
    statements = _list(payload, "Android metadata")
    matching_fingerprints: list[str] = []

    for index, statement_value in enumerate(statements):
        statement = _mapping(statement_value, f"Android metadata[{index}]")
        relation = statement.get("relation")
        target_value = statement.get("target")
        if not isinstance(relation, list) or not isinstance(target_value, dict):
            continue
        target = _mapping(target_value, f"Android metadata[{index}].target")
        if (
            ANDROID_HANDLE_ALL_URLS not in relation
            or target.get("namespace") != "android_app"
            or target.get("package_name") != ANDROID_PACKAGE_NAME
        ):
            continue

        fingerprints = _list(
            target.get("sha256_cert_fingerprints"),
            (
                f"Android metadata[{index}].target."
                "sha256_cert_fingerprints"
            ),
        )
        if not fingerprints:
            raise MetadataValidationError(
                "Android SHA-256 certificate fingerprint list must not be empty."
            )
        for fingerprint in fingerprints:
            if not isinstance(fingerprint, str) or not ANDROID_SHA256_PATTERN.fullmatch(
                fingerprint
            ):
                raise MetadataValidationError(
                    "Android certificate fingerprints must be colon-separated SHA-256 values."
                )
            matching_fingerprints.append(fingerprint.upper())

    if not matching_fingerprints:
        raise MetadataValidationError(
            f"Android metadata has no verified link target for {ANDROID_PACKAGE_NAME}."
        )
    return matching_fingerprints


def load_json(path: Path) -> object:
    with path.open(encoding="utf-8") as input_file:
        return json.load(input_file)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate production Apple and Android app-link metadata."
    )
    parser.add_argument("--apple", required=True, type=Path)
    parser.add_argument("--android", required=True, type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        app_id = validate_apple_app_site_association(load_json(args.apple))
        fingerprints = validate_android_asset_links(load_json(args.android))
    except (OSError, json.JSONDecodeError, MetadataValidationError) as error:
        print(f"release_metadata_verification=failed: {error}", file=sys.stderr)
        return 1

    print(
        "release_metadata_verification=passed "
        f"apple_app_id={app_id} android_fingerprint_count={len(fingerprints)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
