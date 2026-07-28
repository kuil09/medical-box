import uuid

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from sqlalchemy import inspect, select

from medical_box_api.config import Settings, get_settings
from medical_box_api.db import SessionLocal, engine
from medical_box_api.models import (
    DrugConsumerInfo,
    DrugIdentification,
    DrugIdentificationVariant,
    DrugIngredient,
    DrugProduct,
    DurRule,
    SourceRecord,
    SourceRegistry,
    SyncRun,
    User,
)


def create_account(client: TestClient) -> dict[str, object]:
    response = client.post(
        "/api/v1/auth/exchange/google",
        json={
            "providerToken": "valid-google-token",
            "termsVersion": "2026-07-25",
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


def test_production_catalog_worker_does_not_require_api_jwt_secret() -> None:
    worker_settings = Settings(
        _env_file=None,
        app_env="production",
        app_role="catalog_sync",
    )
    assert worker_settings.app_role == "catalog_sync"

    with pytest.raises(ValidationError, match="JWT_SECRET"):
        Settings(
            _env_file=None,
            app_env="production",
            app_role="api",
            jwt_secret="short",
        )


def test_web_health_and_security_headers(client: TestClient) -> None:
    for path in ["/", "/privacy", "/terms", "/support", "/account-deletion"]:
        response = client.get(path)
        assert response.status_code == 200
        assert "우리집 구급키트" in response.text
    live = client.get("/api/health/live")
    ready = client.get("/api/health/ready")
    assert live.json() == {"status": "ok"}
    assert ready.json() == {"status": "ready"}
    assert live.headers["x-content-type-options"] == "nosniff"
    assert "max-age=31536000" in live.headers["strict-transport-security"]


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
            payload={"ITEM_SEQ": "200000001"},
            active=True,
            last_seen_run_id=uuid.uuid4(),
        )
        pill_source_record = SourceRecord(
            source_code="mfds_pill",
            record_key="200000001|primary",
            content_hash="pill-hash",
            payload={},
            last_seen_run_id=uuid.uuid4(),
        )
        pregnancy_run_id = uuid.uuid4()
        concomitant_run_id = uuid.uuid4()
        failed_run_id = uuid.uuid4()
        pregnancy_source_record = SourceRecord(
            source_code="mfds_dur_product_pregnancy",
            record_key="pregnancy-1",
            content_hash="pregnancy-hash",
            payload={
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
            payload={
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
            payload={"TYPE_NAME": "노인주의"},
            last_seen_run_id=failed_run_id,
        )
        db.add_all(
            [
                product_source_record,
                pill_source_record,
                pregnancy_source_record,
                concomitant_source_record,
                failed_source_record,
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
        db.add(
            SourceRegistry(
                code="mfds_product",
                name="MFDS pharmaceutical product authorization",
                portal_url="https://www.data.go.kr/data/15095677/openapi.do",
                license_name="Public data",
                enabled=True,
            )
        )
        db.add_all(
            [
                DurRule(
                    item_seq="200000001",
                    source_code="mfds_dur_product_pregnancy",
                    rule_key="pregnancy-1",
                    rule_type="pregnancy_contraindication",
                    source_record=pregnancy_source_record,
                ),
                DurRule(
                    item_seq="200000001",
                    source_code="mfds_dur_product_concomitant",
                    rule_key="concomitant-1",
                    rule_type="concomitant_contraindication",
                    source_record=concomitant_source_record,
                ),
                DurRule(
                    item_seq="200000001",
                    source_code="mfds_dur_product_elderly",
                    rule_key="failed-1",
                    rule_type="elderly_caution",
                    source_record=failed_source_record,
                ),
            ]
        )
        db.commit()

    assert client.get("/api/v1/catalog/meta").status_code == 401
    assert client.get("/api/v1/drugs/search", params={"q": "효소"}).status_code == 401

    session = create_account(client)
    headers = {"Authorization": f"Bearer {session['accessToken']}"}
    assert (
        client.get("/api/v1/drugs/search", params={"q": "효소"}, headers=headers).status_code
        == 403
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
    assert meta.json()["sources"][0]["lastAttemptStatus"] is None

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
    assert len(detail.json()["sources"]) == 1
    assert detail.json()["sources"][0]["sourceUrl"].startswith("https://www.data.go.kr/")

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
    assert (
        concomitant.json()["items"][0]["counterpartIngredientName"]
        == "상대성분"
    )

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
    assert client.get(
        "/api/v1/drugs/200000001",
        headers=headers,
    ).status_code == 404

    with SessionLocal() as db:
        user = db.get(User, uuid.UUID(session["account"]["id"]))
        assert user is not None
        user.catalog_read_enabled = False
        db.commit()
    assert (
        client.get("/api/v1/drugs/search", params={"q": "효소"}, headers=headers).status_code
        == 403
    )

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
    assert apple.json()["applinks"]["details"][0]["appID"].endswith("com.medicalbox.app")
    assert android.status_code == 200
    assert android.json()[0]["target"]["package_name"] == "com.medicalbox.app"
