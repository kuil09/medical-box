import os
from collections.abc import Generator

os.environ["APP_ENV"] = "test"
os.environ["DATABASE_URL"] = "sqlite+pysqlite:///./test-medical-box.db"
os.environ["ALLOWED_HOSTS"] = "testserver,localhost,127.0.0.1"
os.environ["JWT_SECRET"] = "test-secret-that-is-long-enough-for-signing"

import pytest
from fastapi.testclient import TestClient

from medical_box_api.db import Base, engine
from medical_box_api.main import app
from medical_box_api.providers import VerifiedProviderIdentity, get_provider_validator


class FakeProviderValidator:
    def validate(self, provider: str, token: str) -> VerifiedProviderIdentity:
        return VerifiedProviderIdentity(
            subject=f"{provider}-subject",
            email=f"{provider}@example.com",
            display_name="Test User",
        )


@pytest.fixture
def client() -> Generator[TestClient]:
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    app.dependency_overrides[get_provider_validator] = lambda: FakeProviderValidator()
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
