import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from pydantic import SecretStr, ValidationError
from sqlalchemy import inspect, select

from medical_box_api.config import Settings, get_settings
from medical_box_api.db import SessionLocal, engine
from medical_box_api.main import app
from medical_box_api.models import (
    DrugCode,
    DrugConsumerInfo,
    DrugIdentification,
    DrugIdentificationVariant,
    DrugIngredient,
    DrugPrice,
    DrugProduct,
    DrugStatusEvent,
    DurRule,
    SourceRecord,
    SourceRegistry,
    SyncRun,
    TermsAcceptance,
    User,
)
from medical_box_api.providers import (
    VerifiedProviderIdentity,
    get_provider_validator,
)
from medical_box_api.security import create_reauth_grant


def create_account(
    client: TestClient,
    provider: str = "google",
) -> dict[str, object]:
    response = client.post(
        f"/api/v1/auth/exchange/{provider}",
        json={
            "providerToken": f"valid-{provider}-token",
            "termsVersion": "2026-07-29",
            "termsAccepted": True,
            "deviceLabel": "iPhone",
        },
    )
    assert response.status_code == 200
    return response.json()


def test_railway_postgres_url_uses_psycopg_v3() -> None:
    settings = Settings(
        database_url="postgresql://user:password@postgres.railway.internal:5432/railway"
    )
    assert settings.database_url.startswith("postgresql+psycopg://")


def test_production_catalog_worker_requires_postgres_but_not_api_jwt_secret() -> None:
    worker_settings = Settings(
        _env_file=None,
        app_env="production",
        app_role="catalog_sync",
        database_url="postgresql://catalog:catalog@postgres/medical_box",
    )
    assert worker_settings.app_role == "catalog_sync"

    with pytest.raises(ValidationError, match="DATABASE_URL"):
        Settings(
            _env_file=None,
            app_env="production",
            app_role="catalog_sync",
            database_url="sqlite+pysqlite:///./catalog.db",
        )

    with pytest.raises(ValidationError, match="JWT_SECRET"):
        Settings(
            _env_file=None,
            app_env="production",
            app_role="api",
            database_url="postgresql://user:password@postgres/medical_box",
            jwt_secret="short",
        )


@pytest.mark.parametrize(
    "jwt_secret",
    [
        "development-only-secret-change-before-deploy",
        "replace-with-at-least-32-random-characters",
    ],
)
def test_production_api_rejects_public_jwt_placeholders(jwt_secret: str) -> None:
    with pytest.raises(ValidationError, match="non-placeholder"):
        Settings(
            _env_file=None,
            app_env="production",
            app_role="api",
            database_url="postgresql://user:password@postgres/medical_box",
            jwt_secret=jwt_secret,
        )


def test_production_api_requires_postgresql() -> None:
    with pytest.raises(ValidationError, match="DATABASE_URL"):
        Settings(
            _env_file=None,
            app_env="production",
            app_role="api",
            database_url="sqlite+pysqlite:///./production.db",
            jwt_secret="a-production-only-secret-that-is-long-enough",
        )


def test_production_api_accepts_explicit_postgresql_and_jwt_secret() -> None:
    settings = Settings(
        _env_file=None,
        app_env="production",
        app_role="api",
        database_url="postgresql://user:password@postgres/medical_box",
        jwt_secret="a-production-only-secret-that-is-long-enough",
    )

    assert settings.database_url.startswith("postgresql+psycopg://")


def test_web_health_and_security_headers(client: TestClient) -> None:
    for path in ["/", "/privacy", "/terms", "/support", "/account-deletion"]:
        response = client.get(path)
        assert response.status_code == 200
        assert "우리집 구급키트" in response.text
    account_deletion = client.get("/account-deletion")
    assert "설정 → 로그인 및 검색 권한 → 서버 계정 삭제" in account_deletion.text
    privacy = client.get("/privacy")
    assert "검색어 또는 공개 품목기준코드(itemSeq)" in privacy.text
    assert "기기 안의 보관 정보와 결합하거나 영구 저장하지 않습니다." in privacy.text
    live = client.get("/api/health/live")
    ready = client.get("/api/health/ready")
    assert live.json() == {"status": "ok"}
    assert ready.json() == {"status": "ready"}
    assert live.headers["x-content-type-options"] == "nosniff"
    assert "max-age=31536000" in live.headers["strict-transport-security"]
    assert "시행일: 2026-07-29" in client.get("/terms").text


def test_support_and_external_deletion_contact_are_configuration_gated(
    client: TestClient,
) -> None:
    settings = get_settings()
    previous_email = settings.support_email
    try:
        settings.support_email = None
        unavailable = client.get("/account-deletion")
        assert "외부 요청 연락처가 아직 구성되지 않았습니다." in unavailable.text

        settings.support_email = "helpdesk@example.com"
        support = client.get("/support")
        deletion = client.get("/account-deletion")
    finally:
        settings.support_email = previous_email

    assert "mailto:helpdesk@example.com" in support.text
    assert "mailto:helpdesk@example.com" in deletion.text
    assert "비밀번호, 인증 토큰, 의약품 또는 건강 정보는 보내지 마세요." in deletion.text
    assert "운영자가 원격으로 삭제할 수 없습니다." in deletion.text


def test_support_email_rejects_header_injection() -> None:
    with pytest.raises(ValidationError, match="SUPPORT_EMAIL"):
        Settings(
            _env_file=None,
            support_email="support@example.com\r\nBcc: attacker@example.com",
        )


