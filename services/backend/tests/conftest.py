import base64
import os
from collections.abc import Generator
from datetime import UTC, datetime

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
from fastapi.testclient import TestClient

os.environ["APP_ENV"] = "test"
os.environ["DATABASE_URL"] = "sqlite+pysqlite:///./test-medical-box.db"
os.environ["ALLOWED_HOSTS"] = "testserver,localhost,127.0.0.1"
os.environ["JWT_SECRET"] = "test-secret-that-is-long-enough-for-signing"
os.environ["APPLE_SIGN_IN_ENABLED"] = "true"
os.environ["APPLE_TEAM_ID"] = "TESTTEAM01"
os.environ["APPLE_SIGN_IN_KEY_ID"] = "TESTKEY01"
_test_apple_private_key = ec.generate_private_key(ec.SECP256R1()).private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
)
os.environ["APPLE_SIGN_IN_PRIVATE_KEY_BASE64"] = base64.b64encode(_test_apple_private_key).decode(
    "ascii"
)

from medical_box_api.apple_account import get_apple_authorization_revoker  # noqa: E402
from medical_box_api.db import Base, engine  # noqa: E402
from medical_box_api.main import app  # noqa: E402
from medical_box_api.providers import (  # noqa: E402
    ProviderValidator,
    VerifiedProviderIdentity,
    get_provider_validator,
)


class FakeProviderValidator:
    def validate(self, provider: str, token: str) -> VerifiedProviderIdentity:
        return VerifiedProviderIdentity(
            subject=f"{provider}-subject",
            email=f"{provider}@example.com",
            display_name="Test User",
            email_verified=True,
            issued_at=datetime.now(UTC),
        )


class FakeAppleAuthorizationRevoker:
    def __init__(self) -> None:
        self.calls: list[tuple[str, str]] = []
        self.error: Exception | None = None

    def revoke(
        self,
        *,
        provider_subject: str,
        authorization_code: str,
        validator: ProviderValidator,
    ) -> None:
        del validator
        if self.error is not None:
            raise self.error
        self.calls.append((provider_subject, authorization_code))


@pytest.fixture
def apple_revoker() -> FakeAppleAuthorizationRevoker:
    return FakeAppleAuthorizationRevoker()


@pytest.fixture
def client(apple_revoker: FakeAppleAuthorizationRevoker) -> Generator[TestClient]:
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    app.dependency_overrides[get_provider_validator] = lambda: FakeProviderValidator()
    app.dependency_overrides[get_apple_authorization_revoker] = lambda: apple_revoker
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
