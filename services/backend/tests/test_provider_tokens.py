from datetime import UTC, datetime, timedelta
from types import SimpleNamespace

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException

from medical_box_api.config import Settings
from medical_box_api.providers import OfficialProviderValidator

PROVIDERS = [
    ("google", "https://accounts.google.com", "google-client"),
    ("apple", "https://appleid.apple.com", "com.medicalbox.app"),
    ("kakao", "https://kauth.kakao.com", "kakao-client"),
]


@pytest.fixture
def validator(monkeypatch: pytest.MonkeyPatch) -> tuple[OfficialProviderValidator, object]:
    signing_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)

    class FakeJwkClient:
        def __init__(self, url: str, cache_keys: bool) -> None:
            self.url = url
            self.cache_keys = cache_keys

        def get_signing_key_from_jwt(self, token: str) -> SimpleNamespace:
            return SimpleNamespace(key=signing_key.public_key())

    monkeypatch.setattr(jwt, "PyJWKClient", FakeJwkClient)
    settings = Settings(
        app_env="test",
        google_client_id="google-client",
        apple_client_id="com.medicalbox.app",
        kakao_app_id="kakao-client",
    )
    return OfficialProviderValidator(settings), signing_key


@pytest.mark.parametrize(("provider", "issuer", "audience"), PROVIDERS)
def test_provider_tokens_require_valid_signature_issuer_audience_and_expiry(
    validator: tuple[OfficialProviderValidator, object],
    provider: str,
    issuer: str,
    audience: str,
) -> None:
    verifier, signing_key = validator
    now = datetime.now(UTC)
    base_claims = {
        "sub": f"{provider}-subject",
        "iss": issuer,
        "aud": audience,
        "iat": now,
        "auth_time": int((now - timedelta(minutes=1)).timestamp()),
        "exp": now + timedelta(minutes=5),
        "email": f"{provider}@example.com",
        "email_verified": "true" if provider == "apple" else True,
        "name": "Test User",
    }

    valid = jwt.encode(base_claims, signing_key, algorithm="RS256")
    identity = verifier.validate(provider, valid)
    assert identity.subject == f"{provider}-subject"
    assert identity.email_verified
    assert identity.issued_at is not None
    assert identity.authenticated_at is not None
    assert int(identity.issued_at.timestamp()) == int(now.timestamp())
    assert int(identity.authenticated_at.timestamp()) == int(
        (now - timedelta(minutes=1)).timestamp()
    )

    invalid_claims = [
        {**base_claims, "aud": "wrong-audience"},
        {**base_claims, "iss": "https://invalid.example"},
        {**base_claims, "exp": now - timedelta(seconds=1)},
        {**base_claims, "auth_time": "not-a-numeric-date"},
    ]
    forged_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    invalid_tokens = [
        *(jwt.encode(claims, signing_key, algorithm="RS256") for claims in invalid_claims),
        jwt.encode(base_claims, forged_key, algorithm="RS256"),
    ]

    for token in invalid_tokens:
        with pytest.raises(HTTPException) as error:
            verifier.validate(provider, token)
        assert error.value.status_code == 401


@pytest.mark.parametrize(
    (
        "provider",
        "issuer",
        "audience",
        "include_verification_claim",
        "verification_claim",
        "email",
        "expected",
    ),
    [
        (
            "google",
            "https://accounts.google.com",
            "google-client",
            True,
            True,
            "g@example.com",
            True,
        ),
        ("kakao", "https://kauth.kakao.com", "kakao-client", True, True, "k@example.com", True),
        (
            "apple",
            "https://appleid.apple.com",
            "com.medicalbox.app",
            True,
            "true",
            "a@example.com",
            True,
        ),
        (
            "apple",
            "https://appleid.apple.com",
            "com.medicalbox.app",
            True,
            True,
            "a@example.com",
            True,
        ),
        (
            "google",
            "https://accounts.google.com",
            "google-client",
            True,
            False,
            "g@example.com",
            False,
        ),
        (
            "google",
            "https://accounts.google.com",
            "google-client",
            False,
            None,
            "g@example.com",
            False,
        ),
        (
            "google",
            "https://accounts.google.com",
            "google-client",
            True,
            "true",
            "g@example.com",
            False,
        ),
        (
            "apple",
            "https://appleid.apple.com",
            "com.medicalbox.app",
            True,
            "TRUE",
            "a@example.com",
            False,
        ),
        (
            "kakao",
            "https://kauth.kakao.com",
            "kakao-client",
            True,
            1,
            "k@example.com",
            False,
        ),
        (
            "google",
            "https://accounts.google.com",
            "google-client",
            True,
            True,
            None,
            False,
        ),
    ],
)
def test_provider_email_verification_claims_are_parsed_fail_closed(
    validator: tuple[OfficialProviderValidator, object],
    provider: str,
    issuer: str,
    audience: str,
    include_verification_claim: bool,
    verification_claim: object,
    email: str | None,
    expected: bool,
) -> None:
    verifier, signing_key = validator
    now = datetime.now(UTC)
    claims: dict[str, object] = {
        "sub": f"{provider}-subject",
        "iss": issuer,
        "aud": audience,
        "iat": now,
        "exp": now + timedelta(minutes=5),
    }
    if email is not None:
        claims["email"] = email
    if include_verification_claim:
        claims["email_verified"] = verification_claim

    token = jwt.encode(claims, signing_key, algorithm="RS256")
    identity = verifier.validate(provider, token)

    assert identity.email == email
    assert identity.email_verified is expected