@pytest.mark.parametrize(
    "payload",
    [
        {
            "providerToken": "valid-google-token",
            "termsVersion": "2026-07-29",
        },
        {
            "providerToken": "valid-google-token",
            "termsVersion": "2026-07-29",
            "termsAccepted": False,
        },
    ],
)
def test_auth_exchange_requires_explicit_terms_acceptance(
    client: TestClient,
    payload: dict[str, object],
) -> None:
    response = client.post("/api/v1/auth/exchange/google", json=payload)

    assert response.status_code == 422
    with SessionLocal() as db:
        assert db.scalar(select(User)) is None
        assert db.scalar(select(TermsAcceptance)) is None


def test_auth_exchange_rejects_stale_terms_without_creating_account(
    client: TestClient,
) -> None:
    response = client.post(
        "/api/v1/auth/exchange/google",
        json={
            "providerToken": "valid-google-token",
            "termsVersion": "2026-07-24",
            "termsAccepted": True,
        },
    )

    assert response.status_code == 409
    assert response.json()["detail"] == ("The current terms must be accepted before sign-in.")
    with SessionLocal() as db:
        assert db.scalar(select(User)) is None
        assert db.scalar(select(TermsAcceptance)) is None


def test_valid_auth_exchange_records_current_terms_acceptance(
    client: TestClient,
) -> None:
    create_account(client)

    with SessionLocal() as db:
        acceptance = db.scalar(select(TermsAcceptance))
        assert acceptance is not None
        assert acceptance.version == "2026-07-29"


@pytest.mark.parametrize(
    "missing_field",
    [
        "apple_client_id",
        "apple_team_id",
        "apple_sign_in_key_id",
        "apple_sign_in_private_key_base64",
    ],
)
def test_apple_revocation_configuration_requires_every_value(
    missing_field: str,
) -> None:
    values: dict[str, object] = {
        "apple_client_id": "com.medicalbox.app",
        "apple_team_id": "TESTTEAM01",
        "apple_sign_in_key_id": "TESTKEY01",
        "apple_sign_in_private_key_base64": "dGVzdC1wcml2YXRlLWtleQ==",
    }
    values[missing_field] = ""

    settings = Settings(_env_file=None, **values)

    assert not settings.apple_account_revocation_configured


def test_apple_exchange_requires_explicit_lifecycle_activation(
    client: TestClient,
) -> None:
    settings = get_settings()
    previous_enabled = settings.apple_sign_in_enabled
    try:
        settings.apple_sign_in_enabled = False
        response = client.post(
            "/api/v1/auth/exchange/apple",
            json={
                "providerToken": "valid-apple-token",
                "termsVersion": "2026-07-29",
                "termsAccepted": True,
            },
        )
    finally:
        settings.apple_sign_in_enabled = previous_enabled

    assert response.status_code == 503
    assert response.json()["detail"] == (
        "Apple sign-in is unavailable until account deletion is configured."
    )
    with SessionLocal() as db:
        assert db.scalar(select(User)) is None
        assert db.scalar(select(TermsAcceptance)) is None


def test_apple_exchange_requires_complete_account_revocation_configuration(
    client: TestClient,
) -> None:
    settings = get_settings()
    previous_team_id = settings.apple_team_id
    previous_key_id = settings.apple_sign_in_key_id
    previous_private_key = settings.apple_sign_in_private_key_base64
    try:
        settings.apple_sign_in_key_id = None
        response = client.post(
            "/api/v1/auth/exchange/apple",
            json={
                "providerToken": "valid-apple-token",
                "termsVersion": "2026-07-29",
                "termsAccepted": True,
            },
        )
    finally:
        settings.apple_team_id = previous_team_id
        settings.apple_sign_in_key_id = previous_key_id
        settings.apple_sign_in_private_key_base64 = previous_private_key

    assert response.status_code == 503
    assert response.json()["detail"] == (
        "Apple sign-in is unavailable until account deletion is configured."
    )
    with SessionLocal() as db:
        assert db.scalar(select(User)) is None
        assert db.scalar(select(TermsAcceptance)) is None


def test_apple_exchange_rejects_invalid_revocation_key_before_account_creation(
    client: TestClient,
) -> None:
    settings = get_settings()
    previous_private_key = settings.apple_sign_in_private_key_base64
    try:
        settings.apple_sign_in_private_key_base64 = SecretStr("sensitive-invalid-apple-private-key")
        response = client.post(
            "/api/v1/auth/exchange/apple",
            json={
                "providerToken": "valid-apple-token",
                "termsVersion": "2026-07-29",
                "termsAccepted": True,
            },
        )
    finally:
        settings.apple_sign_in_private_key_base64 = previous_private_key

    assert response.status_code == 503
    assert response.json()["detail"] == "Apple account revocation key is invalid."
    assert "sensitive-invalid-apple-private-key" not in response.text
    with SessionLocal() as db:
        assert db.scalar(select(User)) is None
        assert db.scalar(select(TermsAcceptance)) is None


def test_auth_refresh_profile_reauth_and_delete(client: TestClient) -> None:
    session = create_account(client)
    access = session["accessToken"]
    refresh = session["refreshToken"]
    headers = {"Authorization": f"Bearer {access}"}

    profile = client.get("/api/v1/me", headers=headers)
    assert profile.status_code == 200
    assert profile.json()["providers"] == ["google"]
    assert profile.json()["permissions"] == []

    updated = client.patch(
        "/api/v1/me",
        headers=headers,
        json={"displayName": "Household Owner"},
    )
    assert updated.status_code == 200
    assert updated.json()["displayName"] == "Household Owner"

    rotated = client.post("/api/v1/auth/refresh", json={"refreshToken": refresh})
    assert rotated.status_code == 200
    assert rotated.json()["refreshToken"] != refresh

    reused = client.post("/api/v1/auth/refresh", json={"refreshToken": refresh})
    assert reused.status_code == 401

    fresh = create_account(client)
    fresh_headers = {"Authorization": f"Bearer {fresh['accessToken']}"}
    reauth = client.post(
        "/api/v1/auth/reauth/google",
        headers=fresh_headers,
        json={"providerToken": "valid-google-token"},
    )
    assert reauth.status_code == 200
    deleted = client.request(
        "DELETE",
        "/api/v1/me",
        headers=fresh_headers,
        json={"reauthGrant": reauth.json()["grant"]},
    )
    assert deleted.status_code == 204
    assert client.get("/api/v1/me", headers=fresh_headers).status_code == 401


