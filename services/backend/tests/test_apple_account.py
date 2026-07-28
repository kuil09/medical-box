import base64
from urllib.parse import parse_qs

import httpx
import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi import HTTPException

from medical_box_api.apple_account import (
    APPLE_REVOKE_URL,
    APPLE_TOKEN_URL,
    OfficialAppleAuthorizationRevoker,
)
from medical_box_api.config import Settings
from medical_box_api.providers import VerifiedProviderIdentity


class StaticAppleValidator:
    def __init__(self, subject: str = "apple-subject") -> None:
        self.subject = subject
        self.calls: list[tuple[str, str]] = []

    def validate(self, provider: str, token: str) -> VerifiedProviderIdentity:
        self.calls.append((provider, token))
        return VerifiedProviderIdentity(
            subject=self.subject,
            email=None,
            display_name=None,
        )


class SensitiveFailureAppleValidator:
    def validate(self, provider: str, token: str) -> VerifiedProviderIdentity:
        del provider
        try:
            raise ValueError(f"Rejected sensitive token: {token}")
        except ValueError as exc:
            raise HTTPException(
                status_code=401,
                detail=f"Sensitive validation failure: {token}",
            ) from exc


def apple_settings() -> Settings:
    private_key = ec.generate_private_key(ec.SECP256R1())
    private_key_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    return Settings(
        _env_file=None,
        apple_client_id="com.medicalbox.app",
        apple_team_id="TESTTEAM",
        apple_sign_in_key_id="TESTKEY",
        apple_sign_in_private_key_base64=base64.b64encode(private_key_pem).decode(
            "ascii"
        ),
    )


def form_data(request: httpx.Request) -> dict[str, str]:
    return {
        key: values[0]
        for key, values in parse_qs(request.content.decode("utf-8")).items()
    }


def test_apple_authorization_exchange_and_revocation() -> None:
    requests: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        payload = form_data(request)
        assert payload["client_id"] == "com.medicalbox.app"
        if str(request.url) == APPLE_TOKEN_URL:
            assert payload["code"] == "one-time-code"
            assert payload["grant_type"] == "authorization_code"
            client_secret = payload["client_secret"]
            assert jwt.get_unverified_header(client_secret)["kid"] == "TESTKEY"
            claims = jwt.decode(
                client_secret,
                options={"verify_signature": False},
                algorithms=["ES256"],
            )
            assert claims["iss"] == "TESTTEAM"
            assert claims["sub"] == "com.medicalbox.app"
            assert claims["aud"] == "https://appleid.apple.com"
            return httpx.Response(
                200,
                json={
                    "id_token": "apple-identity-token",
                    "refresh_token": "apple-refresh-token",
                },
            )
        assert str(request.url) == APPLE_REVOKE_URL
        assert payload["token"] == "apple-refresh-token"
        assert payload["token_type_hint"] == "refresh_token"
        return httpx.Response(200)

    validator = StaticAppleValidator()
    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        OfficialAppleAuthorizationRevoker(
            apple_settings(),
            client=client,
        ).revoke(
            provider_subject="apple-subject",
            authorization_code="one-time-code",
            validator=validator,
        )

    assert validator.calls == [("apple", "apple-identity-token")]
    assert [str(request.url) for request in requests] == [
        APPLE_TOKEN_URL,
        APPLE_REVOKE_URL,
    ]


def test_apple_authorization_uses_access_token_when_refresh_is_absent() -> None:
    revocation_form: dict[str, str] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        if str(request.url) == APPLE_TOKEN_URL:
            return httpx.Response(
                200,
                json={
                    "id_token": "apple-identity-token",
                    "access_token": "apple-access-token",
                },
            )
        revocation_form.update(form_data(request))
        return httpx.Response(200)

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        OfficialAppleAuthorizationRevoker(
            apple_settings(),
            client=client,
        ).revoke(
            provider_subject="apple-subject",
            authorization_code="one-time-code",
            validator=StaticAppleValidator(),
        )

    assert revocation_form["token"] == "apple-access-token"
    assert revocation_form["token_type_hint"] == "access_token"


def test_apple_authorization_subject_mismatch_stops_before_revocation() -> None:
    request_urls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        request_urls.append(str(request.url))
        return httpx.Response(
            200,
            json={
                "id_token": "apple-identity-token",
                "refresh_token": "apple-refresh-token",
            },
        )

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        revoker = OfficialAppleAuthorizationRevoker(apple_settings(), client=client)
        with pytest.raises(HTTPException) as exc_info:
            revoker.revoke(
                provider_subject="linked-subject",
                authorization_code="one-time-code",
                validator=StaticAppleValidator("different-subject"),
            )

    assert exc_info.value.status_code == 403
    assert request_urls == [APPLE_TOKEN_URL]


