import json
import runpy
import subprocess
import sys
from pathlib import Path
from typing import Any

import pytest

SCRIPT = (
    Path(__file__).parents[1]
    / "scripts"
    / "verify_well_known_metadata.py"
)
SCRIPT_NAMESPACE = runpy.run_path(str(SCRIPT))
MetadataValidationError = SCRIPT_NAMESPACE["MetadataValidationError"]
validate_android_asset_links = SCRIPT_NAMESPACE[
    "validate_android_asset_links"
]
validate_apple_app_site_association = SCRIPT_NAMESPACE[
    "validate_apple_app_site_association"
]

TEAM_ID = "AB12CD34EF"
FINGERPRINT = ":".join(f"{value:02X}" for value in range(32))
APP_LINK_PATHS = [
    "/app",
    "/app/inventory",
    "/app/reminders",
    "/app/settings",
    "/app/login",
]


def _apple_payload(app_id: str = f"{TEAM_ID}.com.medicalbox.app") -> dict[str, Any]:
    return {
        "applinks": {
            "apps": [],
            "details": [{"appID": app_id, "paths": APP_LINK_PATHS}],
        }
    }


def _android_payload(
    fingerprints: list[str] | None = None,
) -> list[dict[str, Any]]:
    return [
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": "com.medicalbox.app",
                "sha256_cert_fingerprints": (
                    [FINGERPRINT] if fingerprints is None else fingerprints
                ),
            },
        }
    ]


def test_valid_release_metadata_passes() -> None:
    assert (
        validate_apple_app_site_association(
            _apple_payload(),
            f"{TEAM_ID}.com.medicalbox.app",
        )
        == f"{TEAM_ID}.com.medicalbox.app"
    )
    assert validate_android_asset_links(_android_payload(), [FINGERPRINT]) == [
        FINGERPRINT
    ]


def test_unconfigured_apple_app_id_fails_closed() -> None:
    with pytest.raises(MetadataValidationError, match="UNCONFIGURED"):
        validate_apple_app_site_association(
            _apple_payload("UNCONFIGURED.com.medicalbox.app"),
            f"{TEAM_ID}.com.medicalbox.app",
        )


def test_wildcard_apple_app_links_fail_closed() -> None:
    payload = _apple_payload()
    payload["applinks"]["details"][0]["paths"] = ["*"]

    with pytest.raises(MetadataValidationError, match="exact supported /app routes"):
        validate_apple_app_site_association(
            payload,
            f"{TEAM_ID}.com.medicalbox.app",
        )


def test_empty_android_fingerprint_list_fails_closed() -> None:
    with pytest.raises(MetadataValidationError, match="must not be empty"):
        validate_android_asset_links(_android_payload([]), [FINGERPRINT])


@pytest.mark.parametrize(
    "fingerprint",
    [
        "AA:BB",
        "0" * 64,
        ":".join(["GG"] * 32),
    ],
)
def test_invalid_android_fingerprint_fails_closed(fingerprint: str) -> None:
    with pytest.raises(MetadataValidationError, match="colon-separated"):
        validate_android_asset_links(_android_payload([fingerprint]), [FINGERPRINT])


def test_well_formed_but_unexpected_apple_app_id_fails_closed() -> None:
    with pytest.raises(MetadataValidationError, match="exactly match"):
        validate_apple_app_site_association(
            _apple_payload("ZZZZZZZZZZ.com.medicalbox.app"),
            f"{TEAM_ID}.com.medicalbox.app",
        )


def test_well_formed_but_unexpected_android_fingerprint_fails_closed() -> None:
    unexpected = ":".join(["AA"] * 32)

    with pytest.raises(MetadataValidationError, match="exactly match"):
        validate_android_asset_links(
            _android_payload([unexpected]),
            [FINGERPRINT],
        )


def test_additional_android_fingerprint_fails_exact_match() -> None:
    unexpected = ":".join(["AA"] * 32)

    with pytest.raises(MetadataValidationError, match="exactly match"):
        validate_android_asset_links(
            _android_payload([FINGERPRINT, unexpected]),
            [FINGERPRINT],
        )


def test_additional_medical_box_apple_app_id_fails_exact_match() -> None:
    payload = _apple_payload()
    payload["applinks"]["details"].append(
        {
            "appID": "ZZZZZZZZZZ.com.medicalbox.app",
            "paths": APP_LINK_PATHS,
        }
    )

    with pytest.raises(MetadataValidationError, match="exactly match"):
        validate_apple_app_site_association(
            payload,
            f"{TEAM_ID}.com.medicalbox.app",
        )


def test_cli_validates_downloaded_files(tmp_path: Path) -> None:
    apple_path = tmp_path / "apple.json"
    android_path = tmp_path / "android.json"
    apple_path.write_text(json.dumps(_apple_payload()), encoding="utf-8")
    android_path.write_text(json.dumps(_android_payload()), encoding="utf-8")
    result = subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--apple",
            str(apple_path),
            "--android",
            str(android_path),
            "--expected-apple-app-id",
            f"{TEAM_ID}.com.medicalbox.app",
            "--expected-android-fingerprint",
            FINGERPRINT,
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stderr
    assert "release_metadata_verification=passed" in result.stdout
    assert "android_fingerprint_count=1" in result.stdout


def test_production_monitor_is_manual_and_exact_only() -> None:
    workflow = (
        Path(__file__).parents[3]
        / ".github"
        / "workflows"
        / "production-monitor.yml"
    ).read_text()
    availability, manual_gate = workflow.split(
        "      - name: Verify exact release metadata\n",
        maxsplit=1,
    )

    assert "--location" not in workflow
    assert "expected_apple_app_id:" in workflow
    assert "expected_android_fingerprint:" in workflow
    assert workflow.count("required: true") == 2
    assert "application/json" in availability
    assert "schedule:" not in workflow
    assert "workflow_dispatch:" in workflow
    assert "vars.EXPECTED_APPLE_APP_ID" not in workflow
    assert "vars.EXPECTED_ANDROID_FINGERPRINT" not in workflow
    assert "\n    if:" not in availability
    assert (
        "EXPECTED_APPLE_APP_ID: ${{ inputs.expected_apple_app_id }}"
        in manual_gate
    )
    assert (
        "EXPECTED_ANDROID_FINGERPRINT: "
        "${{ inputs.expected_android_fingerprint }}"
        in manual_gate
    )
    assert "--expected-apple-app-id" in manual_gate
    assert "--expected-android-fingerprint" in manual_gate
