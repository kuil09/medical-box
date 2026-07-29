"""Verify the production provider exchange and catalog entitlement boundary.

This script never prints provider, access, or refresh tokens. It is intended
for an operator-controlled test account whose provider token is passed through
the environment.
"""

import os
import sys
from dataclasses import dataclass

import httpx


@dataclass(frozen=True)
class ProbeConfig:
    api_base_url: str
    provider: str
    provider_token: str
    expect_catalog_access: bool

    @classmethod
    def from_environment(cls) -> "ProbeConfig":
        return cls(
            api_base_url=_required("MEDICAL_BOX_API_BASE_URL").rstrip("/"),
            provider=_required("MEDICAL_BOX_AUTH_PROVIDER").lower(),
            provider_token=_required("MEDICAL_BOX_PROVIDER_TOKEN"),
            expect_catalog_access=_boolean("MEDICAL_BOX_EXPECT_CATALOG_ACCESS"),
        )


def _required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise ValueError(f"{name} is required.")
    return value


def _boolean(name: str) -> bool:
    value = os.getenv(name, "false").strip().lower()
    if value not in {"true", "false"}:
        raise ValueError(f"{name} must be true or false.")
    return value == "true"


def _expect(response: httpx.Response, status_code: int, step: str) -> dict[str, object]:
    if response.status_code != status_code:
        raise RuntimeError(
            f"{step} returned HTTP {response.status_code}; expected {status_code}."
        )
    if not response.content:
        return {}
    payload = response.json()
    if not isinstance(payload, dict):
        raise RuntimeError(f"{step} did not return a JSON object.")
    return payload


def run_probe(config: ProbeConfig) -> None:
    default_headers = {"accept": "application/json"}

    with httpx.Client(
        base_url=config.api_base_url,
        headers=default_headers,
        timeout=20,
    ) as client:
        session = _expect(
            client.post(
                f"/v1/auth/exchange/{config.provider}",
                json={
                    "providerToken": config.provider_token,
                    "termsVersion": "2026-07-29",
                    "termsAccepted": True,
                    "deviceLabel": "deployment-probe",
                },
            ),
            200,
            "provider exchange",
        )
        access_token = session.get("accessToken")
        refresh_token = session.get("refreshToken")
        if not isinstance(access_token, str) or not isinstance(refresh_token, str):
            raise RuntimeError("provider exchange omitted session tokens.")

        authorization = {"authorization": f"Bearer {access_token}"}
        profile = _expect(
            client.get("/v1/me", headers=authorization),
            200,
            "account profile",
        )
        permissions = profile.get("permissions")
        if not isinstance(permissions, list):
            raise RuntimeError("account profile omitted permissions.")
        has_catalog_access = "catalog:read" in permissions
        if has_catalog_access != config.expect_catalog_access:
            raise RuntimeError(
                "catalog entitlement did not match MEDICAL_BOX_EXPECT_CATALOG_ACCESS."
            )

        expected_catalog_status = 200 if has_catalog_access else 403
        _expect(
            client.get("/v1/catalog/meta", headers=authorization),
            expected_catalog_status,
            "catalog entitlement",
        )

        replacement = _expect(
            client.post("/v1/auth/refresh", json={"refreshToken": refresh_token}),
            200,
            "refresh rotation",
        )
        replacement_refresh = replacement.get("refreshToken")
        if not isinstance(replacement_refresh, str) or replacement_refresh == refresh_token:
            raise RuntimeError("refresh rotation did not issue a replacement token.")

        _expect(
            client.post("/v1/auth/logout", json={"refreshToken": replacement_refresh}),
            204,
            "logout",
        )

    print(
        "Deployed auth probe passed: provider exchange, profile, entitlement, "
        "refresh rotation, and logout."
    )


def main() -> int:
    try:
        run_probe(ProbeConfig.from_environment())
    except (ValueError, RuntimeError, httpx.HTTPError) as error:
        print(f"Deployed auth probe failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