@pytest.mark.parametrize(
    ("token_payload", "expected_detail"),
    [
        (
            {"refresh_token": "apple-refresh-token"},
            "Apple did not return an identity token.",
        ),
        (
            {"id_token": "apple-identity-token"},
            "Apple did not return a revocable token.",
        ),
    ],
)
def test_apple_authorization_rejects_incomplete_token_response(
    token_payload: dict[str, str],
    expected_detail: str,
) -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(200, json=token_payload)

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        revoker = OfficialAppleAuthorizationRevoker(apple_settings(), client=client)
        with pytest.raises(HTTPException) as exc_info:
            revoker.revoke(
                provider_subject="apple-subject",
                authorization_code="one-time-code",
                validator=StaticAppleValidator(),
            )

    assert exc_info.value.status_code == 502
    assert exc_info.value.detail == expected_detail


def test_apple_authorization_requires_valid_server_credentials() -> None:
    sensitive_invalid_key = "sensitive-invalid-apple-private-key"
    settings = Settings(
        _env_file=None,
        apple_team_id="TESTTEAM",
        apple_sign_in_key_id="TESTKEY",
        apple_sign_in_private_key_base64=sensitive_invalid_key,
    )
    revoker = OfficialAppleAuthorizationRevoker(settings)

    with pytest.raises(HTTPException) as exc_info:
        revoker.revoke(
            provider_subject="apple-subject",
            authorization_code="one-time-code",
            validator=StaticAppleValidator(),
        )

    assert exc_info.value.status_code == 503
    assert exc_info.value.detail == "Apple account revocation key is invalid."
    assert sensitive_invalid_key not in str(exc_info.value)
    assert exc_info.value.__cause__ is None
    assert exc_info.value.__context__ is None


def test_apple_invalid_json_does_not_retain_sensitive_response() -> None:
    sensitive_response = "sensitive-token-response"

    def handler(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(
            200,
            content=f'{{"id_token":"{sensitive_response}"',
            headers={"content-type": "application/json"},
        )

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        revoker = OfficialAppleAuthorizationRevoker(apple_settings(), client=client)
        with pytest.raises(HTTPException) as exc_info:
            revoker.revoke(
                provider_subject="apple-subject",
                authorization_code="sensitive-one-time-code",
                validator=StaticAppleValidator(),
            )

    assert exc_info.value.status_code == 502
    assert exc_info.value.detail == "Apple returned an invalid token response."
    assert sensitive_response not in str(exc_info.value)
    assert exc_info.value.__cause__ is None
    assert exc_info.value.__context__ is None


def test_apple_validator_failure_does_not_retain_sensitive_identity_token() -> None:
    sensitive_id_token = "sensitive-apple-identity-token"

    def handler(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(
            200,
            json={
                "id_token": sensitive_id_token,
                "refresh_token": "sensitive-apple-refresh-token",
            },
        )

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        revoker = OfficialAppleAuthorizationRevoker(apple_settings(), client=client)
        with pytest.raises(HTTPException) as exc_info:
            revoker.revoke(
                provider_subject="apple-subject",
                authorization_code="sensitive-one-time-code",
                validator=SensitiveFailureAppleValidator(),
            )

    assert exc_info.value.status_code == 502
    assert exc_info.value.detail == "Apple returned an unverifiable identity token."
    assert sensitive_id_token not in str(exc_info.value)
    assert exc_info.value.__cause__ is None
    assert exc_info.value.__context__ is None


def test_apple_provider_http_failure_is_generic() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        del request
        return httpx.Response(400, json={"error": "invalid_grant"})

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        revoker = OfficialAppleAuthorizationRevoker(apple_settings(), client=client)
        with pytest.raises(HTTPException) as exc_info:
            revoker.revoke(
                provider_subject="apple-subject",
                authorization_code="sensitive-one-time-code",
                validator=StaticAppleValidator(),
            )

    assert exc_info.value.status_code == 502
    assert exc_info.value.detail == "Apple account revocation failed."
    assert "sensitive-one-time-code" not in str(exc_info.value)
    assert exc_info.value.__cause__ is None
    assert exc_info.value.__context__ is None


def test_apple_provider_transport_failure_does_not_retain_sensitive_request() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("Network unavailable.", request=request)

    with httpx.Client(transport=httpx.MockTransport(handler)) as client:
        revoker = OfficialAppleAuthorizationRevoker(apple_settings(), client=client)
        with pytest.raises(HTTPException) as exc_info:
            revoker.revoke(
                provider_subject="apple-subject",
                authorization_code="sensitive-one-time-code",
                validator=StaticAppleValidator(),
            )

    assert exc_info.value.status_code == 502
    assert exc_info.value.detail == "Apple account revocation failed."
    assert exc_info.value.__cause__ is None
    assert exc_info.value.__context__ is None