def test_logout_with_rotated_token_revokes_active_refresh_family(
    client: TestClient,
) -> None:
    session = create_account(client)
    original_refresh = session["refreshToken"]
    rotated = client.post(
        "/api/v1/auth/refresh",
        json={"refreshToken": original_refresh},
    )
    assert rotated.status_code == 200

    logged_out = client.post(
        "/api/v1/auth/logout",
        json={"refreshToken": original_refresh},
    )
    assert logged_out.status_code == 204

    replacement_refresh = rotated.json()["refreshToken"]
    rejected = client.post(
        "/api/v1/auth/refresh",
        json={"refreshToken": replacement_refresh},
    )
    assert rejected.status_code == 401


@pytest.mark.parametrize(
    ("issued_age", "authentication_age"),
    [
        (timedelta(minutes=6), None),
        (timedelta(), timedelta(minutes=6)),
    ],
)
def test_reauth_rejects_stale_provider_proof_but_exchange_accepts_it(
    client: TestClient,
    issued_age: timedelta,
    authentication_age: timedelta | None,
) -> None:
    now = datetime.now(UTC)
    issued_at = now - issued_age
    authenticated_at = None if authentication_age is None else now - authentication_age

    class StaleProviderValidator:
        def validate(
            self,
            provider: str,
            token: str,
        ) -> VerifiedProviderIdentity:
            del token
            return VerifiedProviderIdentity(
                subject=f"{provider}-subject",
                email=f"{provider}@example.com",
                display_name="Test User",
                issued_at=issued_at,
                authenticated_at=authenticated_at,
            )

    previous_override = app.dependency_overrides[get_provider_validator]
    app.dependency_overrides[get_provider_validator] = StaleProviderValidator
    try:
        session = create_account(client)
        headers = {"Authorization": f"Bearer {session['accessToken']}"}
        reauth = client.post(
            "/api/v1/auth/reauth/google",
            headers=headers,
            json={"providerToken": "stale-google-token"},
        )
    finally:
        app.dependency_overrides[get_provider_validator] = previous_override

    assert reauth.status_code == 401
    assert reauth.json()["detail"] == ("A recent provider proof is required for reauthentication.")


def test_delete_rejects_apple_code_for_google_and_preserves_account(
    client: TestClient,
) -> None:
    session = create_account(client)
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    reauth = client.post(
        "/api/v1/auth/reauth/google",
        headers=headers,
        json={"providerToken": "valid-google-token"},
    )

    deleted = client.request(
        "DELETE",
        "/api/v1/me",
        headers=headers,
        json={
            "reauthGrant": reauth.json()["grant"],
            "appleAuthorizationCode": "unexpected-apple-code",
        },
    )

    assert deleted.status_code == 400
    assert client.get("/api/v1/me", headers=headers).status_code == 200


def test_delete_rejects_grant_for_unlinked_provider(
    client: TestClient,
) -> None:
    session = create_account(client)
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    grant = create_reauth_grant(
        uuid.UUID(str(session["account"]["id"])),
        "apple",
        get_settings(),
    )

    deleted = client.request(
        "DELETE",
        "/api/v1/me",
        headers=headers,
        json={
            "reauthGrant": grant,
            "appleAuthorizationCode": "one-time-authorization-code",
        },
    )

    assert deleted.status_code == 403
    assert client.get("/api/v1/me", headers=headers).status_code == 200


def test_apple_delete_requires_authorization_code_and_preserves_account(
    client: TestClient,
) -> None:
    session = create_account(client, "apple")
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    reauth = client.post(
        "/api/v1/auth/reauth/apple",
        headers=headers,
        json={"providerToken": "valid-apple-token"},
    )

    deleted = client.request(
        "DELETE",
        "/api/v1/me",
        headers=headers,
        json={"reauthGrant": reauth.json()["grant"]},
    )

    assert deleted.status_code == 400
    assert client.get("/api/v1/me", headers=headers).status_code == 200


def test_apple_revocation_failure_preserves_account(
    client: TestClient,
    apple_revoker,
) -> None:
    apple_revoker.error = HTTPException(
        status_code=502,
        detail="Apple account revocation failed.",
    )
    session = create_account(client, "apple")
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    reauth = client.post(
        "/api/v1/auth/reauth/apple",
        headers=headers,
        json={"providerToken": "valid-apple-token"},
    )

    deleted = client.request(
        "DELETE",
        "/api/v1/me",
        headers=headers,
        json={
            "reauthGrant": reauth.json()["grant"],
            "appleAuthorizationCode": "one-time-authorization-code",
        },
    )

    assert deleted.status_code == 502
    assert apple_revoker.calls == []
    assert client.get("/api/v1/me", headers=headers).status_code == 200


def test_apple_revocation_success_deletes_account(
    client: TestClient,
    apple_revoker,
) -> None:
    session = create_account(client, "apple")
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    reauth = client.post(
        "/api/v1/auth/reauth/apple",
        headers=headers,
        json={"providerToken": "valid-apple-token"},
    )

    deleted = client.request(
        "DELETE",
        "/api/v1/me",
        headers=headers,
        json={
            "reauthGrant": reauth.json()["grant"],
            "appleAuthorizationCode": "one-time-authorization-code",
        },
    )

    assert deleted.status_code == 204
    assert apple_revoker.calls == [("apple-subject", "one-time-authorization-code")]
    assert client.get("/api/v1/me", headers=headers).status_code == 401


