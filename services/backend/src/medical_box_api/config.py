from functools import lru_cache
from typing import Literal

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: Literal["development", "test", "production"] = "development"
    database_url: str = "sqlite+pysqlite:///./medical_box.db"
    public_origin: str = "https://medicalbox.outoftokens.ai"
    allowed_hosts: str = "localhost,127.0.0.1,testserver"
    jwt_secret: str = "development-only-secret-change-before-deploy"
    jwt_issuer: str = "medicalbox.outoftokens.ai"
    jwt_audience: str = "com.medicalbox.app"
    catalog_access_email_allowlist: str = ""

    google_client_id: str | None = None
    apple_client_id: str = "com.medicalbox.app"
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
    mfds_recall_url: str | None = None
    mfds_shortage_url: str | None = (
        "https://apis.data.go.kr/1471000/"
        "MdcinPrdctnIncmeSuplyService2/getMdcinPrdctnIncmeSuplyList"
    )
    hira_price_url: str | None = (
        "https://apis.data.go.kr/B551182/"
        "dgamtCrtrInfoService1.2/getDgamtList"
    )
    hira_standard_code_url: str | None = None

    apple_team_id: str | None = None
    android_cert_sha256: str | None = None

    @field_validator("public_origin")
    @classmethod
    def remove_trailing_slash(cls, value: str) -> str:
        return value.rstrip("/")

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
        if self.app_env == "production" and len(self.jwt_secret) < 32:
            raise ValueError(
                "JWT_SECRET must contain at least 32 characters outside local development."
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


@lru_cache
def get_settings() -> Settings:
    return Settings()
