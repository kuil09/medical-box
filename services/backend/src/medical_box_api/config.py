from datetime import date
from functools import lru_cache
from typing import Literal

from pydantic import SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

DEVELOPMENT_JWT_SECRET = "development-only-secret-change-before-deploy"
EXAMPLE_JWT_SECRET = "replace-with-at-least-32-random-characters"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: Literal["development", "test", "production"] = "development"
    app_role: Literal["api", "catalog_sync", "backup", "backup_verify"] = "api"
    database_url: str = "sqlite+pysqlite:///./medical_box.db"
    public_origin: str = "https://medicalbox.outoftokens.ai"
    support_email: str | None = None
    terms_version: str = "2026-07-29"
    allowed_hosts: str = "localhost,127.0.0.1,testserver"
    jwt_secret: str = DEVELOPMENT_JWT_SECRET
    jwt_issuer: str = "medicalbox.outoftokens.ai"
    jwt_audience: str = "com.medicalbox.app"
    catalog_access_email_allowlist: str = ""
    catalog_sync_source_allowlist: str = ""
    catalog_database_capacity_bytes: int = 0
    catalog_min_free_bytes: int = 1_200_000_000

    google_client_id: str | None = None
    apple_client_id: str = "com.medicalbox.app"
    apple_sign_in_enabled: bool = False
    kakao_app_id: str | None = None

    data_go_kr_service_key: str | None = None
    data_go_kr_service_key_encoded: str | None = None
    mfds_product_url: str = (
        "https://apis.data.go.kr/1471000/DrugPrdtPrmsnInfoService07/getDrugPrdtPrmsnInq07"
    )
    mfds_product_detail_url: str = (
        "https://apis.data.go.kr/1471000/"
        "DrugPrdtPrmsnInfoService07/getDrugPrdtPrmsnDtlInq06"
    )
    mfds_product_ingredient_url: str = (
        "https://apis.data.go.kr/1471000/"
        "DrugPrdtPrmsnInfoService07/getDrugPrdtMcpnDtlInq07"
    )
    mfds_easy_url: str = "https://apis.data.go.kr/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList"
    mfds_pill_url: str = (
        "http://apis.data.go.kr/1471000/MdcinGrnIdntfcInfoService03/getMdcinGrnIdntfcInfoList03"
    )
    mfds_dur_product_base_url: str = (
        "https://apis.data.go.kr/1471000/DURPrdlstInfoService03"
    )
    mfds_dur_ingredient_base_url: str = (
        "https://apis.data.go.kr/1471000/DURIrdntInfoService03"
    )
    mfds_recall_url: str | None = (
        "https://apis.data.go.kr/1471000/"
        "MdcinRtrvlSleStpgeInfoService04/getMdcinRtrvlSleStpgelList03"
    )
    mfds_shortage_url: str | None = (
        "https://apis.data.go.kr/1471000/"
        "MdcinPrdctnIncmeSuplyService2/getMdcinPrdctnIncmeSuplyList"
    )
    hira_price_url: str | None = (
        "https://apis.data.go.kr/B551182/"
        "dgamtCrtrInfoService1.2/getDgamtList"
    )
    hira_standard_code_url: str | None = (
        "https://www.data.go.kr/cmm/cmm/fileDownload.do"
        "?atchFileId=FILE_000000003550228"
        "&fileDetailSn=1&insertDataPrcus=N"
    )

    apple_team_id: str | None = None
    apple_sign_in_key_id: str | None = None
    apple_sign_in_private_key_base64: SecretStr | None = None
    android_cert_sha256: str | None = None

    @field_validator("public_origin")
    @classmethod
    def remove_trailing_slash(cls, value: str) -> str:
        return value.rstrip("/")

    @field_validator("support_email")
    @classmethod
    def validate_support_email(cls, value: str | None) -> str | None:
        if value is None or not value.strip():
            return None
        value = value.strip()
        if (
            value.count("@") != 1
            or any(character in value for character in "\r\n\t <>")
        ):
            raise ValueError("SUPPORT_EMAIL must be a single plain email address.")
        return value

    @field_validator("terms_version")
    @classmethod
    def validate_terms_version(cls, value: str) -> str:
        try:
            parsed = date.fromisoformat(value)
        except ValueError as exc:
            raise ValueError("TERMS_VERSION must use YYYY-MM-DD format.") from exc
        if parsed.isoformat() != value:
            raise ValueError("TERMS_VERSION must use YYYY-MM-DD format.")
        return value

    @field_validator("database_url")
    @classmethod
    def select_psycopg_v3_driver(cls, value: str) -> str:
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+psycopg://", 1)
        if value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+psycopg://", 1)
        return value

    @model_validator(mode="after")
    def validate_deploy_secrets(self) -> "Settings":
        if self.app_env != "production":
            return self
        if self.app_role in {"api", "catalog_sync"} and not self.database_url.startswith(
            "postgresql+psycopg://"
        ):
            raise ValueError(
                "DATABASE_URL must use PostgreSQL for production API and catalog sync roles."
            )
        if self.app_role != "api":
            return self
        if len(self.jwt_secret) < 32 or self.jwt_secret in {
            DEVELOPMENT_JWT_SECRET,
            EXAMPLE_JWT_SECRET,
        }:
            raise ValueError(
                "JWT_SECRET must be a non-placeholder secret containing at least "
                "32 characters for the production API."
            )
        return self

    @property
    def allowed_host_list(self) -> list[str]:
        return [host.strip() for host in self.allowed_hosts.split(",") if host.strip()]

    @property
    def catalog_access_email_allowlist_set(self) -> frozenset[str]:
        return frozenset(
            email.strip().casefold()
            for email in self.catalog_access_email_allowlist.split(",")
            if email.strip()
        )

    @property
    def catalog_sync_source_allowlist_set(self) -> frozenset[str]:
        return frozenset(
            source.strip()
            for source in self.catalog_sync_source_allowlist.split(",")
            if source.strip()
        )

    @property
    def apple_account_revocation_configured(self) -> bool:
        private_key = self.apple_sign_in_private_key_base64
        return bool(
            self.apple_client_id.strip()
            and self.apple_team_id
            and self.apple_team_id.strip()
            and self.apple_sign_in_key_id
            and self.apple_sign_in_key_id.strip()
            and private_key is not None
            and private_key.get_secret_value().strip()
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