def test_verified_allowlisted_email_receives_catalog_access(client: TestClient) -> None:
    settings = get_settings()
    previous_allowlist = settings.catalog_access_email_allowlist
    settings.catalog_access_email_allowlist = "GOOGLE@EXAMPLE.COM"
    try:
        session = create_account(client)
    finally:
        settings.catalog_access_email_allowlist = previous_allowlist

    assert session["account"]["permissions"] == ["catalog:read"]
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    assert client.get("/api/v1/catalog/meta", headers=headers).status_code == 200


def test_unverified_allowlisted_email_does_not_receive_catalog_access(
    client: TestClient,
) -> None:
    class UnverifiedProviderValidator:
        def validate(
            self,
            provider: str,
            token: str,
        ) -> VerifiedProviderIdentity:
            del token
            return VerifiedProviderIdentity(
                subject=f"{provider}-subject",
                email=f"{provider}@example.com",
                display_name="Test User",
                email_verified=False,
                issued_at=datetime.now(UTC),
            )

    settings = get_settings()
    previous_allowlist = settings.catalog_access_email_allowlist
    previous_override = app.dependency_overrides[get_provider_validator]
    settings.catalog_access_email_allowlist = "GOOGLE@EXAMPLE.COM"
    app.dependency_overrides[get_provider_validator] = UnverifiedProviderValidator
    try:
        session = create_account(client)
    finally:
        app.dependency_overrides[get_provider_validator] = previous_override
        settings.catalog_access_email_allowlist = previous_allowlist

    assert session["account"]["permissions"] == []
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    assert client.get("/api/v1/catalog/meta", headers=headers).status_code == 403


def test_catalog_search_trims_and_escapes_like_wildcards(
    client: TestClient,
) -> None:
    with SessionLocal() as db:
        db.add_all(
            [
                DrugProduct(
                    item_seq="literal-wildcard",
                    item_name=r"Literal %_ marker",
                    manufacturer=r"Maker \_%",
                ),
                DrugProduct(
                    item_seq="ordinary-product",
                    item_name="Ordinary medicine",
                    manufacturer="Ordinary maker",
                ),
                SourceRecord(
                    source_code="mfds_product",
                    record_key="literal-wildcard",
                    content_hash="literal-wildcard-hash",
                    public_data={},
                    active=True,
                    last_seen_run_id=uuid.uuid4(),
                ),
                SourceRecord(
                    source_code="mfds_product",
                    record_key="ordinary-product",
                    content_hash="ordinary-product-hash",
                    public_data={},
                    active=True,
                    last_seen_run_id=uuid.uuid4(),
                ),
            ]
        )
        db.commit()

    session = create_account(client)
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    with SessionLocal() as db:
        user = db.get(User, uuid.UUID(session["account"]["id"]))
        assert user is not None
        user.catalog_read_enabled = True
        db.commit()

    whitespace = client.get(
        "/api/v1/drugs/search",
        params={"q": "  "},
        headers=headers,
    )
    literal_wildcards = client.get(
        "/api/v1/drugs/search",
        params={"q": "  %_  "},
        headers=headers,
    )

    assert whitespace.status_code == 400
    assert literal_wildcards.status_code == 200
    assert [item["itemSeq"] for item in literal_wildcards.json()["items"]] == ["literal-wildcard"]


