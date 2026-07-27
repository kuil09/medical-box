from pathlib import Path
from typing import Literal

from pydantic import SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class BackupSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: Literal["development", "test", "production"] = "development"
    database_url: SecretStr

    backup_store: Literal["s3", "local"] = "s3"
    backup_local_directory: Path | None = None
    backup_prefix: str = "medical-box/production"

    aws_endpoint_url: str | None = None
    aws_access_key_id: SecretStr | None = None
    aws_secret_access_key: SecretStr | None = None
    aws_s3_bucket_name: str | None = None
    aws_default_region: str = "sin"
    aws_s3_addressing_style: Literal["auto", "path", "virtual"] = "path"

    backup_gpg_public_key_base64: SecretStr | None = None
    backup_gpg_recipient: str | None = None
    backup_gpg_private_key_base64: SecretStr | None = None
    backup_gpg_passphrase: SecretStr | None = None
    backup_manifest_hmac_key_base64: SecretStr

    backup_restore_database_url: SecretStr | None = None
    backup_restore_confirmation: str | None = None

    backup_daily_retention: int = 7
    backup_weekly_retention: int = 4
    backup_monthly_retention: int = 12
    backup_pg_dump_path: str = "pg_dump"
    backup_pg_restore_path: str = "pg_restore"
    backup_gpg_path: str = "gpg"
    backup_restore_jobs: int = 4

    @field_validator("backup_prefix")
    @classmethod
    def normalize_prefix(cls, value: str) -> str:
        normalized = value.strip("/")
        if not normalized or ".." in normalized.split("/"):
            raise ValueError("BACKUP_PREFIX must be a safe, non-empty object prefix.")
        return normalized

    @field_validator(
        "backup_daily_retention",
        "backup_weekly_retention",
        "backup_monthly_retention",
        "backup_restore_jobs",
    )
    @classmethod
    def require_positive_integer(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("Backup retention and restore job values must be positive.")
        return value

    @field_validator("backup_gpg_recipient")
    @classmethod
    def normalize_fingerprint(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = "".join(value.split()).upper()
        has_invalid_character = any(
            character not in "0123456789ABCDEF" for character in normalized
        )
        if len(normalized) < 40 or has_invalid_character:
            raise ValueError("BACKUP_GPG_RECIPIENT must be a full hexadecimal fingerprint.")
        return normalized

    @model_validator(mode="after")
    def validate_store_configuration(self) -> "BackupSettings":
        if self.app_env == "production" and self.backup_store != "s3":
            raise ValueError("Production backups must use the S3-compatible durable store.")
        if self.backup_store == "local":
            if self.backup_local_directory is None:
                raise ValueError("BACKUP_LOCAL_DIRECTORY is required for the local store.")
        else:
            required = {
                "AWS_ENDPOINT_URL": self.aws_endpoint_url,
                "AWS_ACCESS_KEY_ID": self.aws_access_key_id,
                "AWS_SECRET_ACCESS_KEY": self.aws_secret_access_key,
                "AWS_S3_BUCKET_NAME": self.aws_s3_bucket_name,
            }
            missing = [name for name, value in required.items() if value is None]
            if missing:
                raise ValueError(f"Missing S3 backup settings: {', '.join(missing)}")
        return self