def test_catalog_search_and_detail(client: TestClient) -> None:
    with SessionLocal() as db:
        product = DrugProduct(
            item_seq="200000001",
            item_name="테스트 효소제",
            manufacturer="테스트제약",
            status="정상",
            storage_method="실온 보관",
            professional_category="일반의약품",
            appearance="흰색 장방형 필름코팅정",
            source_updated_at="20260725",
        )
        product.ingredients.append(DrugIngredient(name="테스트성분"))
        product.consumer_info = DrugConsumerInfo(
            efficacy="소화 불편 시 참고하는 공식 정보",
            use_method="제품 설명서를 확인하세요.",
        )
        db.add(product)
        product_source_record = SourceRecord(
            source_code="mfds_product",
            record_key="200000001",
            content_hash="product-hash",
            public_data={"ITEM_SEQ": "200000001"},
            active=True,
            last_seen_run_id=uuid.uuid4(),
        )
        pill_source_record = SourceRecord(
            source_code="mfds_pill",
            record_key="200000001|primary",
            content_hash="pill-hash",
            public_data={},
            last_seen_run_id=uuid.uuid4(),
        )
        pregnancy_run_id = uuid.uuid4()
        concomitant_run_id = uuid.uuid4()
        failed_run_id = uuid.uuid4()
        failed_status_run_id = uuid.uuid4()
        recall_run_id = uuid.uuid4()
        price_run_id = uuid.uuid4()
        code_run_id = uuid.uuid4()
        catalog_seen_at = datetime(2026, 7, 26, 3, 10, tzinfo=UTC)
        pregnancy_source_record = SourceRecord(
            source_code="mfds_dur_product_pregnancy",
            record_key="pregnancy-1",
            content_hash="pregnancy-hash",
            public_data={
                "TYPE_NAME": "임부금기",
                "INGR_NAME": "테스트성분",
                "PROHBT_CONTENT": "공식 금기 내용",
                "NOTIFICATION_DATE": "20260725",
            },
            last_seen_run_id=pregnancy_run_id,
        )
        concomitant_source_record = SourceRecord(
            source_code="mfds_dur_product_concomitant",
            record_key="concomitant-1",
            content_hash="concomitant-hash",
            public_data={
                "TYPE_NAME": "병용금기",
                "INGR_KOR_NAME": "테스트성분",
                "MIXTURE_ITEM_SEQ": "200000002",
                "MIXTURE_ITEM_NAME": "상대 의약품",
                "MIXTURE_INGR_KOR_NAME": "상대성분",
                "PROHBT_CONTENT": "함께 사용하지 않음",
            },
            last_seen_run_id=concomitant_run_id,
        )
        failed_source_record = SourceRecord(
            source_code="mfds_dur_product_elderly",
            record_key="failed-1",
            content_hash="failed-hash",
            public_data={"TYPE_NAME": "노인주의"},
            last_seen_run_id=failed_run_id,
        )
        recall_source_record = SourceRecord(
            source_code="mfds_recall",
            record_key="recall-1",
            content_hash="recall-hash",
            public_data={
                "RTRVL_RESN": "품질 기준 확인을 위한 공식 회수",
                "UPDATE_DATE": "20260726",
            },
            active=True,
            last_seen_run_id=recall_run_id,
            last_seen_at=catalog_seen_at,
        )
        inactive_recall_source_record = SourceRecord(
            source_code="mfds_recall",
            record_key="recall-inactive",
            content_hash="inactive-recall-hash",
            public_data={"RTRVL_RESN": "이전 전체 동기화에서 사라진 이력"},
            active=False,
            last_seen_run_id=recall_run_id,
            last_seen_at=catalog_seen_at,
        )
        failed_recall_source_record = SourceRecord(
            source_code="mfds_recall",
            record_key="recall-failed",
            content_hash="failed-recall-hash",
            public_data={"RTRVL_RESN": "완료되지 않은 동기화의 이력"},
            active=True,
            last_seen_run_id=failed_status_run_id,
            last_seen_at=catalog_seen_at,
        )
        price_source_record = SourceRecord(
            source_code="hira_price",
            record_key="price-1",
            content_hash="price-hash",
            public_data={"applyDt": "20260701", "UPDATE_DATE": "20260702"},
            active=True,
            last_seen_run_id=price_run_id,
            last_seen_at=catalog_seen_at,
        )
        code_source_record = SourceRecord(
            source_code="hira_standard_code",
            record_key="8801234567890",
            content_hash="code-hash",
            public_data={
                "표준코드": "8801234567890",
                "제품코드(개정후)": "645700010",
                "UPDATE_DATE": "20260703",
            },
            active=True,
            last_seen_run_id=code_run_id,
            last_seen_at=catalog_seen_at,
        )
        db.add_all(
            [
                product_source_record,
                pill_source_record,
                pregnancy_source_record,
                concomitant_source_record,
                failed_source_record,
                recall_source_record,
                inactive_recall_source_record,
                failed_recall_source_record,
                price_source_record,
                code_source_record,
                SyncRun(
                    id=pregnancy_run_id,
                    source_code="mfds_dur_product_pregnancy",
                    status="succeeded",
                ),
                SyncRun(
                    id=concomitant_run_id,
                    source_code="mfds_dur_product_concomitant",
                    status="succeeded",
                ),
                SyncRun(
                    id=failed_run_id,
                    source_code="mfds_dur_product_elderly",
                    status="failed",
                ),
                SyncRun(
                    id=recall_run_id,
                    source_code="mfds_recall",
                    status="succeeded",
                    started_at=datetime(2026, 7, 26, 3, 0, tzinfo=UTC),
                ),
                SyncRun(
                    id=failed_status_run_id,
                    source_code="mfds_recall",
                    status="failed",
                    started_at=datetime(2026, 7, 25, 3, 0, tzinfo=UTC),
                ),
                SyncRun(
                    id=price_run_id,
                    source_code="hira_price",
                    status="succeeded",
                ),
                SyncRun(
                    id=code_run_id,
                    source_code="hira_standard_code",
                    status="succeeded",
                ),
            ]
        )
        db.add(
            DrugIdentification(
                item_seq="200000001",
                source_record=pill_source_record,
                shape="장방형",
                color="하양",
                imprint_front="TEST 500",
                imprint_back=None,
                image_url="https://example.test/official-pill.jpg",
            )
        )
        db.add(
            DrugIdentificationVariant(
                item_seq="200000001",
                source_record=pill_source_record,
                source_code="mfds_pill",
                variant_key="200000001|primary",
                shape="장방형",
                color="하양",
                imprint_front="TEST 500",
                imprint_back=None,
                image_url="https://example.test/official-pill.jpg",
            )
        )
        db.add_all(
            [
                SourceRegistry(
                    code="mfds_product",
                    name="MFDS pharmaceutical product authorization",
                    portal_url="https://www.data.go.kr/data/15095677/openapi.do",
                    license_name="Public data",
                    enabled=True,
                ),
                SourceRegistry(
                    code="mfds_recall",
                    name="MFDS recall and sale suspension",
                    portal_url="https://www.data.go.kr/data/15059114/openapi.do",
                    license_name="Public data",
                    attribution="Source: Ministry of Food and Drug Safety",
                    enabled=True,
                ),
                SourceRegistry(
                    code="hira_price",
                    name="HIRA drug reimbursement price",
                    portal_url="https://www.data.go.kr/data/15054445/openapi.do",
                    license_name="Korea Open Government License Type 1",
                    attribution=("Source: Health Insurance Review & Assessment Service"),
                    enabled=True,
                ),
                SourceRegistry(
                    code="hira_standard_code",
                    name="HIRA medicine standard code",
                    portal_url="https://www.data.go.kr/data/15067462/fileData.do",
                    license_name="Korea Open Government License Type 1",
                    attribution=("Source: Health Insurance Review & Assessment Service"),
                    enabled=True,
                ),
            ]
        )
        db.add_all(
            [
                DurRule(
                    item_seq="200000001",
                    rule_type="pregnancy_contraindication",
                    source_record=pregnancy_source_record,
                ),
                DurRule(
                    item_seq="200000001",
                    counterpart_item_seq="200000002",
                    rule_type="concomitant_contraindication",
                    source_record=concomitant_source_record,
                ),
                DurRule(
                    item_seq="200000001",
                    rule_type="elderly_caution",
                    source_record=failed_source_record,
                ),
                DrugStatusEvent(
                    item_seq="200000001",
                    source_code="mfds_recall",
                    event_key="recall-1",
                    event_type="recall",
                    started_on=date(2026, 7, 25),
                    source_record=recall_source_record,
                ),
                DrugStatusEvent(
                    item_seq="200000001",
                    source_code="mfds_recall",
                    event_key="recall-inactive",
                    event_type="recall",
                    started_on=date(2025, 1, 1),
                    source_record=inactive_recall_source_record,
                ),
                DrugStatusEvent(
                    item_seq="200000001",
                    source_code="mfds_recall",
                    event_key="recall-failed",
                    event_type="recall",
                    started_on=date(2026, 7, 27),
                    source_record=failed_recall_source_record,
                ),
                DrugPrice(
                    item_seq=None,
                    insurance_code="645700010",
                    amount=Decimal("1234.00"),
                    effective_date=date(2026, 7, 1),
                    source_record=price_source_record,
                ),
                DrugCode(
                    item_seq="200000001",
                    code_type="standard",
                    code="8801234567890",
                    valid_from=date(2026, 1, 1),
                    source_record=code_source_record,
                ),
            ]
        )
        db.commit()

    assert client.get("/api/v1/catalog/meta").status_code == 401
    assert client.get("/api/v1/drugs/search", params={"q": "효소"}).status_code == 401

    session = create_account(client)
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    assert (
        client.get("/api/v1/drugs/search", params={"q": "효소"}, headers=headers).status_code == 403
    )
    with SessionLocal() as db:
        user = db.get(User, uuid.UUID(session["account"]["id"]))
        assert user is not None
        user.catalog_read_enabled = True
        db.commit()

    profile = client.get("/api/v1/me", headers=headers)
    assert profile.status_code == 200
    assert profile.json()["permissions"] == ["catalog:read"]

    meta = client.get("/api/v1/catalog/meta", headers=headers)
    assert meta.status_code == 200
    assert meta.json()["productCount"] == 1
    assert meta.json()["failedSources"] == []
    product_source = next(
        source for source in meta.json()["sources"] if source["code"] == "mfds_product"
    )
    assert product_source["lastAttemptStatus"] is None

    search = client.get("/api/v1/drugs/search", params={"q": "효소"}, headers=headers)
    assert search.status_code == 200
    assert search.json()["items"][0]["itemName"] == "테스트 효소제"

    detail = client.get("/api/v1/drugs/200000001", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["ingredients"] == ["테스트성분"]
    assert detail.json()["appearance"] == "흰색 장방형 필름코팅정"
    assert detail.json()["imageUrl"] == "https://example.test/official-pill.jpg"
    assert detail.json()["identification"] == {
        "variantKey": None,
        "shape": "장방형",
        "color": "하양",
        "imprintFront": "TEST 500",
        "imprintBack": None,
        "imageUrl": "https://example.test/official-pill.jpg",
    }
    assert detail.json()["identificationVariants"] == [
        {
            "variantKey": "200000001|primary",
            "shape": "장방형",
            "color": "하양",
            "imprintFront": "TEST 500",
            "imprintBack": None,
            "imageUrl": "https://example.test/official-pill.jpg",
        }
    ]
    assert detail.json()["safetyOverview"] == {
        "totalCount": 2,
        "categories": [
            {"ruleType": "concomitant_contraindication", "count": 1},
            {"ruleType": "pregnancy_contraindication", "count": 1},
        ],
    }
    assert detail.json()["statusEvents"] == [
        {
            "eventType": "recall",
            "reason": "품질 기준 확인을 위한 공식 회수",
            "startedOn": "2026-07-25",
            "endedOn": None,
            "sourceCode": "mfds_recall",
            "sourceUpdatedAt": "20260726",
            "catalogUpdatedAt": "2026-07-26T03:10:00",
            "source": {
                "source": "MFDS recall and sale suspension",
                "sourceUrl": "https://www.data.go.kr/data/15059114/openapi.do",
                "licenseName": "Public data",
                "attribution": "Source: Ministry of Food and Drug Safety",
            },
        }
    ]
    assert detail.json()["prices"] == [
        {
            "insuranceCode": "645700010",
            "amount": "1234.00",
            "effectiveDate": "2026-07-01",
            "sourceCode": "hira_price",
            "sourceUpdatedAt": "20260702",
            "catalogUpdatedAt": "2026-07-26T03:10:00",
            "source": {
                "source": "HIRA drug reimbursement price",
                "sourceUrl": "https://www.data.go.kr/data/15054445/openapi.do",
                "licenseName": "Korea Open Government License Type 1",
                "attribution": ("Source: Health Insurance Review & Assessment Service"),
            },
        }
    ]
    assert detail.json()["codes"] == [
        {
            "codeType": "standard",
            "code": "8801234567890",
            "validFrom": "2026-01-01",
            "validTo": None,
            "sourceCode": "hira_standard_code",
            "sourceUpdatedAt": "20260703",
            "catalogUpdatedAt": "2026-07-26T03:10:00",
            "source": {
                "source": "HIRA medicine standard code",
                "sourceUrl": "https://www.data.go.kr/data/15067462/fileData.do",
                "licenseName": "Korea Open Government License Type 1",
                "attribution": ("Source: Health Insurance Review & Assessment Service"),
            },
        }
    ]
    assert len(detail.json()["sources"]) == 4
    assert all(
        source["sourceUrl"].startswith("https://www.data.go.kr/")
        for source in detail.json()["sources"]
    )

    first_rules = client.get(
        "/api/v1/drugs/200000001/dur-rules",
        params={"limit": 1},
        headers=headers,
    )
    assert first_rules.status_code == 200
    assert len(first_rules.json()["items"]) == 1
    assert first_rules.json()["nextCursor"] is not None

    second_rules = client.get(
        "/api/v1/drugs/200000001/dur-rules",
        params={"limit": 1, "cursor": first_rules.json()["nextCursor"]},
        headers=headers,
    )
    assert second_rules.status_code == 200
    assert len(second_rules.json()["items"]) == 1
    assert second_rules.json()["nextCursor"] is None

    concomitant = client.get(
        "/api/v1/drugs/200000001/dur-rules",
        params={"ruleType": "concomitant_contraindication"},
        headers=headers,
    )
    assert concomitant.status_code == 200
    assert concomitant.json()["items"][0]["counterpartItemName"] == "상대 의약품"
    assert concomitant.json()["items"][0]["counterpartIngredientName"] == "상대성분"

    with SessionLocal() as db:
        db.add(
            DrugProduct(
                item_seq="200000002",
                item_name="상대 의약품",
                manufacturer="상대제약",
                status="정상",
            )
        )
        db.add(
            SourceRecord(
                source_code="mfds_product",
                record_key="200000002",
                content_hash="counterpart-product-hash",
                public_data={"ITEM_SEQ": "200000002"},
                active=True,
                last_seen_run_id=uuid.uuid4(),
            )
        )
        db.commit()

    reverse_concomitant = client.get(
        "/api/v1/drugs/200000002/dur-rules",
        params={"ruleType": "concomitant_contraindication"},
        headers=headers,
    )
    assert reverse_concomitant.status_code == 200
    assert reverse_concomitant.json()["items"] == [
        {
            "ruleType": "concomitant_contraindication",
            "typeName": "병용금기",
            "ingredientName": "상대성분",
            "counterpartItemSeq": "200000001",
            "counterpartItemName": "테스트 효소제",
            "counterpartIngredientName": "테스트성분",
            "prohibitionContent": "함께 사용하지 않음",
            "remark": None,
            "notificationDate": None,
            "sourceCode": "mfds_dur_product_concomitant",
        }
    ]
    reverse_detail = client.get(
        "/api/v1/drugs/200000002",
        headers=headers,
    )
    assert reverse_detail.status_code == 200
    assert reverse_detail.json()["safetyOverview"] == {
        "totalCount": 1,
        "categories": [
            {"ruleType": "concomitant_contraindication", "count": 1},
        ],
    }

    with SessionLocal() as db:
        product_record = db.scalar(
            select(SourceRecord).where(
                SourceRecord.source_code == "mfds_product",
                SourceRecord.record_key == "200000001",
            )
        )
        assert product_record is not None
        product_record.active = False
        db.commit()
    hidden_search = client.get(
        "/api/v1/drugs/search",
        params={"q": "효소"},
        headers=headers,
    )
    assert hidden_search.status_code == 200
    assert hidden_search.json()["items"] == []
    assert (
        client.get(
            "/api/v1/drugs/200000001",
            headers=headers,
        ).status_code
        == 404
    )

    with SessionLocal() as db:
        user = db.get(User, uuid.UUID(session["account"]["id"]))
        assert user is not None
        user.catalog_read_enabled = False
        db.commit()
    assert (
        client.get("/api/v1/drugs/search", params={"q": "효소"}, headers=headers).status_code == 403
    )


def test_catalog_detail_projections_are_bounded_and_deterministic(
    client: TestClient,
) -> None:
    status_run_id = uuid.uuid4()
    shortage_run_id = uuid.uuid4()
    price_run_id = uuid.uuid4()
    code_run_id = uuid.uuid4()
    with SessionLocal() as db:
        db.add(
            DrugProduct(
                item_seq="bounded-product",
                item_name="Projection Bound Test",
            )
        )
        db.add(
            DrugProduct(
                item_seq="empty-projection-product",
                item_name="Empty Projection Test",
            )
        )
        db.add(
            SourceRecord(
                source_code="mfds_product",
                record_key="bounded-product",
                content_hash="bounded-product-hash",
                public_data={},
                active=True,
                last_seen_run_id=uuid.uuid4(),
            )
        )
        db.add(
            SourceRecord(
                source_code="mfds_product",
                record_key="empty-projection-product",
                content_hash="empty-projection-product-hash",
                public_data={},
                active=True,
                last_seen_run_id=uuid.uuid4(),
            )
        )
        db.add_all(
            [
                SourceRegistry(
                    code="mfds_product",
                    name="MFDS products",
                    portal_url="https://example.test/products",
                    enabled=True,
                ),
                SourceRegistry(
                    code="mfds_recall",
                    name="MFDS recalls",
                    portal_url="https://example.test/recalls",
                    enabled=True,
                ),
                SourceRegistry(
                    code="mfds_shortage",
                    name="MFDS supply shortage",
                    portal_url="https://example.test/shortages",
                    enabled=True,
                ),
                SourceRegistry(
                    code="hira_price",
                    name="HIRA prices",
                    portal_url="https://example.test/prices",
                    enabled=True,
                ),
                SourceRegistry(
                    code="hira_standard_code",
                    name="HIRA codes",
                    portal_url="https://example.test/codes",
                    enabled=True,
                ),
                SourceRegistry(
                    code="mfds_pill",
                    name="MFDS pill identification",
                    portal_url="https://example.test/pills",
                    enabled=True,
                ),
                SyncRun(
                    id=status_run_id,
                    source_code="mfds_recall",
                    status="succeeded",
                ),
                SyncRun(
                    id=shortage_run_id,
                    source_code="mfds_shortage",
                    status="succeeded",
                ),
                SyncRun(
                    id=price_run_id,
                    source_code="hira_price",
                    status="succeeded",
                ),
                SyncRun(
                    id=code_run_id,
                    source_code="hira_standard_code",
                    status="succeeded",
                ),
            ]
        )
        for index in range(23):
            event_source_code = "mfds_shortage" if index == 21 else "mfds_recall"
            event_record = SourceRecord(
                source_code=event_source_code,
                record_key=f"event-{index:02d}",
                content_hash=f"event-hash-{index:02d}",
                public_data=(
                    {"SUSPEND_REASON": "공식 생산·수입·공급 중단 사유"} if index == 21 else {}
                ),
                active=True,
                last_seen_run_id=(shortage_run_id if index == 21 else status_run_id),
            )
            db.add(event_record)
            db.add(
                DrugStatusEvent(
                    item_seq="bounded-product",
                    source_code=event_source_code,
                    event_key=f"event-{index:02d}",
                    event_type=(
                        "suspension" if index == 22 else "shortage" if index == 21 else "recall"
                    ),
                    started_on=date(2026, 1, 1) + timedelta(days=index),
                    source_record=event_record,
                )
            )
        for index in range(7):
            price_record = SourceRecord(
                source_code="hira_price",
                record_key=f"price-{index:02d}",
                content_hash=f"price-hash-{index:02d}",
                public_data={},
                active=True,
                last_seen_run_id=price_run_id,
            )
            db.add(price_record)
            db.add(
                DrugPrice(
                    item_seq="bounded-product",
                    insurance_code=f"price-{index:02d}",
                    amount=Decimal(index),
                    effective_date=date(2026, 2, 1) + timedelta(days=index),
                    source_record=price_record,
                )
            )
        for index in range(22):
            code_record = SourceRecord(
                source_code="hira_standard_code",
                record_key=f"code-{index:02d}",
                content_hash=f"code-hash-{index:02d}",
                public_data={},
                active=True,
                last_seen_run_id=code_run_id,
            )
            db.add(code_record)
            db.add(
                DrugCode(
                    item_seq="bounded-product",
                    code_type="standard",
                    code=f"code-{index:02d}",
                    valid_from=date(2026, 3, 1) + timedelta(days=index),
                    source_record=code_record,
                )
            )
        for index in reversed(range(22)):
            variant_record = SourceRecord(
                source_code="mfds_pill",
                record_key=f"variant-{index:02d}",
                content_hash=f"variant-hash-{index:02d}",
                public_data={},
                active=True,
                last_seen_run_id=uuid.uuid4(),
            )
            db.add(variant_record)
            db.add(
                DrugIdentificationVariant(
                    item_seq="bounded-product",
                    source_code="mfds_pill",
                    variant_key=f"variant-{index:02d}",
                    shape="round",
                    source_record=variant_record,
                )
            )
        db.commit()

    session = create_account(client)
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    with SessionLocal() as db:
        user = db.get(User, uuid.UUID(session["account"]["id"]))
        assert user is not None
        user.catalog_read_enabled = True
        db.commit()

    response = client.get("/api/v1/drugs/bounded-product", headers=headers)
    assert response.status_code == 200
    detail = response.json()
    assert len(detail["statusEvents"]) == 20
    assert detail["statusEvents"][0]["startedOn"] == "2026-01-23"
    assert detail["statusEvents"][0]["eventType"] == "suspension"
    assert detail["statusEvents"][1]["eventType"] == "shortage"
    assert detail["statusEvents"][1]["reason"] == "공식 생산·수입·공급 중단 사유"
    assert detail["statusEvents"][-1]["startedOn"] == "2026-01-04"
    assert len(detail["prices"]) == 5
    assert detail["prices"][0]["insuranceCode"] == "price-06"
    assert detail["prices"][-1]["insuranceCode"] == "price-02"
    assert len(detail["codes"]) == 20
    assert detail["codes"][0]["code"] == "code-21"
    assert detail["codes"][-1]["code"] == "code-02"
    assert len(detail["identificationVariants"]) == 20
    assert detail["identificationVariants"][0]["variantKey"] == "variant-00"
    assert detail["identificationVariants"][-1]["variantKey"] == "variant-19"

    empty_response = client.get(
        "/api/v1/drugs/empty-projection-product",
        headers=headers,
    )
    assert empty_response.status_code == 200
    assert empty_response.json()["statusEvents"] == []
    assert empty_response.json()["prices"] == []
    assert empty_response.json()["codes"] == []


def test_server_schema_excludes_household_inventory(client: TestClient) -> None:
    table_names = set(inspect(engine).get_table_names())
    forbidden = {
        "households",
        "member_profiles",
        "inventory_containers",
        "inventory_items",
        "renewal_readiness",
        "reminders",
        "app_settings",
    }
    assert table_names.isdisjoint(forbidden)


def test_well_known_files(client: TestClient) -> None:
    apple = client.get("/.well-known/apple-app-site-association")
    android = client.get("/.well-known/assetlinks.json")
    assert apple.status_code == 200
    apple_detail = apple.json()["applinks"]["details"][0]
    assert apple_detail["appID"].endswith("com.medicalbox.app")
    assert apple_detail["paths"] == [
        "/app",
        "/app/inventory",
        "/app/reminders",
        "/app/settings",
        "/app/login",
    ]
    assert android.status_code == 200
    assert android.json()[0]["target"]["package_name"] == "com.medicalbox.app"

    for path in apple_detail["paths"]:
        fallback = client.get(path)
        assert fallback.status_code == 200
        assert "앱에서 열기" in fallback.text
